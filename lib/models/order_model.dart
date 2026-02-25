class OrderModel {
  final String id;
  final String gigId;
  final String gigTitle;
  final String buyerName;
  final String sellerName;
  final String buyerId;
  final String sellerId;
  final double amount;
  final String status; // pending, in_progress, delivered, completed, cancelled
  final DateTime orderDate;
  final DateTime deliveryDate;
  final String requirements;
  final String attachmentFileId;
  final String attachmentFileName;
  final String attachmentUrl;

  OrderModel({
    required this.id,
    this.gigId = '',
    required this.gigTitle,
    required this.buyerName,
    required this.sellerName,
    this.buyerId = '',
    this.sellerId = '',
    required this.amount,
    required this.status,
    required this.orderDate,
    required this.deliveryDate,
    this.requirements = '',
    this.attachmentFileId = '',
    this.attachmentFileName = '',
    this.attachmentUrl = '',
  });
}

List<OrderModel> dummyOrders = [
  OrderModel(
    id: 'ORD-001',
    gigTitle: 'Professional PPT Design',
    buyerName: 'Usman Shah',
    sellerName: 'Ahmed Khan',
    amount: 1500,
    status: 'in_progress',
    orderDate: DateTime.now().subtract(const Duration(days: 1)),
    deliveryDate: DateTime.now().add(const Duration(days: 1)),
  ),
  OrderModel(
    id: 'ORD-002',
    gigTitle: 'Python Bug Fixing',
    buyerName: 'Zain Ul Abideen',
    sellerName: 'Bilal Raza',
    amount: 2000,
    status: 'delivered',
    orderDate: DateTime.now().subtract(const Duration(days: 3)),
    deliveryDate: DateTime.now().subtract(const Duration(days: 1)),
  ),
  OrderModel(
    id: 'ORD-003',
    gigTitle: 'Canva Poster Design',
    buyerName: 'Maryam Bibi',
    sellerName: 'Sara Malik',
    amount: 1000,
    status: 'completed',
    orderDate: DateTime.now().subtract(const Duration(days: 5)),
    deliveryDate: DateTime.now().subtract(const Duration(days: 3)),
  ),
  OrderModel(
    id: 'ORD-004',
    gigTitle: 'Assignment Formatting',
    buyerName: 'Ali Hamza',
    sellerName: 'Fatima Ali',
    amount: 800,
    status: 'pending',
    orderDate: DateTime.now(),
    deliveryDate: DateTime.now().add(const Duration(days: 1)),
  ),
];
