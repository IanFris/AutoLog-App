import 'package:flutter/material.dart';
import '../utils/currency_formatter.dart';
import 'custom_card.dart';

class ExpenseChartWidget extends StatelessWidget {
  final Map<String, double> monthlyData;
  final Map<String, double> categoryData;

  const ExpenseChartWidget({
    super.key,
    required this.monthlyData,
    required this.categoryData,
  });

  @override
  Widget build(BuildContext context) {
    final totalSpent =
        categoryData.values.fold(0.0, (sum, val) => sum + val);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Monthly Bar Chart Card
        CustomCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tren Pengeluaran 6 Bulan Terakhir',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Perawatan',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0D9488),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildMonthlyBarChart(context),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Category Breakdown Card
        CustomCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rincian Biaya per Kategori',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              if (categoryData.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Belum ada data pengeluaran.',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    ),
                  ),
                )
              else
                ...categoryData.entries.map((entry) {
                  final percentage = totalSpent > 0 ? (entry.value / totalSpent) : 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${CurrencyFormatter.format(entry.value)} (${(percentage * 100).toStringAsFixed(0)}%)',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0D9488),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percentage,
                            minHeight: 8,
                            backgroundColor:
                                Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFE2E8F0),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF0D9488),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyBarChart(BuildContext context) {
    if (monthlyData.isEmpty) {
      return const SizedBox(
        height: 140,
        child: Center(
          child: Text(
            'Tidak ada data transaksi.',
            style: TextStyle(color: Color(0xFF94A3B8)),
          ),
        ),
      );
    }

    final maxVal = monthlyData.values.fold(0.0, (m, v) => v > m ? v : m);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: monthlyData.entries.map((e) {
          final heightFactor = maxVal > 0 ? (e.value / maxVal).clamp(0.06, 1.0) : 0.06;
          final isHighest = e.value > 0 && e.value == maxVal;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (e.value > 0)
                    Text(
                      CurrencyFormatter.formatCompact(e.value),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: isHighest ? const Color(0xFF0D9488) : const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    const SizedBox(height: 12),
                  const SizedBox(height: 4),
                  Container(
                    height: 80 * heightFactor,
                    decoration: BoxDecoration(
                      color: isHighest
                          ? const Color(0xFF0D9488)
                          : isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatMonthLabel(e.key),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatMonthLabel(String key) {
    // Format "10/2026" to "Okt"
    final parts = key.split('/');
    if (parts.length >= 2) {
      final month = int.tryParse(parts[0]) ?? 1;
      const monthNames = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      if (month >= 1 && month <= 12) {
        return monthNames[month - 1];
      }
    }
    return key;
  }
}

