import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../constants/app_colors.dart';
import '../models/gig_model.dart';
import '../providers/app_state.dart';
import '../services/database_service.dart';
import '../services/file_storage_service.dart';
import 'chat_screen.dart';

class GigDetailScreen extends StatelessWidget {
  final GigModel gig;
  final String role;

  const GigDetailScreen({super.key, required this.gig, required this.role});

  @override
  Widget build(BuildContext context) {
    final commission = gig.price * 0.15;
    final sellerEarning = gig.price - commission;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back_ios_new,
                    size: 18, color: Colors.white),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.favorite_border,
                    size: 20, color: Colors.white),
              ),
              Container(
                margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.share_outlined,
                    size: 20, color: Colors.white),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Text(
                        categories.firstWhere((c) => c['name'] == gig.category)['icon'] as String,
                        style: const TextStyle(fontSize: 56),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          gig.category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main info card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        gig.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Stats row
                      Row(
                        children: [
                          _buildStatChip(
                            Icons.star,
                            '${gig.rating} (${gig.reviewCount})',
                            AppColors.starYellow,
                          ),
                          const SizedBox(width: 12),
                          _buildStatChip(
                            Icons.access_time,
                            gig.deliveryTimeText,
                            AppColors.info,
                          ),
                          const SizedBox(width: 12),
                          _buildStatChip(
                            Icons.shopping_bag_outlined,
                            '${gig.reviewCount + 5} orders',
                            AppColors.secondary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Description
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        gig.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),

                // Seller info card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'About the Seller',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withOpacity(0.8),
                                  AppColors.primaryLight,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                gig.sellerAvatar,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  gig.sellerName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  gig.sellerDepartment,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on,
                                        size: 14, color: AppColors.textHint),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Quaid-e-Azam University',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textHint,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Chat button
                          GestureDetector(
                            onTap: () async {
                              final appState = context.read<AppState>();
                              final dbService = DatabaseService();

                              // Show loading
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (_) => const Center(child: CircularProgressIndicator()),
                              );

                              final chatId = await dbService.getOrCreateChat(
                                myId: appState.uid,
                                myName: appState.userName,
                                myAvatar: appState.userAvatar,
                                otherId: gig.sellerId,
                                otherName: gig.sellerName,
                                otherAvatar: gig.sellerAvatar,
                              );

                              if (!context.mounted) return;
                              Navigator.pop(context); // dismiss loading

                              if (chatId.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Failed to start chat')),
                                );
                                return;
                              }

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatDetailScreen(
                                    chatId: chatId,
                                    otherUserId: gig.sellerId,
                                    otherUserName: gig.sellerName,
                                    otherUserAvatar: gig.sellerAvatar,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.chat_bubble_outline,
                                  color: AppColors.primary, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Price breakdown card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Price Breakdown',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildPriceRow('Service Price', 'Rs. ${gig.price.toInt()}'),
                      const SizedBox(height: 10),
                      _buildPriceRow('Platform Fee (15%)', 'Rs. ${commission.toInt()}'),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(color: AppColors.divider),
                      ),
                      if (role == 'seller')
                        _buildPriceRow('You Earn', 'Rs. ${sellerEarning.toInt()}',
                            isBold: true, color: AppColors.secondary)
                      else
                        _buildPriceRow(
                            'Total', 'Rs. ${gig.price.toInt()}',
                            isBold: true, color: AppColors.primary),
                    ],
                  ),
                ),

                // Reviews section
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Reviews',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${gig.reviewCount} reviews',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: DatabaseService().getReviewsForGig(gig.id),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          }
                          final reviews = snapshot.data ?? [];
                          if (reviews.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  'No reviews yet',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textHint,
                                  ),
                                ),
                              ),
                            );
                          }
                          return Column(
                            children: reviews.take(3).map((review) {
                              return Column(
                                children: [
                                  _buildReviewItem(
                                    review['reviewerName'] as String,
                                    review['comment'] as String,
                                    (review['rating'] as double),
                                  ),
                                  if (review != reviews.take(3).last)
                                    const Divider(color: AppColors.divider, height: 24),
                                ],
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      // Bottom bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Price
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Price',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'Rs. ${gig.price.toInt()}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              // Order button
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      _showOrderConfirmation(context);
                    },
                    child: Text(
                      role == 'buyer' ? 'Order Now' : 'Edit Gig',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOrderConfirmation(BuildContext context) {
    final descController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        bool isLoading = false;
        String? pickedFileName;
        Uint8List? pickedFileBytes;
        bool isUploading = false;
        String? fileSizeError;
        double uploadProgress = 0.0;
        String uploadStatus = '';

        return StatefulBuilder(
          builder: (context, setModalState) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: isLoading
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 40),
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: isUploading
                              ? Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      value: uploadProgress > 0 ? uploadProgress : null,
                                      strokeWidth: 4,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.primary,
                                      ),
                                      backgroundColor: AppColors.divider,
                                    ),
                                    if (uploadProgress > 0)
                                      Text(
                                        '${(uploadProgress * 100).toInt()}%',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                  ],
                                )
                              : CircularProgressIndicator(
                                  strokeWidth: 4,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primary,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          isUploading
                              ? (uploadStatus.isNotEmpty ? uploadStatus : 'Uploading file...')
                              : 'Placing your order...',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isUploading
                              ? 'Uploading your attachment to cloud ☁️'
                              : 'Please wait while we process your order ✨',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    )
                  : SingleChildScrollView(
                      child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.divider,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_circle,
                              color: AppColors.success, size: 40),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Confirm Order',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You are about to order "${gig.title}"',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Task description
                        TextField(
                          controller: descController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Describe your task requirements...',
                            hintStyle: TextStyle(color: AppColors.textHint),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // ── File Attachment ──
                        GestureDetector(
                          onTap: () async {
                            final result = await FilePicker.platform.pickFiles(
                              withData: true,
                              withReadStream: false,
                              type: FileType.any,
                            );
                            if (result != null && result.files.single.name.isNotEmpty) {
                              Uint8List? bytes = result.files.single.bytes;
                              // On Android/iOS, bytes can be null — read from path
                              if (bytes == null && result.files.single.path != null) {
                                bytes = await File(result.files.single.path!).readAsBytes();
                              }
                              if (bytes != null) {
                                final maxBytes = FileStorageService.maxFileSizeBytes;
                                if (bytes.length > maxBytes) {
                                  setModalState(() {
                                    pickedFileName = result.files.single.name;
                                    pickedFileBytes = null;
                                    fileSizeError = 'File is ${(bytes!.length / (1024 * 1024)).toStringAsFixed(1)} MB — max allowed is ${maxBytes ~/ (1024 * 1024)} MB. Pick a smaller file.';
                                  });
                                } else {
                                  setModalState(() {
                                    pickedFileName = result.files.single.name;
                                    pickedFileBytes = bytes;
                                    fileSizeError = null;
                                  });
                                }
                              }
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: pickedFileName != null
                                    ? AppColors.primary
                                    : AppColors.divider,
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  pickedFileName != null
                                      ? Icons.insert_drive_file_rounded
                                      : Icons.attach_file_rounded,
                                  color: pickedFileName != null
                                      ? AppColors.primary
                                      : AppColors.textHint,
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    pickedFileName ?? 'Attach a file (optional)',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: pickedFileName != null
                                          ? AppColors.textPrimary
                                          : AppColors.textHint,
                                      fontWeight: pickedFileName != null
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (pickedFileName != null)
                                  GestureDetector(
                                    onTap: () {
                                      setModalState(() {
                                        pickedFileName = null;
                                        pickedFileBytes = null;                                        fileSizeError = null;                                      });
                                    },
                                    child: const Icon(Icons.close_rounded,
                                        size: 20, color: AppColors.textHint),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        // File size error message
                        if (fileSizeError != null) ...[                         
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    fileSizeError!,
                                    style: const TextStyle(fontSize: 13, color: Colors.red, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        // Price summary
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Amount',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Rs. ${gig.price.toInt()}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: fileSizeError != null
                                ? null  // Disable button when file too large
                                : () async {
                              setModalState(() {
                                isLoading = true;
                              });

                              String attachmentFileId = '';
                              String attachmentFileName = '';
                              String attachmentUrl = '';

                              // Upload file to Firestore if one was picked
                              if (pickedFileBytes != null &&
                                  pickedFileName != null) {
                                debugPrint('[Order] File picked: $pickedFileName, bytes=${pickedFileBytes!.length}');

                                setModalState(() {
                                  isUploading = true;
                                });
                                try {
                                  final uploadResult =
                                      await FileStorageService.instance
                                          .uploadFile(
                                    fileBytes: pickedFileBytes!,
                                    fileName: pickedFileName!,
                                    onProgress: (completed, total) {
                                      setModalState(() {
                                        uploadProgress = completed / total;
                                        if (completed == 0) {
                                          uploadStatus = 'Compressing...';
                                        } else if (completed < total) {
                                          uploadStatus = 'Uploading chunk $completed of ${total - 2}...';
                                        } else {
                                          uploadStatus = 'Almost done...';
                                        }
                                      });
                                    },
                                  );
                                  debugPrint('[Order] Upload result: $uploadResult');
                                  if (uploadResult != null) {
                                    attachmentFileId =
                                        uploadResult['fileId'] ?? '';
                                    attachmentFileName =
                                        uploadResult['fileName'] ?? '';
                                    attachmentUrl =
                                        uploadResult['webViewLink'] ?? '';
                                  } else {
                                    debugPrint('[Order] Upload returned null');
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Text('File upload failed. Order will be placed without attachment.'),
                                          backgroundColor: Colors.orange,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      );
                                    }
                                  }
                                } catch (e) {
                                  debugPrint('[Order] Upload exception: $e');
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Upload error: $e'),
                                        backgroundColor: Colors.red,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    );
                                  }
                                }
                                setModalState(() {
                                  isUploading = false;
                                });
                              }

                              if (!context.mounted) return;
                              await context.read<AppState>().placeOrder(
                                gig: gig,
                                requirements:
                                    descController.text.trim().isNotEmpty
                                        ? descController.text.trim()
                                        : 'No description provided',
                                attachmentFileId: attachmentFileId,
                                attachmentFileName: attachmentFileName,
                                attachmentUrl: attachmentUrl,
                              );
                              if (!context.mounted) return;
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                      '✅ Order placed successfully!'),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            },
                            child: isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2.5),
                                  )
                                : Text(fileSizeError != null
                                    ? 'File Too Large'
                                    : 'Place Order'),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    )),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String amount,
      {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: isBold ? 18 : 14,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewItem(String name, String comment, double rating) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              name[0],
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < rating.floor() ? Icons.star : Icons.star_border,
                        size: 14,
                        color: AppColors.starYellow,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                comment,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
