import 'package:flutter/material.dart';
import '../models/maintenance_record.dart';
import '../models/service_reminder.dart';
import '../models/vehicle.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../widgets/custom_card.dart';
import '../widgets/reminder_card.dart';
import '../widgets/service_record_tile.dart';
import '../widgets/stat_card.dart';
import '../widgets/update_odometer_dialog.dart';
import '../widgets/vehicle_selector_card.dart';
import 'add_edit_service_screen.dart';
import 'add_fuel_screen.dart';
import 'service_detail_screen.dart';

class DashboardScreen extends StatelessWidget {
  final Vehicle? activeVehicle;
  final List<Vehicle> allVehicles;
  final List<MaintenanceRecord> recentRecords;
  final List<ServiceReminder> activeReminders;
  final List<ServiceReminder> dueReminders;
  final double totalCostThisMonth;
  final Function(String vehicleId) onVehicleChanged;
  final Function(int newOdometer) onOdometerUpdated;
  final VoidCallback onAddVehicle;
  final Function(MaintenanceRecord record, {bool createNextReminder, int? intervalKm, int? intervalMonths}) onAddService;
  final Function(MaintenanceRecord record) onUpdateService;
  final Function(String id) onDeleteService;
  final Function(String reminderId, {MaintenanceRecord? newServiceRecord}) onCompleteReminder;
  final VoidCallback onNavigateToServices;
  final VoidCallback onNavigateToReminders;
  final VoidCallback onNavigateToFuel;

  const DashboardScreen({
    super.key,
    required this.activeVehicle,
    required this.allVehicles,
    required this.recentRecords,
    required this.activeReminders,
    required this.dueReminders,
    required this.totalCostThisMonth,
    required this.onVehicleChanged,
    required this.onOdometerUpdated,
    required this.onAddVehicle,
    required this.onAddService,
    required this.onUpdateService,
    required this.onDeleteService,
    required this.onCompleteReminder,
    required this.onNavigateToServices,
    required this.onNavigateToReminders,
    required this.onNavigateToFuel,
  });

