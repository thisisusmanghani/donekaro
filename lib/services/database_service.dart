import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/gig_model.dart';
import '../models/order_model.dart';
import '../providers/app_state.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ══════════════════════════════════════════════
  //  GIGS
  // ══════════════════════════════════════════════

  // Add a gig
  Future<String?> addGig(GigModel gig, String userId) async {
    try {
      final docRef = await _firestore.collection('gigs').add({
        'title': gig.title,
        'description': gig.description,
        'category': gig.category,
        'price': gig.price,
        'deliveryDays': gig.deliveryDays,
        'deliveryUnit': gig.deliveryUnit,
        'sellerName': gig.sellerName,
        'sellerAvatar': gig.sellerAvatar,
        'sellerDepartment': gig.sellerDepartment,
        'rating': gig.rating,
        'reviewCount': gig.reviewCount,
        'imageUrl': gig.imageUrl,
        'sellerId': userId,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      return null;
    }
  }

  // Get all gigs (stream)
  Stream<List<GigModel>> getGigsStream() {
    return _firestore
        .collection('gigs')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return GigModel(
                id: doc.id,
                title: data['title'] ?? '',
                description: data['description'] ?? '',
                category: data['category'] ?? '',
                price: (data['price'] ?? 0).toDouble(),
                deliveryDays: data['deliveryDays'] ?? 1,
                deliveryUnit: data['deliveryUnit'] ?? 'days',
                sellerName: data['sellerName'] ?? '',
                sellerAvatar: data['sellerAvatar'] ?? '',
                sellerDepartment: data['sellerDepartment'] ?? '',
                sellerId: data['sellerId'] ?? '',
                rating: (data['rating'] ?? 0).toDouble(),
                reviewCount: data['reviewCount'] ?? 0,
                imageUrl: data['imageUrl'] ?? '',
              );
            }).toList());
  }

  // Get all gigs (one-time fetch)
  Future<List<GigModel>> getGigs() async {
    try {
      // Try with ordering first
      final snapshot = await _firestore
          .collection('gigs')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();
      debugPrint('getGigs: fetched ${snapshot.docs.length} gigs with index');
      return _mapGigDocs(snapshot.docs);
    } catch (e) {
      debugPrint('getGigs indexed query failed: $e');
      // Fallback: fetch without ordering (no composite index needed)
      try {
        final snapshot = await _firestore
            .collection('gigs')
            .where('isActive', isEqualTo: true)
            .get();
        debugPrint('getGigs fallback: fetched ${snapshot.docs.length} gigs');
        return _mapGigDocs(snapshot.docs);
      } catch (e2) {
        debugPrint('getGigs fallback also failed: $e2');
        // Last resort: fetch ALL gigs docs
        try {
          final snapshot = await _firestore.collection('gigs').get();
          debugPrint('getGigs all docs: fetched ${snapshot.docs.length} gigs');
          final docs = snapshot.docs.where((doc) {
            final data = doc.data();
            return data['isActive'] == true || !data.containsKey('isActive');
          }).toList();
          return _mapGigDocs(docs);
        } catch (e3) {
          debugPrint('getGigs all attempts failed: $e3');
          return [];
        }
      }
    }
  }

  List<GigModel> _mapGigDocs(List<dynamic> docs) {
    return docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return GigModel(
        id: doc.id,
        title: data['title'] ?? '',
        description: data['description'] ?? '',
        category: data['category'] ?? '',
        price: (data['price'] ?? 0).toDouble(),
        deliveryDays: data['deliveryDays'] ?? 1,
        deliveryUnit: data['deliveryUnit'] ?? 'days',
        sellerName: data['sellerName'] ?? '',
        sellerAvatar: data['sellerAvatar'] ?? '',
        sellerDepartment: data['sellerDepartment'] ?? '',
        sellerId: data['sellerId'] ?? '',
        rating: (data['rating'] ?? 0).toDouble(),
        reviewCount: data['reviewCount'] ?? 0,
        imageUrl: data['imageUrl'] ?? '',
      );
    }).toList();
  }

  // Get gigs by seller
  Future<List<GigModel>> getGigsBySeller(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('gigs')
          .where('sellerId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();
      debugPrint('getGigsBySeller: fetched ${snapshot.docs.length} gigs for $userId');
      return _mapGigDocs(snapshot.docs);
    } catch (e) {
      debugPrint('getGigsBySeller failed: $e');
      // Fallback: just query by sellerId without isActive
      try {
        final snapshot = await _firestore
            .collection('gigs')
            .where('sellerId', isEqualTo: userId)
            .get();
        debugPrint('getGigsBySeller fallback: fetched ${snapshot.docs.length} gigs');
        return _mapGigDocs(snapshot.docs);
      } catch (e2) {
        debugPrint('getGigsBySeller fallback also failed: $e2');
        return [];
      }
    }
  }

  // Delete gig (soft delete)
  Future<bool> deleteGig(String gigId) async {
    try {
      await _firestore.collection('gigs').doc(gigId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ══════════════════════════════════════════════
  //  ORDERS
  // ══════════════════════════════════════════════

  // Place order
  Future<String?> placeOrder({
    required String gigId,
    required String gigTitle,
    required String buyerId,
    required String buyerName,
    required String buyerEmail,
    required String buyerDepartment,
    required String sellerId,
    required String sellerName,
    required double amount,
    required int deliveryDays,
    required String deliveryUnit,
    required String requirements,
    String attachmentFileId = '',
    String attachmentFileName = '',
    String attachmentUrl = '',
  }) async {
    try {
      final docRef = await _firestore.collection('orders').add({
        'gigId': gigId,
        'gigTitle': gigTitle,
        'buyerId': buyerId,
        'buyerName': buyerName,
        'buyerEmail': buyerEmail,
        'buyerDepartment': buyerDepartment,
        'sellerId': sellerId,
        'sellerName': sellerName,
        'amount': amount,
        'status': 'pending',
        'requirements': requirements,
        'attachmentFileId': attachmentFileId,
        'attachmentFileName': attachmentFileName,
        'attachmentUrl': attachmentUrl,
        'orderDate': FieldValue.serverTimestamp(),
        'deliveryDate': Timestamp.fromDate(
            deliveryUnit == 'hours'
                ? DateTime.now().add(Duration(hours: deliveryDays))
                : DateTime.now().add(Duration(days: deliveryDays))),
        'createdAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      return null;
    }
  }

  // Get orders for user (buyer or seller)
  Stream<List<OrderModel>> getOrdersStream(String userId) {
    // We query where user is buyer OR seller using two separate queries
    // and merge them
    return _firestore
        .collection('orders')
        .where('buyerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((buyerSnap) async {
      final sellerSnap = await _firestore
          .collection('orders')
          .where('sellerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final allDocs = [...buyerSnap.docs, ...sellerSnap.docs];

      // Remove duplicates
      final seen = <String>{};
      final uniqueDocs = allDocs.where((d) => seen.add(d.id)).toList();

      return uniqueDocs.map((doc) {
        final data = doc.data();
        return OrderModel(
          id: doc.id,
          gigId: data['gigId'] ?? '',
          gigTitle: data['gigTitle'] ?? '',
          buyerName: data['buyerName'] ?? '',
          sellerName: data['sellerName'] ?? '',
          buyerId: data['buyerId'] ?? '',
          sellerId: data['sellerId'] ?? '',
          amount: (data['amount'] ?? 0).toDouble(),
          status: data['status'] ?? 'pending',
          orderDate: (data['orderDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
          deliveryDate:
              (data['deliveryDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
          requirements: data['requirements'] ?? '',
          attachmentFileId: data['attachmentFileId'] ?? '',
          attachmentFileName: data['attachmentFileName'] ?? '',
          attachmentUrl: data['attachmentUrl'] ?? '',
        );
      }).toList()
        ..sort((a, b) => b.orderDate.compareTo(a.orderDate));
    });
  }

  // Get orders (one-time)
  Future<List<OrderModel>> getOrders(String userId) async {
    try {
      // Try buyer orders with ordering
      List<QueryDocumentSnapshot<Map<String, dynamic>>> buyerDocs = [];
      try {
        final buyerSnap = await _firestore
            .collection('orders')
            .where('buyerId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .get();
        buyerDocs = buyerSnap.docs;
      } catch (_) {
        // Fallback: without ordering
        final buyerSnap = await _firestore
            .collection('orders')
            .where('buyerId', isEqualTo: userId)
            .get();
        buyerDocs = buyerSnap.docs;
      }

      // Try seller orders with ordering
      List<QueryDocumentSnapshot<Map<String, dynamic>>> sellerDocs = [];
      try {
        final sellerSnap = await _firestore
            .collection('orders')
            .where('sellerId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .get();
        sellerDocs = sellerSnap.docs;
      } catch (_) {
        // Fallback: without ordering
        final sellerSnap = await _firestore
            .collection('orders')
            .where('sellerId', isEqualTo: userId)
            .get();
        sellerDocs = sellerSnap.docs;
      }

      debugPrint('getOrders: buyer=${buyerDocs.length}, seller=${sellerDocs.length} for $userId');

      final allDocs = [...buyerDocs, ...sellerDocs];
      final seen = <String>{};
      final uniqueDocs = allDocs.where((d) => seen.add(d.id)).toList();

      return uniqueDocs.map((doc) {
        final data = doc.data();
        return OrderModel(
          id: doc.id,
          gigId: data['gigId'] ?? '',
          gigTitle: data['gigTitle'] ?? '',
          buyerName: data['buyerName'] ?? '',
          sellerName: data['sellerName'] ?? '',
          buyerId: data['buyerId'] ?? '',
          sellerId: data['sellerId'] ?? '',
          amount: (data['amount'] ?? 0).toDouble(),
          status: data['status'] ?? 'pending',
          orderDate: (data['orderDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
          deliveryDate:
              (data['deliveryDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
          requirements: data['requirements'] ?? '',
          attachmentFileId: data['attachmentFileId'] ?? '',
          attachmentFileName: data['attachmentFileName'] ?? '',
          attachmentUrl: data['attachmentUrl'] ?? '',
        );
      }).toList()
        ..sort((a, b) => b.orderDate.compareTo(a.orderDate));
    } catch (e) {
      debugPrint('getOrders failed: $e');
      return [];
    }
  }

  // Update order status
  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // Submit review for a gig
  Future<bool> submitReview({
    required String gigId,
    required String orderId,
    required String reviewerName,
    required String reviewerId,
    required int rating,
    required String comment,
    required List<String> tags,
  }) async {
    try {
      // Save review document
      await _firestore.collection('reviews').add({
        'gigId': gigId,
        'orderId': orderId,
        'reviewerName': reviewerName,
        'reviewerId': reviewerId,
        'rating': rating,
        'comment': comment,
        'tags': tags,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update gig's average rating
      final reviewsSnap = await _firestore
          .collection('reviews')
          .where('gigId', isEqualTo: gigId)
          .get();

      double totalRating = 0;
      for (final doc in reviewsSnap.docs) {
        totalRating += (doc.data()['rating'] ?? 0).toDouble();
      }
      final avgRating = totalRating / reviewsSnap.docs.length;

      await _firestore.collection('gigs').doc(gigId).update({
        'rating': double.parse(avgRating.toStringAsFixed(1)),
        'reviewCount': reviewsSnap.docs.length,
      });

      return true;
    } catch (e) {
      debugPrint('submitReview failed: $e');
      return false;
    }
  }

  // Get reviews for a specific gig
  Future<List<Map<String, dynamic>>> getReviewsForGig(String gigId) async {
    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('gigId', isEqualTo: gigId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'reviewerName': data['reviewerName'] ?? '',
          'rating': (data['rating'] ?? 0).toDouble(),
          'comment': data['comment'] ?? '',
          'tags': List<String>.from(data['tags'] ?? []),
        };
      }).toList();
    } catch (e) {
      debugPrint('getReviewsForGig failed: $e');
      return [];
    }
  }

  // Credit seller wallet atomically
  Future<bool> creditSellerWallet(String sellerId, double earning, String gigTitle) async {
    try {
      await _firestore.collection('users').doc(sellerId).update({
        'walletBalance': FieldValue.increment(earning),
        'totalEarned': FieldValue.increment(earning),
      });
      // Add transaction record for seller
      await addTransaction(
        userId: sellerId,
        title: 'Earned from: $gigTitle',
        amount: earning,
        type: 'earning',
        status: 'completed',
      );
      return true;
    } catch (e) {
      debugPrint('creditSellerWallet failed: $e');
      return false;
    }
  }

  // ══════════════════════════════════════════════
  //  TRANSACTIONS
  // ══════════════════════════════════════════════

  Future<String?> addTransaction({
    required String userId,
    required String title,
    required double amount,
    required String type,
    required String status,
    String description = '',
  }) async {
    try {
      final docRef =
          await _firestore.collection('users').doc(userId).collection('transactions').add({
        'title': title,
        'description': description,
        'amount': amount,
        'type': type,
        'status': status,
        'date': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      return null;
    }
  }

  Future<List<TransactionItem>> getTransactions(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .orderBy('date', descending: true)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return TransactionItem(
          id: doc.id,
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          amount: (data['amount'] ?? 0).toDouble(),
          date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
          type: data['type'] ?? '',
          status: data['status'] ?? '',
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // ══════════════════════════════════════════════
  //  NOTIFICATIONS
  // ══════════════════════════════════════════════

  Future<void> addNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'title': title,
        'message': message,
        'type': type,
        'isRead': false,
        'time': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Stream<List<NotificationItem>> getNotificationsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('time', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return NotificationItem(
                id: doc.id,
                title: data['title'] ?? '',
                message: data['message'] ?? '',
                time: (data['time'] as Timestamp?)?.toDate() ?? DateTime.now(),
                type: data['type'] ?? 'system',
                isRead: data['isRead'] ?? false,
              );
            }).toList());
  }

  Future<void> markNotificationRead(String userId, String notifId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notifId)
          .update({'isRead': true});
    } catch (_) {}
  }

  Future<void> markAllNotificationsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (_) {}
  }

  // ══════════════════════════════════════════════
  //  CHAT
  // ══════════════════════════════════════════════

  // Create or get chat between two users
  Future<String> getOrCreateChat({
    required String myId,
    required String myName,
    required String myAvatar,
    required String otherId,
    required String otherName,
    required String otherAvatar,
  }) async {
    try {
      // Check if chat already exists
      final existing = await _firestore
          .collection('chats')
          .where('participants', arrayContains: myId)
          .get();

      for (final doc in existing.docs) {
        final participants = List<String>.from(doc.data()['participants'] ?? []);
        if (participants.contains(otherId)) {
          return doc.id;
        }
      }

      // Create new chat
      final docRef = await _firestore.collection('chats').add({
        'participants': [myId, otherId],
        'participantNames': {myId: myName, otherId: otherName},
        'participantAvatars': {myId: myAvatar, otherId: otherAvatar},
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      debugPrint('getOrCreateChat error: $e');
      return '';
    }
  }

  // Get all chats for a user
  Future<List<Map<String, dynamic>>> getChatsForUser(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .get();

      final chats = <Map<String, dynamic>>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final lastMessage = data['lastMessage'] ?? '';
        // Skip chats with no messages
        if (lastMessage.toString().isEmpty) continue;

        chats.add({
          'id': doc.id,
          'participants': List<String>.from(data['participants'] ?? []),
          'participantNames': Map<String, dynamic>.from(data['participantNames'] ?? {}),
          'participantAvatars': Map<String, dynamic>.from(data['participantAvatars'] ?? {}),
          'lastMessage': lastMessage,
          'lastMessageTime': (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
        });
      }

      // Sort by lastMessageTime descending
      chats.sort((a, b) => (b['lastMessageTime'] as DateTime).compareTo(a['lastMessageTime'] as DateTime));
      return chats;
    } catch (e) {
      debugPrint('getChatsForUser error: $e');
      return [];
    }
  }

  // Get chats stream for a user (live updates)
  Stream<List<Map<String, dynamic>>> getChatsStream(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      final chats = <Map<String, dynamic>>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        chats.add({
          'id': doc.id,
          'participants': List<String>.from(data['participants'] ?? []),
          'participantNames': Map<String, dynamic>.from(data['participantNames'] ?? {}),
          'participantAvatars': Map<String, dynamic>.from(data['participantAvatars'] ?? {}),
          'lastMessage': data['lastMessage'] ?? '',
          'lastMessageTime': (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
        });
      }
      chats.sort((a, b) => (b['lastMessageTime'] as DateTime).compareTo(a['lastMessageTime'] as DateTime));
      return chats;
    });
  }

  // Send message
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
  }) async {
    try {
      await _firestore.collection('chats').doc(chatId).collection('messages').add({
        'senderId': senderId,
        'text': text,
        'time': FieldValue.serverTimestamp(),
      });
      // Update last message
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  // Get messages stream
  Stream<List<Map<String, dynamic>>> getMessagesStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('time', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'senderId': data['senderId'] ?? '',
                'text': data['text'] ?? '',
                'time': (data['time'] as Timestamp?)?.toDate() ?? DateTime.now(),
              };
            }).toList());
  }

  // ══════════════════════════════════════════════
  //  WALLET (update user balance)
  // ══════════════════════════════════════════════

  Future<bool> updateWallet(String userId, {
    double? walletBalance,
    double? totalEarned,
    double? totalWithdrawn,
  }) async {
    try {
      final Map<String, dynamic> data = {'updatedAt': FieldValue.serverTimestamp()};
      if (walletBalance != null) data['walletBalance'] = walletBalance;
      if (totalEarned != null) data['totalEarned'] = totalEarned;
      if (totalWithdrawn != null) data['totalWithdrawn'] = totalWithdrawn;
      await _firestore.collection('users').doc(userId).update(data);
      return true;
    } catch (e) {
      return false;
    }
  }
}
