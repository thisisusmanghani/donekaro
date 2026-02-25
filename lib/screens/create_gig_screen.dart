import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/gig_model.dart';
import '../providers/app_state.dart';

class CreateGigScreen extends StatefulWidget {
  const CreateGigScreen({super.key});

  @override
  State<CreateGigScreen> createState() => _CreateGigScreenState();
}

class _CreateGigScreenState extends State<CreateGigScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  String _selectedCategory = 'Presentations';
  int _deliveryDays = 2;
  String _deliveryUnit = 'days';

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final price = double.tryParse(_priceController.text) ?? 0;
    final commission = price * 0.15;
    final earning = price - commission;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Create a Gig'),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text(
              'Preview',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Gig Title
            _buildSection(
              'Gig Title',
              'What service are you offering?',
              child: TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'e.g. I will design your PPT presentation',
                  filled: true,
                  fillColor: Colors.white,
                ),
                maxLength: 80,
              ),
            ),

            // Category
            _buildSection(
              'Category',
              'Choose the right category for your gig',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.divider),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    items: categories
                        .where((c) => c['name'] != 'All')
                        .map((c) {
                      return DropdownMenuItem(
                        value: c['name'] as String,
                        child: Row(
                          children: [
                            Text(c['icon'] as String),
                            const SizedBox(width: 10),
                            Text(c['name'] as String),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _selectedCategory = val!);
                    },
                  ),
                ),
              ),
            ),

            // Description
            _buildSection(
              'Description',
              'Describe your service in detail',
              child: TextField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText:
                      'Tell buyers what you will deliver, your process, what makes your service special...',
                  filled: true,
                  fillColor: Colors.white,
                ),
                maxLength: 500,
              ),
            ),

            // Delivery Time
            _buildSection(
              'Delivery Time',
              'Set the time you need to deliver',
              child: Column(
                children: [
                  // Hours / Days toggle
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _deliveryUnit = 'hours';
                              if (_deliveryDays > 72) _deliveryDays = 24;
                              if (_deliveryDays < 1) _deliveryDays = 1;
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _deliveryUnit == 'hours'
                                    ? AppColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Hours',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: _deliveryUnit == 'hours'
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _deliveryUnit = 'days';
                              if (_deliveryDays > 30) _deliveryDays = 14;
                              if (_deliveryDays < 1) _deliveryDays = 1;
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _deliveryUnit == 'days'
                                    ? AppColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Days',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: _deliveryUnit == 'days'
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Counter
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.access_time,
                                color: AppColors.primary),
                            const SizedBox(width: 12),
                            Text(
                              _deliveryUnit == 'hours'
                                  ? '$_deliveryDays ${_deliveryDays == 1 ? 'Hour' : 'Hours'}'
                                  : '$_deliveryDays ${_deliveryDays == 1 ? 'Day' : 'Days'}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            _buildCounterBtn(
                              Icons.remove,
                              () {
                                if (_deliveryDays > 1) {
                                  setState(() => _deliveryDays--);
                                }
                              },
                            ),
                            const SizedBox(width: 16),
                            _buildCounterBtn(
                              Icons.add,
                              () {
                                final max = _deliveryUnit == 'hours' ? 72 : 30;
                                if (_deliveryDays < max) {
                                  setState(() => _deliveryDays++);
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Price
            _buildSection(
              'Price (PKR)',
              'Set your service price',
              child: Column(
                children: [
                  TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'e.g. 1500',
                      prefixText: 'Rs. ',
                      prefixStyle: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontSize: 16,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (price > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.secondary.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildEarningRow(
                              'Service Price', 'Rs. ${price.toInt()}'),
                          const SizedBox(height: 8),
                          _buildEarningRow(
                              'Platform Fee (15%)', '- Rs. ${commission.toInt()}',
                              isRed: true),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Divider(color: AppColors.divider),
                          ),
                          _buildEarningRow(
                              'You\'ll Earn', 'Rs. ${earning.toInt()}',
                              isBold: true),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Publish button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final appState = context.read<AppState>();
                    final newGig = GigModel(
                      id: 'gig${DateTime.now().millisecondsSinceEpoch}',
                      title: _titleController.text.isNotEmpty
                          ? _titleController.text
                          : 'New Gig',
                      description: _descriptionController.text,
                      category: _selectedCategory,
                      price: price,
                      deliveryDays: _deliveryDays,
                      deliveryUnit: _deliveryUnit,
                      sellerName: appState.userName,
                      sellerAvatar: appState.userAvatar,
                      sellerDepartment: appState.userDepartment,
                      rating: 0.0,
                      reviewCount: 0,
                    );
                    appState.addGig(newGig);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            const Text('🎉 Gig published successfully!'),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.publish, color: Colors.white),
                  label: const Text('Publish Gig'),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String subtitle,
      {required Widget child}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildCounterBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
    );
  }

  Widget _buildEarningRow(String label, String value,
      {bool isBold = false, bool isRed = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 18 : 14,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: isRed
                ? AppColors.error
                : isBold
                    ? AppColors.secondary
                    : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
