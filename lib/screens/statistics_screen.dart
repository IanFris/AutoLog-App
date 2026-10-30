import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../utils/currency_formatter.dart';
import '../widgets/custom_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/expense_chart.dart';
import '../widgets/stat_card.dart';

class StatisticsScreen extends StatelessWidget {
  final Vehicle? vehicle;
  final double totalMaintenanceCost;
  final double totalMaintenanceThisMonth;
  final double totalMaintenanceThisYear;
  final double totalFuelCost;
  final double averageFuelEfficiency;
  final Map<String, double> categoryCostBreakdown;
  final Map<String, double> monthlyTrends;
  final int totalServiceCount;

  const StatisticsScreen({
    super.key,
    required this.vehicle,
    required this.totalMaintenanceCost,
    required this.totalMaintenanceThisMonth,
    required this.totalMaintenanceThisYear,
    required this.totalFuelCost,
    required this.averageFuelEfficiency,
    required this.categoryCostBreakdown,
    required this.monthlyTrends,
    required this.totalServiceCount,
  });

  @override
  Widget build(BuildContext context) {
    if (vehicle == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Statistik & Pengeluaran')),
        body: const EmptyStateWidget(
          icon: Icons.bar_chart,
          title: 'Belum Ada Kendaraan',
          subtitle: 'Pilih atau tambahkan kendaraan untuk melihat ringkasan statistik biaya perawatan.',
        ),
      );
    }

    final grandTotal = totalMaintenanceCost + totalFuelCost;
    final costPerKm = vehicle!.currentOdometer > 0
        ? (totalMaintenanceCost / vehicle!.currentOdometer)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik Pengeluaran'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Total Spending Highlight Card
          CustomCard(
            padding: const EdgeInsets.all(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F766E),
                Color(0xFF134E4A),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL PENGELUARAN KENDARAAN',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        vehicle!.licensePlate,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  CurrencyFormatter.format(grandTotal),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Servis & Perawatan',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            CurrencyFormatter.formatCompact(totalMaintenanceCost),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bahan Bakar (BBM)',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            CurrencyFormatter.formatCompact(totalFuelCost),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 4-Grid Metric Cards
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Bulan Ini',
                  value: CurrencyFormatter.formatCompact(totalMaintenanceThisMonth),
                  subtitle: 'Biaya Servis',
                  icon: Icons.calendar_month,
                  iconColor: const Color(0xFF0D9488),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Tahun Ini',
                  value: CurrencyFormatter.formatCompact(totalMaintenanceThisYear),
                  subtitle: '${DateTime.now().year}',
                  icon: Icons.calendar_today,
                  iconColor: const Color(0xFF3B82F6),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Biaya / KM',
                  value: 'Rp ${costPerKm.toStringAsFixed(0)}',
                  subtitle: 'Perawatan/KM',
                  icon: Icons.speed,
                  iconColor: const Color(0xFF8B5CF6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Konsumsi BBM',
                  value: averageFuelEfficiency > 0
                      ? '${averageFuelEfficiency.toStringAsFixed(1)} KM/L'
                      : '-',
                  subtitle: 'Rata-rata',
                  icon: Icons.local_gas_station,
                  iconColor: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Charts
          ExpenseChartWidget(
            monthlyData: monthlyTrends,
            categoryData: categoryCostBreakdown,
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

