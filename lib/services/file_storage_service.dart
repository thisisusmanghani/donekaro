import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as p;

/// Top-level function for background isolate — compresses + encodes file bytes.
/// Must be top-level (not a closure) to work with compute().
Map<String, dynamic> _compressAndEncode(Uint8List fileBytes) {
  final compressed = gzip.encode(fileBytes);
  final base64Data = base64Encode(compressed);
  return {
    'compressed': compressed,
    'base64Data': base64Data,
    'compressedSize': compressed.length,
  };
}

/// Stores file attachments directly in Firestore as compressed base64.
/// No external storage service needed — fully free.
///
/// Supports chunked storage for large files:
/// - Small files (≤700 KB raw): stored in a single Firestore document
/// - Large files (up to 10 MB raw): compressed in background isolate,
///   split into chunks, written in parallel batches
class FileStorageService {
  static final FileStorageService instance = FileStorageService._();
  FileStorageService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Max raw file size we allow (10 MB).
  static const int maxFileSizeBytes = 10 * 1024 * 1024; // 10 MB

  /// Max base64 chars per Firestore document chunk (~900 KB to stay safe).
  static const int _maxChunkSize = 900000;

  /// How many chunks to write in parallel per batch (avoids stream exhaustion).
  static const int _parallelBatchSize = 3;

