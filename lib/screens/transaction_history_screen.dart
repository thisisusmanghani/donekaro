import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/app_state.dart';

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Transaction History'),
      ),
      body: Consumer<AppState>(
        builder: (context, appState, _) {
          final transactions = appState.transactions;

          if (transactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 70, color: AppColors.textHint.withAlpha(100)),
                  const SizedBox(height: 16),
                  const Text(
                    'No Transactions Yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your earnings and payments will appear here',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            );
          }

          // Group by month
          final grouped = <String, List<TransactionItem>>{};
          for (final tx in transactions) {
            final key =
                '${_monthName(tx.date.month)} ${tx.date.year}';
            grouped.putIfAbsent(key, () => []).add(tx);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary card
              _buildSummaryCard(appState),
              const SizedBox(height: 20),

              // Transaction list grouped by month
              ...grouped.entries.expand((entry) => [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12, top: 4),
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    ...entry.value.map((tx) => _buildTransactionCard(tx)),
                  ]),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(AppState appState) {
    double totalEarned = 0;
    double totalSpent = 0;
    for (final tx in appState.transactions) {
      if (tx.type == 'earning') totalEarned += tx.amount;
      if (tx.type == 'payment') totalSpent += tx.amount;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Wallet Balance',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Rs. ${appState.walletBalance.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _buildSummaryItem(
                'Total Earned',
                'Rs. ${totalEarned.toStringAsFixed(0)}',
                Icons.arrow_downward,
                Colors.greenAccent,
              ),
              const SizedBox(width: 20),
              _buildSummaryItem(
                'Total Spent',
                'Rs. ${totalSpent.toStringAsFixed(0)}',
                Icons.arrow_upward,
                Colors.redAccent.shade100,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withAlpha(40),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white60,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(TransactionItem tx) {
    IconData icon;
    Color color;
    String prefix;
    switch (tx.type) {
      case 'earning':
        icon = Icons.arrow_downward;
        color = AppColors.success;
        prefix = '+';
        break;
      case 'payment':
        icon = Icons.arrow_upward;
        color = AppColors.error;
        prefix = '-';
        break;
      case 'withdrawal':
        icon = Icons.account_balance_outlined;
        color = AppColors.warning;
        prefix = '-';
        break;
      default:
        icon = Icons.swap_horiz;
        color = AppColors.textHint;
        prefix = '';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  tx.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$prefix Rs. ${tx.amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${tx.date.day}/${tx.date.month}/${tx.date.year}',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const names = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return names[month];
  }
}
