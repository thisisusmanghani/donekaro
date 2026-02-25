import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/gig_model.dart';
import '../models/order_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

class AppState extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final DatabaseService _dbService = DatabaseService();

  // ─── User Info ───
  String _uid = '';
  String _userName = '';
  String _userEmail = '';
  String _userDepartment = '';
  String _userUniversity = '';
  String _userAvatar = '';
  String _userPhone = '';
  String _role = 'buyer';
  bool _hasSelectedRole = false;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String _errorMessage = '';

  // ─── Wallet ───
  double _walletBalance = 0;
  double _totalEarned = 0;
  double _totalWithdrawn = 0;

  // ─── Data ───
  List<GigModel> _allGigs = []; // All gigs from Firestore
  List<GigModel> _myGigs = []; // Seller's own gigs
  List<OrderModel> _orders = [];
  List<TransactionItem> _transactions = [];
  List<NotificationItem> _notifications = [];
  List<ChatConversation> _conversations = [];

  // ─── Getters ───
  String get uid => _uid;
  String get userName => _userName;
  String get userEmail => _userEmail;
  String get userDepartment => _userDepartment;
  String get userUniversity => _userUniversity;
  String get userAvatar => _userAvatar;
  String get userPhone => _userPhone;
  String get role => _role;
  bool get hasSelectedRole => _hasSelectedRole;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  double get walletBalance => _walletBalance;
  double get totalEarned => _totalEarned;
  double get totalWithdrawn => _totalWithdrawn;
  // Buyers see all gigs, sellers see only their own
  List<GigModel> get gigs => _role == 'seller' ? _myGigs : _allGigs;
  List<GigModel> get allGigs => _allGigs;
  List<GigModel> get myGigs => _myGigs;
  List<OrderModel> get orders => _orders;
  List<TransactionItem> get transactions => _transactions;
  List<NotificationItem> get notifications => _notifications;
  List<ChatConversation> get conversations => _conversations;

  // ══════════════════════════════════════════════
  //  AUTH - Firebase
  // ══════════════════════════════════════════════

  // ─── Login ───
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    final result = await _authService.login(
      email: email,
      password: password,
    );

    if (result['success'] == true) {
      final User user = result['user'];
      _uid = user.uid;
      _userEmail = user.email ?? email;

      // Load user data from Firestore
      await _loadUserData(user.uid);

      _isLoggedIn = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['error'] ?? 'Login failed';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Signup ───
  Future<bool> signup({
    required String name,
    required String email,
    required String password,
    required String department,
    required String university,
    String phone = '',
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final result = await _authService.signUp(
        name: name,
        email: email,
        password: password,
        department: department,
        university: university,
        phone: phone,
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        return {'success': false, 'error': 'Request timeout. Internet check kro aur dobara try kro.'};
      });

      if (result['success'] == true) {
        final User user = result['user'];
        _uid = user.uid;
        _userName = name.trim();
        _userEmail = email.trim();
        _userDepartment = department.trim();
        _userUniversity = university;
        _userPhone = phone;
        _userAvatar =
            name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase();
        _walletBalance = 0;
        _totalEarned = 0;
        _totalWithdrawn = 0;
        _hasSelectedRole = false;
        _isLoggedIn = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['error'] ?? 'Signup failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Signup error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Load user data from Firestore ───
  Future<void> _loadUserData(String uid) async {
    try {
      final userData = await _authService.getUserData(uid)
          .timeout(const Duration(seconds: 10));
      if (userData != null) {
        _userName = userData['name'] ?? '';
        _userEmail = userData['email'] ?? '';
        _userDepartment = userData['department'] ?? '';
        _userUniversity = userData['university'] ?? '';
        _userPhone = userData['phone'] ?? '';
        _userAvatar = userData['avatar'] ?? '';
        _role = userData['role'] ?? '';
        // If role is set (non-empty), hasSelectedRole must be true
        if (_role.isNotEmpty) {
          _hasSelectedRole = true;
        } else {
          _hasSelectedRole = userData['hasSelectedRole'] ?? false;
        }
        _walletBalance = (userData['walletBalance'] ?? 0).toDouble();
        _totalEarned = (userData['totalEarned'] ?? 0).toDouble();
        _totalWithdrawn = (userData['totalWithdrawn'] ?? 0).toDouble();
      }
    } catch (_) {
      // If Firestore fetch fails, keep existing local data
    }
  }

  // ─── Check if already logged in (auto-login) ───
  Future<bool> checkAuthState() async {
    final user = _authService.currentUser;
    if (user != null) {
      _uid = user.uid;
      _userEmail = user.email ?? '';
      await _loadUserData(user.uid);
      _isLoggedIn = true;
      await loadAllData();
      notifyListeners();
      return true;
    }
    return false;
  }

  // Whether to show role selection or go to home
  bool get shouldShowRoleSelection => !_hasSelectedRole || _role.isEmpty;

  // ─── Google Sign-In ───
  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final result = await _authService.signInWithGoogle();

      if (result['success'] == true) {
        final User user = result['user'];
        _uid = user.uid;
        _userEmail = user.email ?? '';

        // Load user data from Firestore
        await _loadUserData(user.uid);

        _isLoggedIn = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['error'] ?? 'Google sign-in failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Google sign-in error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Logout ───
  Future<void> logout() async {
    await _authService.logout();
    _uid = '';
    _userName = '';
    _userEmail = '';
    _userDepartment = '';
    _userUniversity = '';
    _userAvatar = '';
    _userPhone = '';
    _role = 'buyer';
    _hasSelectedRole = false;
    _isLoggedIn = false;
    _walletBalance = 0;
    _totalEarned = 0;
    _totalWithdrawn = 0;
    _allGigs = [];
    _myGigs = [];
    _orders = [];
    _transactions = [];
    _notifications = [];
    _conversations = [];
    _errorMessage = '';
    notifyListeners();
  }

  // ─── Reset Password ───
  Future<Map<String, dynamic>> resetPassword(String email) async {
    return await _authService.resetPassword(email);
  }

  // ══════════════════════════════════════════════
  //  ROLE
  // ══════════════════════════════════════════════

  Future<void> setRole(String role) async {
    _role = role;
    _hasSelectedRole = true;
    notifyListeners();
    if (_uid.isNotEmpty) {
      try {
        await _authService.updateUserProfile(_uid, {
          'role': role,
          'hasSelectedRole': true,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      } catch (_) {}
    }
  }

  // Role is permanent — no switching allowed after selection

  // ══════════════════════════════════════════════
  //  PROFILE
  // ══════════════════════════════════════════════

  Future<void> updateProfile({String? name, String? department, String? phone}) async {
    final Map<String, dynamic> updates = {};
    if (name != null) {
      _userName = name;
      _userAvatar =
          name.split(' ').map((e) => e[0]).take(2).join().toUpperCase();
      updates['name'] = name;
      updates['avatar'] = _userAvatar;
    }
    if (department != null) {
      _userDepartment = department;
      updates['department'] = department;
    }
    if (phone != null) {
      _userPhone = phone;
      updates['phone'] = phone;
    }
    if (_uid.isNotEmpty && updates.isNotEmpty) {
      await _authService.updateUserProfile(_uid, updates);
    }
    notifyListeners();
  }

  // ══════════════════════════════════════════════
  //  LOAD ALL DATA
  // ══════════════════════════════════════════════

  Future<void> loadGigs() async {
    _allGigs = await _dbService.getGigs();
    if (_role == 'seller' && _uid.isNotEmpty) {
      _myGigs = await _dbService.getGigsBySeller(_uid);
    }
    notifyListeners();
  }

  Future<void> loadAllData() async {
    if (_uid.isEmpty) return;
    _isLoading = true;
    notifyListeners();

    try {
      // Load ALL gigs from Firestore (for buyers)
      _allGigs = await _dbService.getGigs();
      debugPrint('loadAllData: loaded ${_allGigs.length} allGigs, role=$_role');
      
      // Load seller's own gigs
      if (_role == 'seller') {
        _myGigs = await _dbService.getGigsBySeller(_uid);
        debugPrint('loadAllData: loaded ${_myGigs.length} myGigs for seller');
      }

      // Load orders
      _orders = await _dbService.getOrders(_uid);
      debugPrint('loadAllData: loaded ${_orders.length} orders for $_uid');

      // Load transactions
      _transactions = await _dbService.getTransactions(_uid);

      // Load user data (refresh wallet)
      await _loadUserData(_uid);
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  // ══════════════════════════════════════════════
  //  GIGS
  // ══════════════════════════════════════════════

  Future<void> addGig(GigModel gig) async {
    final gigId = await _dbService.addGig(gig, _uid);
    if (gigId != null) {
      final newGig = GigModel(
        id: gigId,
        title: gig.title,
        description: gig.description,
        category: gig.category,
        price: gig.price,
        deliveryDays: gig.deliveryDays,
        deliveryUnit: gig.deliveryUnit,
        sellerName: gig.sellerName,
        sellerAvatar: gig.sellerAvatar,
        sellerDepartment: gig.sellerDepartment,
        sellerId: _uid,
        rating: gig.rating,
        reviewCount: gig.reviewCount,
        imageUrl: gig.imageUrl,
      );
      _myGigs.insert(0, newGig);
      _allGigs.insert(0, newGig);

      // Update seller's totalGigs count in Firestore
      if (_uid.isNotEmpty) {
        try {
          await _authService.updateUserProfile(_uid, {
            'totalGigs': _myGigs.length,
          });
        } catch (_) {}
      }

      notifyListeners();
    }
  }

  Future<void> removeGig(String gigId) async {
    final success = await _dbService.deleteGig(gigId);
    if (success) {
      _myGigs.removeWhere((g) => g.id == gigId);
      _allGigs.removeWhere((g) => g.id == gigId);
      notifyListeners();
    }
  }

  List<GigModel> getGigsByCategory(String category) {
    final source = _role == 'seller' ? _myGigs : _allGigs;
    if (category == 'All') return source;
    return source.where((g) => g.category == category).toList();
  }

  List<GigModel> searchGigs(String query) {
    final source = _role == 'seller' ? _myGigs : _allGigs;
    if (query.isEmpty) return source;
    final q = query.toLowerCase();
    return source
        .where((g) =>
            g.title.toLowerCase().contains(q) ||
            g.description.toLowerCase().contains(q) ||
            g.category.toLowerCase().contains(q) ||
            g.sellerName.toLowerCase().contains(q))
        .toList();
  }

  // ══════════════════════════════════════════════
  //  ORDERS
  // ══════════════════════════════════════════════

  Future<void> placeOrder({
    required GigModel gig,
    required String requirements,
    String attachmentFileId = '',
    String attachmentFileName = '',
    String attachmentUrl = '',
  }) async {
    final orderId = await _dbService.placeOrder(
      gigId: gig.id,
      gigTitle: gig.title,
      buyerId: _uid,
      buyerName: _userName,
      buyerEmail: _userEmail,
      buyerDepartment: _userDepartment,
      sellerId: gig.sellerId,
      sellerName: gig.sellerName,
      amount: gig.price,
      deliveryDays: gig.deliveryDays,
      deliveryUnit: gig.deliveryUnit,
      requirements: requirements,
      attachmentFileId: attachmentFileId,
      attachmentFileName: attachmentFileName,
      attachmentUrl: attachmentUrl,
    );

    if (orderId != null) {
      final deliveryDate = gig.deliveryUnit == 'hours'
          ? DateTime.now().add(Duration(hours: gig.deliveryDays))
          : DateTime.now().add(Duration(days: gig.deliveryDays));
      final order = OrderModel(
        id: orderId,
        gigId: gig.id,
        gigTitle: gig.title,
        buyerName: _userName,
        sellerName: gig.sellerName,
        buyerId: _uid,
        sellerId: gig.sellerId,
        amount: gig.price,
        status: 'pending',
        orderDate: DateTime.now(),
        deliveryDate: deliveryDate,
        requirements: requirements,
        attachmentFileId: attachmentFileId,
        attachmentFileName: attachmentFileName,
        attachmentUrl: attachmentUrl,
      );
      _orders.insert(0, order);

      // Add notification for buyer
      await _dbService.addNotification(
        userId: _uid,
        title: 'Order Placed! 🎉',
        message: 'Your order for "${gig.title}" has been placed successfully.',
        type: 'order',
      );

      // Add notification for seller
      if (gig.sellerId.isNotEmpty) {
        await _dbService.addNotification(
          userId: gig.sellerId,
          title: 'New Order Received! 🎉',
          message: '$_userName ordered your gig "${gig.title}" for Rs ${gig.price.toStringAsFixed(0)}.',
          type: 'order',
        );
      }

      // Add transaction
      await _dbService.addTransaction(
        userId: _uid,
        title: 'Order: ${gig.title}',
        amount: -gig.price,
        type: 'payment',
        status: 'completed',
      );

      // Refresh local
      _transactions = await _dbService.getTransactions(_uid);

      // Update buyer's totalOrders in Firestore
      try {
        await _authService.updateUserProfile(_uid, {
          'totalOrders': _orders.length,
        });
      } catch (_) {}

      notifyListeners();
    }
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    final success = await _dbService.updateOrderStatus(orderId, newStatus);
    if (success) {
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        final old = _orders[index];
        _orders[index] = OrderModel(
          id: old.id,
          gigTitle: old.gigTitle,
          buyerName: old.buyerName,
          sellerName: old.sellerName,
          buyerId: old.buyerId,
          sellerId: old.sellerId,
          amount: old.amount,
          status: newStatus,
          orderDate: old.orderDate,
          deliveryDate: old.deliveryDate,
        );

        if (newStatus == 'completed') {
          final earning = old.amount * 0.85;
          // Credit the SELLER's wallet, not current user
          await _dbService.creditSellerWallet(old.sellerId, earning, old.gigTitle);
          // If current user is the seller, update local state too
          if (_uid == old.sellerId) {
            _walletBalance += earning;
            _totalEarned += earning;
          }
          _transactions = await _dbService.getTransactions(_uid);
        }

        notifyListeners();
      }
    }
  }

  // ══════════════════════════════════════════════
  //  WALLET
  // ══════════════════════════════════════════════

  Future<void> withdrawFunds(double amount) async {
    if (amount <= _walletBalance) {
      _walletBalance -= amount;
      _totalWithdrawn += amount;

      await _dbService.updateWallet(_uid,
          walletBalance: _walletBalance, totalWithdrawn: _totalWithdrawn);

      await _dbService.addTransaction(
        userId: _uid,
        title: 'Withdrawal',
        amount: -amount,
        type: 'withdrawal',
        status: 'pending',
        description: 'Withdrawal request',
      );

      await _dbService.addNotification(
        userId: _uid,
        title: 'Withdrawal Requested',
        message: 'Rs. ${amount.toInt()} withdrawal is being processed.',
        type: 'wallet',
      );

      _transactions = await _dbService.getTransactions(_uid);
      notifyListeners();
    }
  }

  // ══════════════════════════════════════════════
  //  NOTIFICATIONS
  // ══════════════════════════════════════════════

  Future<void> loadNotifications() async {
    if (_uid.isEmpty) return;
    _dbService.getNotificationsStream(_uid).listen((notifs) {
      _notifications = notifs;
      notifyListeners();
    });
  }

  Future<void> markNotificationRead(String id) async {
    if (_uid.isEmpty) return;
    await _dbService.markNotificationRead(_uid, id);
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = NotificationItem(
        id: _notifications[index].id,
        title: _notifications[index].title,
        message: _notifications[index].message,
        time: _notifications[index].time,
        type: _notifications[index].type,
        isRead: true,
      );
      notifyListeners();
    }
  }

  Future<void> markAllNotificationsRead() async {
    if (_uid.isEmpty) return;
    await _dbService.markAllNotificationsRead(_uid);
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = NotificationItem(
        id: _notifications[i].id,
        title: _notifications[i].title,
        message: _notifications[i].message,
        time: _notifications[i].time,
        type: _notifications[i].type,
        isRead: true,
      );
    }
    notifyListeners();
  }

  int get unreadNotificationCount =>
      _notifications.where((n) => !n.isRead).length;

  // ─── Clear error ───
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }
}

// ─── Extra Models ───

class TransactionItem {
  final String id;
  final String title;
  final String description;
  final double amount;
  final DateTime date;
  final String type;
  final String status;

  TransactionItem({
    required this.id,
    required this.title,
    this.description = '',
    required this.amount,
    required this.date,
    required this.type,
    required this.status,
  });
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime time;
  final String type;
  final bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    required this.isRead,
  });
}

class ChatConversation {
  final String id;
  final String otherUserName;
  final String otherUserAvatar;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final List<ChatMessage> messages;

  ChatConversation({
    required this.id,
    required this.otherUserName,
    required this.otherUserAvatar,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.messages,
  });
}

class ChatMessage {
  final String id;
  final String text;
  final bool isMe;
  final DateTime time;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isMe,
    required this.time,
  });
}
