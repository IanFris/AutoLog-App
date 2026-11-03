import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/component_reminder.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../providers/service_provider.dart';
import '../../widgets/component_status_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/vehicle_header_card.dart';
import '../vehicles/add_edit_vehicle_screen.dart';
import '../service_logs/add_service_log_screen.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onNavigateToLogs;
  final VoidCallback onNavigateToExpenses;

  const DashboardScreen({
    super.key,
    required this.onNavigateToLogs,
    required this.onNavigateToExpenses,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _selectedStatusFilter = 'all'; // all, merah, kuning, hijau

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _loadInitialData() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      final vp = context.read<VehicleProvider>();
      await vp.fetchVehicles(user.id);
      if (vp.activeVehicle != null && mounted) {
        context.read<ServiceProvider>().fetchVehicleData(vp.activeVehicle!.id);
      }
    }
  }

  Future<void> _refresh() async {
    final vp = context.read<VehicleProvider>();
    if (vp.activeVehicle != null) {
      await context
          .read<ServiceProvider>()
          .fetchVehicleData(vp.activeVehicle!.id);
    }
  }

  List<ComponentReminder> _getFilteredReminders(List<ComponentReminder> list) {
    if (_selectedStatusFilter == 'all') return list;
    if (_selectedStatusFilter == 'merah') {
      return list
          .where((r) => r.statusColor == ReminderColorStatus.merah)
          .toList();
    }
    if (_selectedStatusFilter == 'kuning') {
      return list
          .where((r) => r.statusColor == ReminderColorStatus.kuning)
          .toList();
    }
    if (_selectedStatusFilter == 'hijau') {
      return list
          .where((r) => r.statusColor == ReminderColorStatus.hijau)
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final vp = context.watch<VehicleProvider>();
    final sp = context.watch<ServiceProvider>();
    final isGuest = context.watch<AuthProvider>().isGuest;
    final activeVehicle = vp.activeVehicle;

    final allReminders = sp.reminders;
    final filteredReminders = _getFilteredReminders(allReminders);

    final redCount = allReminders
        .where((r) => r.statusColor == ReminderColorStatus.merah)
        .length;
    final yellowCount = allReminders
        .where((r) => r.statusColor == ReminderColorStatus.kuning)
        .length;
    final greenCount = allReminders
        .where((r) => r.statusColor == ReminderColorStatus.hijau)
        .length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F8B80).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.directions_car_rounded,
                  color: Color(0xFF0F8B80), size: 21),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Garasi kamu',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                Text(
                  'Semua kendaraan dalam satu tempat',
                  style: TextStyle(fontSize: 11, color: Color(0xFF72808C)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).cardColor,
            ),
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Tambah Kendaraan',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddEditVehicleScreen()),
              );
            },
          ),
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).cardColor,
            ),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Muat Ulang',
            onPressed: _refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Vehicle Header Card (with active vehicle switcher & update KM)
            VehicleHeaderCard(
              vehicle: activeVehicle,
              allVehicles: vp.vehicles,
              onVehicleChanged: (v) {
                vp.setActiveVehicle(v);
                sp.fetchVehicleData(v.id);
              },
              onOdometerUpdated: (newOdo) {
                vp.updateOdometer(newOdo);
                _refresh();
              },
              onAddVehicle: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const AddEditVehicleScreen()),
                );
              },
              onEditVehicle: activeVehicle != null
                  ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              AddEditVehicleScreen(vehicle: activeVehicle),
                        ),
                      );
                    }
                  : null,
              onDeleteVehicle: activeVehicle != null
                  ? () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Hapus kendaraan?'),
                          content: Text(
                            'Kendaraan ${activeVehicle.brandModel} (${activeVehicle.licensePlate}) akan dihapus permanen.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Batal'),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFFEF4444)),
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Hapus'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed != true) return;

                      final success = await vp.deleteVehicle(activeVehicle.id);
                      if (mounted && success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Kendaraan berhasil dihapus.')),
                        );
                      } else if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(vp.errorMessage ??
                                'Gagal menghapus kendaraan.'),
                            backgroundColor: const Color(0xFFEF4444),
                          ),
                        );
                      }
                    }
                  : null,
            ),

            if (isGuest) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F8B80).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.phone_android_rounded, color: Color(0xFF0F8B80)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Mode Tamu: data tersimpan di perangkat ini saja dan tidak dikirim ke cloud.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: Color(0xFF536A70),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (activeVehicle != null) ...[
              const SizedBox(height: 16),

              // Attention Banner if there are overdue or near components
              if (redCount > 0 || yellowCount > 0)
                _buildAttentionBanner(redCount, yellowCount),

              const SizedBox(height: 16),

              // Quick Action Buttons
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionBtn(
                      icon: Icons.build_circle,
                      label: 'Catat Servis',
                      color: const Color(0xFF0D9488),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                AddServiceLogScreen(vehicle: activeVehicle),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildQuickActionBtn(
                      icon: Icons.history,
                      label: 'Riwayat Servis',
                      color: const Color(0xFF3B82F6),
                      onTap: widget.onNavigateToLogs,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildQuickActionBtn(
                      icon: Icons.bar_chart,
                      label: 'Biaya Servis',
                      color: const Color(0xFF8B5CF6),
                      onTap: widget.onNavigateToExpenses,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Component Status Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Status komponen',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '${allReminders.length} Komponen',
                    style:
                        const TextStyle(fontSize: 12, color: Color(0xFF72808C)),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Color Status Filter Chips (Hijau, Kuning, Merah)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('all', 'Semua (${allReminders.length})'),
                    const SizedBox(width: 6),
                    _buildFilterChip('merah', 'Wajib Servis ($redCount)',
                        color: const Color(0xFFEF4444)),
                    const SizedBox(width: 6),
                    _buildFilterChip('kuning', 'Mendekati ($yellowCount)',
                        color: const Color(0xFFF59E0B)),
                    const SizedBox(width: 6),
                    _buildFilterChip('hijau', 'Aman ($greenCount)',
                        color: const Color(0xFF10B981)),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Component Reminders List
              if (sp.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (filteredReminders.isEmpty)
                EmptyStateWidget(
                  icon: Icons.check_circle_outline,
                  title: 'Tidak Ada Komponen Terdaftar',
                  subtitle:
                      'Semua komponen dalam kondisi baik atau filter saat ini kosong.',
                  buttonText: 'Catat Servis Baru',
                  onButtonPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            AddServiceLogScreen(vehicle: activeVehicle),
                      ),
                    );
                  },
                )
              else
                ...filteredReminders.map(
                  (rem) => ComponentStatusCard(
                    reminder: rem,
                    onServiceNow: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AddServiceLogScreen(
                            vehicle: activeVehicle,
                            initialServiceTypeId: rem.serviceTypeId,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildAttentionBanner(int redCount, int yellowCount) {
    final isCritical = redCount > 0;
    final color =
        isCritical ? const Color(0xFFEF4444) : const Color(0xFFF59E0B);
    final title = isCritical
        ? '$redCount Komponen Wajib Servis Segera!'
        : '$yellowCount Komponen Mendekati Batas Servis!';
    final subtitle = isCritical
        ? 'Kilometer atau tanggal servis telah melampaui batas yang dianjurkan.'
        : 'Disarankan untuk mempersiapkan jadwal servis dalam waktu dekat.';

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
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: const Icon(Icons.warning_amber_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style:
                      const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, {Color? color}) {
    final isSelected = _selectedStatusFilter == key;
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      selectedColor: (color ?? const Color(0xFF0D9488)).withValues(alpha: 0.2),
      checkmarkColor: color ?? const Color(0xFF0D9488),
      side: BorderSide(
        color: isSelected
            ? (color ?? const Color(0xFF0D9488))
            : const Color(0xFFCBD5E1),
      ),
      onSelected: (_) => setState(() => _selectedStatusFilter = key),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    );
  }

  Widget _buildQuickActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF293844)
                : const Color(0xFFE7ECEF),
          ),
          boxShadow: Theme.of(context).brightness == Brightness.dark
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFF172B3A).withValues(alpha: 0.035),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
