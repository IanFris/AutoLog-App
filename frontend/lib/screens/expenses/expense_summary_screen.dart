import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../providers/service_provider.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/stat_card.dart';

class ExpenseSummaryScreen extends StatelessWidget {
  const ExpenseSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vp = context.watch<VehicleProvider>();
    final sp = context.watch<ServiceProvider>();
    final auth = context.read<AuthProvider>();
    final vehicle = vp.activeVehicle;
    final exp = sp.expenses;

    if (vehicle == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rekap Pengeluaran')),
        body: const EmptyStateWidget(
          icon: Icons.bar_chart,
          title: 'Belum Ada Kendaraan',
          subtitle:
              'Pilih kendaraan untuk melihat statistik biaya pengeluaran pemeliharaan.',
        ),
      );
    }

    if (sp.isLoading && exp == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final totalAll = exp?.totalAllTime ?? 0.0;
    final totalMonth = exp?.totalThisMonth ?? 0.0;
    final totalYear = exp?.totalThisYear ?? 0.0;
    final costPerKm = exp?.costPerKm ?? 0.0;
    final categories = exp?.categoryBreakdown ?? [];
    final trends = exp?.monthlyTrends ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekapitulasi Biaya Servis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFEF4444)),
            tooltip: auth.isGuest ? 'Keluar dari mode tamu' : 'Logout',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(auth.isGuest
                      ? 'Keluar dari mode tamu?'
                      : 'Konfirmasi Logout'),
                  content: Text(auth.isGuest
                      ? 'Data tamu tetap tersimpan di perangkat ini dan dapat dibuka kembali nanti.'
                      : 'Apakah Anda yakin ingin keluar dari akun?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Batal')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444)),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        context.read<VehicleProvider>().reset();
                        context.read<ServiceProvider>().reset();
                        auth.logout();
                      },
                      child: Text(auth.isGuest ? 'Keluar' : 'Logout'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Total Spending Gradient Card
          CustomCard(
            padding: const EdgeInsets.all(20),
            borderRadius: 24,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF128E82),
                Color(0xFF0B625D),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL BIAYA PEMELIHARAAN',
                      style: TextStyle(
                        fontSize: 10,
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
                        vehicle.licensePlate,
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
                  CurrencyFormatter.format(totalAll),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${vehicle.brandModel} • Total ${exp?.serviceCount ?? 0} Kali Servis',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 2x2 Metric Cards
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Bulan Ini',
                  value: CurrencyFormatter.formatCompact(totalMonth),
                  subtitle: 'Biaya Servis',
                  icon: Icons.calendar_month,
                  iconColor: const Color(0xFF0D9488),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Tahun Ini',
                  value: CurrencyFormatter.formatCompact(totalYear),
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
                  subtitle: 'Perawatan per KM',
                  icon: Icons.speed,
                  iconColor: const Color(0xFF8B5CF6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Total Servis',
                  value: '${exp?.serviceCount ?? 0} Kali',
                  subtitle: 'Tercatat',
                  icon: Icons.build,
                  iconColor: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Monthly Trend Card
          if (trends.isNotEmpty) ...[
            CustomCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tren Pengeluaran 6 Bulan Terakhir',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 120,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: trends.map((t) {
                        final maxVal = trends.fold(
                            0.0, (m, v) => v.totalCost > m ? v.totalCost : m);
                        final heightFactor = maxVal > 0
                            ? (t.totalCost / maxVal).clamp(0.08, 1.0)
                            : 0.08;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (t.totalCost > 0)
                                  Text(
                                    CurrencyFormatter.formatCompact(
                                        t.totalCost),
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0D9488),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                const SizedBox(height: 4),
                                Container(
                                  height: 70 * heightFactor,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0D9488),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  t.monthLabel.split(' ').first,
                                  style: const TextStyle(
                                      fontSize: 10, color: Color(0xFF94A3B8)),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Category Breakdown Card
          CustomCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rincian Biaya per Komponen Servis',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 14),
                if (categories.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'Belum ada data transaksi pengeluaran.',
                        style:
                            TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      ),
                    ),
                  )
                else
                  ...categories.map((c) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                c.name,
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                '${CurrencyFormatter.format(c.cost)} (${c.percentage.toStringAsFixed(0)}%)',
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
                              value: (c.percentage / 100).clamp(0.0, 1.0),
                              minHeight: 8,
                              backgroundColor: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF0D9488)),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