  Future<void> _showAddServiceModal(BuildContext context) async {
    if (activeVehicle == null) return;

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditServiceScreen(vehicle: activeVehicle!),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      onAddService(
        result['record'] as MaintenanceRecord,
        createNextReminder: result['createNextReminder'] as bool? ?? false,
        intervalKm: result['intervalKm'] as int?,
        intervalMonths: result['intervalMonths'] as int?,
      );
    }
  }

  Future<void> _showAddFuelModal(BuildContext context) async {
    if (activeVehicle == null) return;

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddFuelScreen(vehicle: activeVehicle!),
      ),
    );

    if (result != null) {
      onNavigateToFuel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final curOdo = activeVehicle?.currentOdometer ?? 0;
    final lastRecord =
        recentRecords.isNotEmpty ? recentRecords.first : null;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.directions_car,
                color: Color(0xFF0D9488),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AutoLog',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                Text(
                  'Catatan Servis & Perawatan',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Instant refresh
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Active Vehicle Card
            VehicleSelectorCard(
              vehicle: activeVehicle,
              allVehicles: allVehicles,
              onVehicleChanged: onVehicleChanged,
              onOdometerUpdated: onOdometerUpdated,
              onAddVehicle: onAddVehicle,
            ),

            if (activeVehicle != null) ...[
              const SizedBox(height: 16),

              // Attention / Alert Banner if there are due reminders
              if (dueReminders.isNotEmpty) ...[
                _buildAttentionBanner(context, dueReminders.first, curOdo),
                const SizedBox(height: 16),
              ],

              // Quick Action Buttons
              _buildQuickActions(context),

              const SizedBox(height: 16),

              // Stat Summary Cards
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Biaya Bulan Ini',
                      value: CurrencyFormatter.formatCompact(totalCostThisMonth),
                      subtitle: 'Servis & Perawatan',
                      icon: Icons.receipt_long,
                      iconColor: const Color(0xFF0D9488),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Servis Terakhir',
                      value: lastRecord != null
                          ? '${CurrencyFormatter.formatNumber(lastRecord.odometer)} KM'
                          : '-',
                      subtitle: lastRecord != null
                          ? DateFormatter.formatRelative(lastRecord.date)
                          : 'Belum ada servis',
                      icon: Icons.history,
                      iconColor: const Color(0xFF3B82F6),
                      onTap: onNavigateToServices,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Upcoming Reminders Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Jadwal Servis Terdekat',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: onNavigateToReminders,
                    child: const Text('Lihat Semua'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (activeReminders.isEmpty)
                CustomCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline,
                          color: Color(0xFF10B981), size: 28),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Semua Jadwal Terpenuhi',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'Tidak ada jadwal servis yang perlu ditangani saat ini.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: onNavigateToReminders,
                        child: const Text('Tambah'),
                      ),
                    ],
                  ),
                )
              else
                ...activeReminders.take(2).map((rem) {
                  return ReminderCard(
                    reminder: rem,
                    currentOdometer: curOdo,
                    onServiceNow: () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AddEditServiceScreen(
                            vehicle: activeVehicle!,
                            initialCategoryKey: rem.categoryKey,
                          ),
                        ),
                      );
                      if (result != null && result is Map<String, dynamic>) {
                        onCompleteReminder(
                          rem.id,
                          newServiceRecord:
                              result['record'] as MaintenanceRecord,
                        );
                      }
                    },
                  );
                }),

              const SizedBox(height: 20),

              // Recent Service Records Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Riwayat Servis Terkini',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: onNavigateToServices,
                    child: const Text('Lihat Semua'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (recentRecords.isEmpty)
                CustomCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.build_circle_outlined,
                          color: Color(0xFF0D9488), size: 28),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Belum Ada Catatan Servis',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'Catat servis pertama Anda untuk mulai memantau.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _showAddServiceModal(context),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                        child: const Text('Catat'),
                      ),
                    ],
                  ),
                )
              else
                ...recentRecords.take(3).map((record) {
                  return ServiceRecordTile(
                    record: record,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ServiceDetailScreen(
                            record: record,
                            vehicle: activeVehicle!,
                            onUpdate: onUpdateService,
                            onDelete: () => onDeleteService(record.id),
                          ),
                        ),
                      );
                    },
                  );
                }),
            ],

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildAttentionBanner(
      BuildContext context, ServiceReminder rem, int currentOdometer) {
    final status = rem.getStatus(currentOdometer);
    final remainingKm = rem.getRemainingKm(currentOdometer);
    final isOverdue = status == ReminderStatus.terlewat;
    final color = isOverdue ? const Color(0xFFEF4444) : const Color(0xFFF59E0B);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.priority_high, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOverdue ? 'Jadwal Servis Terlewat!' : 'Perlu Servis Segera!',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${rem.title} (${remainingKm != null && remainingKm < 0 ? 'Terlewat ${remainingKm.abs()} KM' : 'Sisa ${remainingKm ?? 0} KM'})',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              visualDensity: VisualDensity.compact,
            ),
            onPressed: onNavigateToReminders,
            child: const Text('Cek', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            context,
            icon: Icons.build_circle,
            label: 'Catat Servis',
            color: const Color(0xFF0D9488),
            onTap: () => _showAddServiceModal(context),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionButton(
            context,
            icon: Icons.local_gas_station,
            label: 'Isi BBM',
            color: const Color(0xFF3B82F6),
            onTap: () => _showAddFuelModal(context),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionButton(
            context,
            icon: Icons.alarm,
            label: 'Jadwal',
            color: const Color(0xFF8B5CF6),
            onTap: onNavigateToReminders,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionButton(
            context,
            icon: Icons.edit_road,
            label: 'Update KM',
            color: const Color(0xFFF59E0B),
            onTap: () {
              if (activeVehicle != null) {
                UpdateOdometerDialog.show(
                  context,
                  vehicle: activeVehicle!,
                  onSaved: onOdometerUpdated,
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return CustomCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

