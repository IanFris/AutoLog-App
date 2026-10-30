import 'package:flutter/material.dart';
import '../providers/autolog_provider.dart';
import '../models/vehicle.dart';
import '../models/maintenance_record.dart';
import '../widgets/update_odometer_dialog.dart';
import 'dashboard_screen.dart';
import 'service_history_screen.dart';
import 'reminder_list_screen.dart';
import 'statistics_screen.dart';
import 'fuel_history_screen.dart';
import 'garage_screen.dart';
import 'add_edit_service_screen.dart';
import 'add_fuel_screen.dart';
import 'add_edit_vehicle_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final AutoLogProvider provider;

  const MainNavigationScreen({super.key, required this.provider});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  int _analyticsSubTab = 0; // 0: Statistik Servis, 1: BBM

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
  }

  void _showQuickActionSheet(BuildContext context) {
    final v = widget.provider.activeVehicle;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tindakan Cepat',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (v != null) ...[
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.build_circle,
                        color: Color(0xFF0D9488)),
                  ),
                  title: const Text('Catat Pemeliharaan / Servis'),
                  subtitle: Text('Untuk ${v.name}'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _navigateToAddService(context);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.local_gas_station,
                        color: Color(0xFF3B82F6)),
                  ),
                  title: const Text('Catat Pengisian BBM'),
                  subtitle: const Text('Hitung konsumsi & biaya bensin'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _navigateToAddFuel(context);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.speed, color: Color(0xFFF59E0B)),
                  ),
                  title: const Text('Perbarui Odometer (KM)'),
                  subtitle: Text('KM saat ini: ${v.currentOdometer} KM'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    UpdateOdometerDialog.show(
                      context,
                      vehicle: v,
                      onSaved: (newOdo) =>
                          widget.provider.updateOdometer(v.id, newOdo),
                    );
                  },
                ),
              ],
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add_circle, color: Color(0xFF8B5CF6)),
                ),
                title: const Text('Tambah Kendaraan Baru'),
                subtitle: const Text('Daftarkan motor atau mobil baru'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _navigateToAddVehicle(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToAddService(BuildContext context) async {
    final v = widget.provider.activeVehicle;
    if (v == null) return;

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditServiceScreen(vehicle: v),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      widget.provider.addMaintenanceRecord(
        result['record'] as MaintenanceRecord,
        createNextReminder: result['createNextReminder'] as bool? ?? false,
        intervalKm: result['intervalKm'] as int?,
        intervalMonths: result['intervalMonths'] as int?,
      );
    }
  }

  Future<void> _navigateToAddFuel(BuildContext context) async {
    final v = widget.provider.activeVehicle;
    if (v == null) return;

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddFuelScreen(vehicle: v),
      ),
    );

    if (result != null) {
      widget.provider.addFuelRecord(result);
      setState(() {
        _currentIndex = 3;
        _analyticsSubTab = 1;
      });
    }
  }

  Future<void> _navigateToAddVehicle(BuildContext context) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AddEditVehicleScreen(),
      ),
    );

    if (result != null && result is Vehicle) {
      widget.provider.addVehicle(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.provider,
      builder: (context, _) {
        final p = widget.provider;

        final pages = [
          // 0: Dashboard
          DashboardScreen(
            activeVehicle: p.activeVehicle,
            allVehicles: p.vehicles,
            recentRecords: p.activeVehicleRecords,
            activeReminders: p.activeVehicleReminders,
            dueReminders: p.activeVehicleDueReminders,
            totalCostThisMonth: p.totalMaintenanceCostThisMonth,
            onVehicleChanged: p.setActiveVehicle,
            onOdometerUpdated: (newOdo) {
              if (p.activeVehicle != null) {
                p.updateOdometer(p.activeVehicle!.id, newOdo);
              }
            },
            onAddVehicle: () => _navigateToAddVehicle(context),
            onAddService: (rec,
                {createNextReminder = false, intervalKm, intervalMonths}) {
              p.addMaintenanceRecord(
                rec,
                createNextReminder: createNextReminder,
                intervalKm: intervalKm,
                intervalMonths: intervalMonths,
              );
            },
            onUpdateService: p.updateMaintenanceRecord,
            onDeleteService: p.deleteMaintenanceRecord,
            onCompleteReminder: p.completeReminder,
            onNavigateToServices: () => _onTabSelected(1),
            onNavigateToReminders: () => _onTabSelected(2),
            onNavigateToFuel: () {
              setState(() {
                _currentIndex = 3;
                _analyticsSubTab = 1;
              });
            },
          ),

          // 1: Service History
          ServiceHistoryScreen(
            vehicle: p.activeVehicle,
            records: p.activeVehicleRecords,
            onAdd: (rec,
                {createNextReminder = false, intervalKm, intervalMonths}) {
              p.addMaintenanceRecord(
                rec,
                createNextReminder: createNextReminder,
                intervalKm: intervalKm,
                intervalMonths: intervalMonths,
              );
            },
            onUpdate: p.updateMaintenanceRecord,
            onDelete: p.deleteMaintenanceRecord,
          ),

          // 2: Reminders & Schedule
          ReminderListScreen(
            vehicle: p.activeVehicle,
            reminders: p.activeVehicleReminders,
            onAdd: p.addReminder,
            onDelete: p.deleteReminder,
            onComplete: p.completeReminder,
          ),

          // 3: Statistics & BBM
          _buildAnalyticsContainer(p),

          // 4: Garage
          GarageScreen(
            vehicles: p.vehicles,
            activeVehicle: p.activeVehicle,
            isDarkMode: p.isDarkMode,
            onSelectActive: p.setActiveVehicle,
            onAdd: p.addVehicle,
            onUpdate: p.updateVehicle,
            onDelete: p.deleteVehicle,
            onUpdateOdometer: p.updateOdometer,
            onToggleTheme: p.toggleDarkMode,
            onResetDemoData: p.resetToMockData,
            onClearAllData: p.clearAllData,
            onExportData: p.exportBackup,
            onImportData: p.importBackup,
          ),
        ];

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: pages,
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: _onTabSelected,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.speed_outlined),
                selectedIcon: Icon(Icons.speed),
                label: 'Beranda',
              ),
              const NavigationDestination(
                icon: Icon(Icons.build_outlined),
                selectedIcon: Icon(Icons.build),
                label: 'Servis',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: p.activeVehicleDueReminders.isNotEmpty,
                  label: Text('${p.activeVehicleDueReminders.length}'),
                  backgroundColor: const Color(0xFFEF4444),
                  child: const Icon(Icons.alarm_outlined),
                ),
                selectedIcon: Badge(
                  isLabelVisible: p.activeVehicleDueReminders.isNotEmpty,
                  label: Text('${p.activeVehicleDueReminders.length}'),
                  backgroundColor: const Color(0xFFEF4444),
                  child: const Icon(Icons.alarm),
                ),
                label: 'Pengingat',
              ),
              const NavigationDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart),
                label: 'Statistik',
              ),
              const NavigationDestination(
                icon: Icon(Icons.garage_outlined),
                selectedIcon: Icon(Icons.garage),
                label: 'Garasi',
              ),
            ],
          ),
          floatingActionButton: _currentIndex == 0
              ? FloatingActionButton(
                  onPressed: () => _showQuickActionSheet(context),
                  tooltip: 'Tindakan Cepat',
                  child: const Icon(Icons.add),
                )
              : null,
        );
      },
    );
  }

  Widget _buildAnalyticsContainer(AutoLogProvider p) {
    return Column(
      children: [
        // Sub-Tab Switcher
        Container(
          color: Theme.of(context).cardColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _analyticsSubTab = 0),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _analyticsSubTab == 0
                          ? const Color(0xFF0D9488).withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _analyticsSubTab == 0
                            ? const Color(0xFF0D9488)
                            : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Text(
                      'Statistik Servis',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: _analyticsSubTab == 0
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: _analyticsSubTab == 0
                            ? const Color(0xFF0D9488)
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _analyticsSubTab = 1),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _analyticsSubTab == 1
                          ? const Color(0xFF0D9488).withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _analyticsSubTab == 1
                            ? const Color(0xFF0D9488)
                            : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Text(
                      'Catatan BBM (${p.activeVehicleFuel.length})',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: _analyticsSubTab == 1
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: _analyticsSubTab == 1
                            ? const Color(0xFF0D9488)
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Sub-Tab Content
        Expanded(
          child: _analyticsSubTab == 0
              ? StatisticsScreen(
                  vehicle: p.activeVehicle,
                  totalMaintenanceCost: p.totalMaintenanceCostAllTime,
                  totalMaintenanceThisMonth: p.totalMaintenanceCostThisMonth,
                  totalMaintenanceThisYear: p.totalMaintenanceCostThisYear,
                  totalFuelCost: p.totalFuelCostAllTime,
                  averageFuelEfficiency: p.averageFuelEfficiency,
                  categoryCostBreakdown: p.categoryCostBreakdown,
                  monthlyTrends: p.monthlyExpenseTrends,
                  totalServiceCount: p.activeVehicleRecords.length,
                )
              : FuelHistoryScreen(
                  vehicle: p.activeVehicle,
                  fuelRecords: p.activeVehicleFuel,
                  averageEfficiency: p.averageFuelEfficiency,
                  onAdd: p.addFuelRecord,
                  onDelete: p.deleteFuelRecord,
                ),
        ),
      ],
    );
  }
}

