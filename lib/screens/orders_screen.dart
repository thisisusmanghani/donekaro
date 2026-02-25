import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../constants/app_colors.dart';
import '../models/order_model.dart';
import '../providers/app_state.dart';
import '../services/database_service.dart';
import '../services/file_storage_service.dart';
import 'chat_screen.dart';
import 'review_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final role = appState.role;
    final allOrders = appState.orders;

    return SafeArea(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Orders',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  role == 'buyer'
                      ? 'Track your ordered tasks'
                      : 'Manage orders from buyers',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textHint,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  tabAlignment: TabAlignment.start,
                  tabs: const [
                    Tab(text: 'All'),
                    Tab(text: 'Active'),
                    Tab(text: 'Delivered'),
                    Tab(text: 'Completed'),
                  ],
                ),
              ],
            ),
          ),

          // Orders list
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOrdersList(allOrders, role),
                _buildOrdersList(
                    allOrders
                        .where((o) =>
                            o.status == 'pending' || o.status == 'in_progress')
                        .toList(),
                    role),
                _buildOrdersList(
                    allOrders
                        .where((o) => o.status == 'delivered')
                        .toList(),
                    role),
                _buildOrdersList(
                    allOrders
                        .where((o) => o.status == 'completed')
                        .toList(),
                    role),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(List<OrderModel> orders, String role) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📭', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            const Text(
              'No orders yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              role == 'buyer'
                  ? 'Start ordering tasks from students!'
                  : 'Your received orders will appear here',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        return _buildOrderCard(orders[index], role);
      },
    );
  }

  Widget _buildOrderCard(OrderModel order, String role) {
    return GestureDetector(
      onTap: () => _showOrderDetails(context, order, role),
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
          // Top row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order.id,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textHint,
                ),
              ),
              _buildStatusChip(order.status),
            ],
          ),
          const SizedBox(height: 12),
          // Title
          Text(
            order.gigTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          // Buyer/Seller info
          Row(
            children: [
              Icon(
                role == 'buyer'
                    ? Icons.person_outline
                    : Icons.shopping_bag_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                role == 'buyer'
                    ? 'Seller: ${order.sellerName}'
                    : 'Buyer: ${order.buyerName}',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Bottom row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Price
              Text(
                'Rs. ${order.amount.toInt()}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              // Delivery date
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 14, color: AppColors.textHint),
                  const SizedBox(width: 6),
                  Text(
                    '${order.deliveryDate.day}/${order.deliveryDate.month}/${order.deliveryDate.year}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Action buttons
          if (order.status == 'in_progress' && role == 'seller')
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await context.read<AppState>().updateOrderStatus(
                          order.id, 'delivered');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.upload_file, color: Colors.white, size: 18),
                    label: const Text('Upload & Deliver',
                        style: TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final appState = context.read<AppState>();
                      final dbService = DatabaseService();
                      final chatId = await dbService.getOrCreateChat(
                        myId: appState.uid,
                        myName: appState.userName,
                        myAvatar: appState.userAvatar,
                        otherId: order.buyerId,
                        otherName: order.buyerName,
                        otherAvatar: order.buyerName.isNotEmpty
                            ? order.buyerName.split(' ').map((e) => e[0]).take(2).join().toUpperCase()
                            : '\ud83d\udc64',
                      );
                      if (!context.mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatDetailScreen(
                            chatId: chatId,
                            otherUserId: order.buyerId,
                            otherUserName: order.buyerName,
                            otherUserAvatar: order.buyerName.isNotEmpty
                                ? order.buyerName.split(' ').map((e) => e[0]).take(2).join().toUpperCase()
                                : '\ud83d\udc64',
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.chat_outlined, size: 18),
                    label: const Text('Chat with Buyer',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          if (order.status == 'delivered' && role == 'buyer')
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await context.read<AppState>().updateOrderStatus(
                          order.id, 'in_progress');
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      foregroundColor: AppColors.error,
                    ),
                    child: const Text('Request Revision',
                        style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await context.read<AppState>().updateOrderStatus(
                          order.id, 'completed');
                      if (!context.mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReviewScreen(
                            sellerName: order.sellerName,
                            gigTitle: order.gigTitle,
                            orderId: order.id,
                            gigId: order.gigId,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Accept & Review',
                        style:
                            TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ),
              ],
            ),
          if (order.status == 'pending' && role == 'seller')
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await context.read<AppState>().updateOrderStatus(
                              order.id, 'cancelled');
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.error),
                          foregroundColor: AppColors.error,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Reject',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await context.read<AppState>().updateOrderStatus(
                              order.id, 'in_progress');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.check, color: Colors.white, size: 18),
                        label: const Text('Accept Order',
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final appState = context.read<AppState>();
                      final dbService = DatabaseService();
                      final chatId = await dbService.getOrCreateChat(
                        myId: appState.uid,
                        myName: appState.userName,
                        myAvatar: appState.userAvatar,
                        otherId: order.buyerId,
                        otherName: order.buyerName,
                        otherAvatar: order.buyerName.isNotEmpty
                            ? order.buyerName.split(' ').map((e) => e[0]).take(2).join().toUpperCase()
                            : '👤',
                      );
                      if (!context.mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatDetailScreen(
                            chatId: chatId,
                            otherUserId: order.buyerId,
                            otherUserName: order.buyerName,
                            otherUserAvatar: order.buyerName.isNotEmpty
                                ? order.buyerName.split(' ').map((e) => e[0]).take(2).join().toUpperCase()
                                : '👤',
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.chat_outlined, size: 18),
                    label: const Text('Chat with Buyer',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          if (order.status == 'pending' && role == 'buyer')
            Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.hourglass_top,
                        size: 16, color: AppColors.warning),
                    const SizedBox(width: 6),
                    Text(
                      'Waiting for seller to accept...',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.warning,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final appState = context.read<AppState>();
                      final dbService = DatabaseService();
                      final chatId = await dbService.getOrCreateChat(
                        myId: appState.uid,
                        myName: appState.userName,
                        myAvatar: appState.userAvatar,
                        otherId: order.sellerId,
                        otherName: order.sellerName,
                        otherAvatar: order.sellerName.isNotEmpty
                            ? order.sellerName.split(' ').map((e) => e[0]).take(2).join().toUpperCase()
                            : '\ud83d\udc64',
                      );
                      if (!context.mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatDetailScreen(
                            chatId: chatId,
                            otherUserId: order.sellerId,
                            otherUserName: order.sellerName,
                            otherUserAvatar: order.sellerName.isNotEmpty
                                ? order.sellerName.split(' ').map((e) => e[0]).take(2).join().toUpperCase()
                                : '\ud83d\udc64',
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.chat_outlined, size: 18),
                    label: const Text('Chat with Seller',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
        ],
      ),
    ),
    );
  }

  void _showOrderDetails(BuildContext context, OrderModel order, String role) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        // State for auto-loading attachment preview
        Uint8List? _attachmentBytes;
        bool _isLoadingAttachment = false;
        bool _attachmentLoaded = false;
        bool _attachmentFailed = false;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            // Auto-load attachment when the sheet opens
            if (order.attachmentFileName.isNotEmpty &&
                order.attachmentUrl.startsWith('firestore://') &&
                !_isLoadingAttachment &&
                !_attachmentLoaded &&
                !_attachmentFailed) {
              _isLoadingAttachment = true;
              final docId = order.attachmentFileId.isNotEmpty
                  ? order.attachmentFileId
                  : order.attachmentUrl.split('/').last;
              FileStorageService.instance.downloadFile(docId).then((bytes) {
                if (context.mounted) {
                  setSheetState(() {
                    _attachmentBytes = bytes;
                    _isLoadingAttachment = false;
                    _attachmentLoaded = true;
                    _attachmentFailed = bytes == null;
                  });
                }
              });
            }

            final lowerName = order.attachmentFileName.toLowerCase();
            final isImage = lowerName.endsWith('.jpg') ||
                lowerName.endsWith('.jpeg') ||
                lowerName.endsWith('.png') ||
                lowerName.endsWith('.gif') ||
                lowerName.endsWith('.webp');
            final isPdf = lowerName.endsWith('.pdf');

            return Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Order Details',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildDetailRow(Icons.shopping_bag_outlined, 'Gig', order.gigTitle),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.person_outline,
              role == 'buyer' ? 'Seller' : 'Buyer',
              role == 'buyer' ? order.sellerName : order.buyerName,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.attach_money, 'Amount', 'Rs. ${order.amount.toInt()}'),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.calendar_today,
              'Delivery Date',
              '${order.deliveryDate.day}/${order.deliveryDate.month}/${order.deliveryDate.year}',
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.description_outlined, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Text(
                order.requirements.isNotEmpty
                    ? order.requirements
                    : 'No description provided',
                style: TextStyle(
                  fontSize: 14,
                  color: order.requirements.isNotEmpty
                      ? AppColors.textPrimary
                      : AppColors.textHint,
                  height: 1.5,
                ),
              ),
            ),
            // ── Attachment Section with Inline Preview ──
            if (order.attachmentFileName.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.attach_file_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Text(
                    'Attachment',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ── Inline Image Preview ──
              if (isImage && _attachmentBytes != null)
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => Dialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      order.attachmentFileName,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ],
                              ),
                            ),
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                              ),
                              child: Image.memory(_attachmentBytes!, fit: BoxFit.contain),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: Image.memory(
                              _attachmentBytes!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.05),
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(13)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.image_rounded, size: 20, color: AppColors.primary),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  order.attachmentFileName,
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(Icons.zoom_in_rounded, size: 18, color: AppColors.primary),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )

              // ── PDF / Other File Card ──
              else if (!isImage || _attachmentBytes == null)
                GestureDetector(
                  onTap: () async {
                    if (_isLoadingAttachment) return;

                    if (order.attachmentUrl.startsWith('firestore://')) {
                      Uint8List? bytes = _attachmentBytes;
                      if (bytes == null) {
                        // Download first
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Downloading file...'),
                            backgroundColor: AppColors.primary,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                        final docId = order.attachmentFileId.isNotEmpty
                            ? order.attachmentFileId
                            : order.attachmentUrl.split('/').last;
                        bytes = await FileStorageService.instance.downloadFile(docId);
                      }

                      if (bytes != null && context.mounted) {
                        try {
                          // Save to cache directory
                          final dir = await getTemporaryDirectory();
                          final file = File('${dir.path}/${order.attachmentFileName}');
                          await file.writeAsBytes(bytes);
                          debugPrint('[Attachment] File saved to: ${file.path}');

                          // Determine MIME type for better app matching
                          String? mimeType;
                          if (isPdf) {
                            mimeType = 'application/pdf';
                          } else if (lowerName.endsWith('.doc') || lowerName.endsWith('.docx')) {
                            mimeType = 'application/msword';
                          } else if (lowerName.endsWith('.xls') || lowerName.endsWith('.xlsx')) {
                            mimeType = 'application/vnd.ms-excel';
                          } else if (lowerName.endsWith('.ppt') || lowerName.endsWith('.pptx')) {
                            mimeType = 'application/vnd.ms-powerpoint';
                          } else if (lowerName.endsWith('.txt')) {
                            mimeType = 'text/plain';
                          } else if (lowerName.endsWith('.zip')) {
                            mimeType = 'application/zip';
                          }

                          // Open with system chooser (like "Open with Drive/Adobe/etc.")
                          final result = await OpenFilex.open(file.path, type: mimeType);
                          debugPrint('[Attachment] OpenFilex result: ${result.type} - ${result.message}');

                          if (result.type != ResultType.done && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Could not open file: ${result.message}'),
                                backgroundColor: Colors.orange,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          }
                        } catch (e) {
                          debugPrint('[Attachment] Error: $e');
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error opening file: $e'),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          }
                        }
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Failed to download file'),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      }
                    } else {
                      // Legacy URL
                      final uri = Uri.parse(order.attachmentUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        // File type icon
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isPdf
                                ? Colors.red.withOpacity(0.1)
                                : AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isPdf
                                ? Icons.picture_as_pdf_rounded
                                : _isLoadingAttachment
                                    ? Icons.hourglass_top_rounded
                                    : Icons.insert_drive_file_rounded,
                            size: 24,
                            color: isPdf ? Colors.red : AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.attachmentFileName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isLoadingAttachment
                                    ? 'Loading...'
                                    : isPdf
                                        ? 'Tap to open in PDF viewer'
                                        : 'Tap to open with system app',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_isLoadingAttachment)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          Icon(Icons.open_in_new_rounded, size: 18, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
        ),
      );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status) {
      case 'pending':
        bgColor = AppColors.warning.withOpacity(0.1);
        textColor = AppColors.warning;
        label = 'Pending';
        icon = Icons.hourglass_top;
        break;
      case 'in_progress':
        bgColor = AppColors.info.withOpacity(0.1);
        textColor = AppColors.info;
        label = 'In Progress';
        icon = Icons.autorenew;
        break;
      case 'delivered':
        bgColor = AppColors.secondary.withOpacity(0.1);
        textColor = AppColors.secondary;
        label = 'Delivered';
        icon = Icons.check_circle_outline;
        break;
      case 'completed':
        bgColor = AppColors.success.withOpacity(0.1);
        textColor = AppColors.success;
        label = 'Completed';
        icon = Icons.verified;
        break;
      default:
        bgColor = AppColors.error.withOpacity(0.1);
        textColor = AppColors.error;
        label = 'Cancelled';
        icon = Icons.cancel_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