  /// Compresses and stores a file in Firestore.
  /// Heavy work (compression/encoding) runs in a background isolate.
  /// Chunks are written in parallel batches for speed.
  ///
  /// [onProgress] is called with (completedSteps, totalSteps) so the UI
  /// can show a progress indicator. Steps = 1 (compress) + N chunks + 1 (done).
  Future<Map<String, String>?> uploadFile({
    required Uint8List fileBytes,
    required String fileName,
    void Function(int completed, int total)? onProgress,
  }) async {
    try {
      // Check file size
      if (fileBytes.length > maxFileSizeBytes) {
        debugPrint(
            '[FileStorage] File too large: ${fileBytes.length} bytes (max: ${maxFileSizeBytes ~/ (1024 * 1024)} MB)');
        return null;
      }

      debugPrint(
          '[FileStorage] Compressing $fileName (${fileBytes.length} bytes) in background...');

      // ── Step 1: Compress + encode in background isolate ──
      onProgress?.call(0, 3); // indeterminate at first
      final result = await compute(_compressAndEncode, fileBytes);
      final String base64Data = result['base64Data'] as String;
      final int compressedSize = result['compressedSize'] as int;

      debugPrint(
          '[FileStorage] Compressed: $compressedSize bytes → ${base64Data.length} base64 chars');

      // Get file extension
      final ext = p.extension(fileName).toLowerCase();

      // Decide: single doc or chunked
      if (base64Data.length <= _maxChunkSize) {
        // ── Single document (small file, backward compatible) ──
        onProgress?.call(1, 2);
        final docRef = await _firestore.collection('attachments').add({
          'fileName': fileName,
          'fileExtension': ext,
          'originalSize': fileBytes.length,
          'compressedSize': compressedSize,
          'data': base64Data,
          'chunked': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        debugPrint('[FileStorage] Stored as single document: ${docRef.id}');
        onProgress?.call(2, 2);

        return {
          'fileId': docRef.id,
          'fileName': fileName,
          'webViewLink': 'firestore://attachments/${docRef.id}',
        };
      } else {
        // ── Chunked storage (large file) ──
        final totalChunks = (base64Data.length / _maxChunkSize).ceil();
        // total steps: 1 (compress done) + totalChunks + 1 (metadata)
        final totalSteps = totalChunks + 2;
        onProgress?.call(1, totalSteps);

        debugPrint(
            '[FileStorage] Large file — splitting into $totalChunks chunks');

        // 1. Create the parent metadata document
        final parentRef = await _firestore.collection('attachments').add({
          'fileName': fileName,
          'fileExtension': ext,
          'originalSize': fileBytes.length,
          'compressedSize': compressedSize,
          'chunked': true,
          'totalChunks': totalChunks,
          'createdAt': FieldValue.serverTimestamp(),
        });
        onProgress?.call(2, totalSteps);

        debugPrint('[FileStorage] Parent doc: ${parentRef.id}');

        // 2. Prepare all chunk data
        final List<MapEntry<int, String>> chunks = [];
        for (int i = 0; i < totalChunks; i++) {
          final start = i * _maxChunkSize;
          final end = (start + _maxChunkSize > base64Data.length)
              ? base64Data.length
              : start + _maxChunkSize;
          chunks.add(MapEntry(i, base64Data.substring(start, end)));
        }

        // 3. Write chunks in parallel batches to avoid stream exhaustion
        int completedChunks = 0;
        for (int batchStart = 0;
            batchStart < chunks.length;
            batchStart += _parallelBatchSize) {
          final batchEnd = (batchStart + _parallelBatchSize > chunks.length)
              ? chunks.length
              : batchStart + _parallelBatchSize;
          final batch = chunks.sublist(batchStart, batchEnd);

          // Write this batch in parallel
          await Future.wait(batch.map((entry) {
            return _firestore
                .collection('attachments')
                .doc(parentRef.id)
                .collection('chunks')
                .doc('chunk_${entry.key}')
                .set({
              'index': entry.key,
              'data': entry.value,
            });
          }));

          completedChunks += batch.length;
          onProgress?.call(2 + completedChunks, totalSteps);
          debugPrint(
              '[FileStorage] Wrote batch ${batchStart ~/ _parallelBatchSize + 1} ($completedChunks/$totalChunks chunks done)');
        }

        debugPrint('[FileStorage] All chunks written successfully');

        return {
          'fileId': parentRef.id,
          'fileName': fileName,
          'webViewLink': 'firestore://attachments/${parentRef.id}',
        };
      }
    } catch (e, stack) {
      debugPrint('\n=== FILE STORAGE ERROR ===');
      debugPrint('Error: $e');
      debugPrint('Stack: $stack');
      debugPrint('=== END FILE STORAGE ERROR ===\n');
      return null;
    }
  }

  /// Downloads a file from Firestore by document ID.
  /// Handles both single-doc and chunked files, plus legacy docs without
  /// the 'chunked' field.
  /// Returns the original (decompressed) file bytes, or null if not found.
  Future<Uint8List?> downloadFile(String fileId) async {
    try {
      debugPrint('[FileStorage] Downloading file: $fileId');
      final doc = await _firestore.collection('attachments').doc(fileId).get();

      if (!doc.exists) {
        debugPrint('[FileStorage] Document not found: $fileId');
        return null;
      }

      final data = doc.data()!;
      final fileName = data['fileName'] as String? ?? 'unknown';
      final isChunked = data['chunked'] == true;

      String base64Data;

      if (isChunked) {
        // ── Reassemble chunks ──
        final totalChunks = data['totalChunks'] as int;
        debugPrint(
            '[FileStorage] Chunked file ($totalChunks chunks), reassembling...');

        final chunkSnap = await _firestore
            .collection('attachments')
            .doc(fileId)
            .collection('chunks')
            .orderBy('index')
            .get();

        if (chunkSnap.docs.length != totalChunks) {
          debugPrint(
              '[FileStorage] Chunk count mismatch: expected $totalChunks, got ${chunkSnap.docs.length}');
          return null;
        }

        final buffer = StringBuffer();
        for (final chunkDoc in chunkSnap.docs) {
          buffer.write(chunkDoc.data()['data'] as String);
        }
        base64Data = buffer.toString();
      } else {
        // ── Single document (or legacy) ──
        base64Data = data['data'] as String;
      }

      debugPrint('[FileStorage] Found $fileName, decoding...');

      // Decode base64 → compressed bytes → original bytes
      final compressed = base64Decode(base64Data);
      final originalBytes = Uint8List.fromList(gzip.decode(compressed));

      debugPrint('[FileStorage] Decompressed: ${originalBytes.length} bytes');

      return originalBytes;
    } catch (e) {
      debugPrint('[FileStorage] Download error: $e');
      return null;
    }
  }

  /// Gets file metadata (name, size) without downloading the full data.
  Future<Map<String, dynamic>?> getFileInfo(String fileId) async {
    try {
      final doc = await _firestore.collection('attachments').doc(fileId).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      return {
        'fileName': data['fileName'] ?? '',
        'fileExtension': data['fileExtension'] ?? '',
        'originalSize': data['originalSize'] ?? 0,
        'compressedSize': data['compressedSize'] ?? 0,
        'chunked': data['chunked'] == true,
        'totalChunks': data['totalChunks'] ?? 1,
      };
    } catch (e) {
      return null;
    }
  }
}
