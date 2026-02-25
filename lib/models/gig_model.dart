class GigModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final double price;
  final String sellerName;
  final String sellerAvatar;
  final String sellerDepartment;
  final String sellerId;
  final double rating;
  final int reviewCount;
  final int deliveryDays;
  final String deliveryUnit; // 'days' or 'hours'
  final String imageUrl;

  GigModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.sellerName,
    required this.sellerAvatar,
    required this.sellerDepartment,
    this.sellerId = '',
    required this.rating,
    required this.reviewCount,
    required this.deliveryDays,
    this.deliveryUnit = 'days',
    this.imageUrl = '',
  });

  String get deliveryTimeText {
    if (deliveryUnit == 'hours') {
      return '$deliveryDays ${deliveryDays == 1 ? 'Hour' : 'Hours'}';
    }
    return '$deliveryDays ${deliveryDays == 1 ? 'Day' : 'Days'}';
  }

  String get deliveryTimeShort {
    return deliveryUnit == 'hours' ? '${deliveryDays}h' : '${deliveryDays}d';
  }
}

List<Map<String, dynamic>> categories = [
  {'name': 'All', 'icon': '🔥'},
  {'name': 'Presentations', 'icon': '📊'},
  {'name': 'Writing', 'icon': '✍️'},
  {'name': 'Coding', 'icon': '💻'},
  {'name': 'Design', 'icon': '🎨'},
  {'name': 'Typing', 'icon': '⌨️'},
  {'name': 'Data Entry', 'icon': '📋'},
  {'name': 'Translation', 'icon': '🌐'},
];
