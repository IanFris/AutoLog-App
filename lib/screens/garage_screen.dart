import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/vehicle.dart';
import '../utils/currency_formatter.dart';
import '../widgets/custom_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/update_odometer_dialog.dart';
import 'add_edit_vehicle_screen.dart';

class GarageScreen extends StatelessWidget {
  final List<Vehicle> vehicles;
  final Vehicle? activeVehicle;
  final bool isDarkMode;
  final Function(String vehicleId) onSelectActive;
  final Function(Vehicle vehicle) onAdd;
  final Function(Vehicle vehicle) onUpdate;
  final Function(String id) onDelete;
  final Function(String vehicleId, int newOdometer) onUpdateOdometer;
  final VoidCallback onToggleTheme;
  final VoidCallback onResetDemoData;
  final VoidCallback onClearAllData;
  final String Function() onExportData;
  final Future<bool> Function(String jsonStr) onImportData;

  const GarageScreen({
    super.key,
    required this.vehicles,
    required this.activeVehicle,
    required this.isDarkMode,
    required this.onSelectActive,
    required this.onAdd,
    required this.onUpdate,
    required this.onDelete,
    required this.onUpdateOdometer,
    required this.onToggleTheme,
    required this.onResetDemoData,
    required this.onClearAllData,
    required this.onExportData,
    required this.onImportData,
  });

  Future<void> _navigateToAddVehicle(BuildContext context) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AddEditVehicleScreen(),
      ),
    );

    if (result != null && result is Vehicle) {
      onAdd(result);
    }
  }

  Future<void> _navigateToEditVehicle(BuildContext context, Vehicle vehicle) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditVehicleScreen(vehicle: vehicle),
      ),
    );

    if (result != null && result is Vehicle) {
      onUpdate(result);
    }
  }

  void _confirmDeleteVehicle(BuildContext context, Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Hapus ${vehicle.name}?'),
        content: const Text(
          'Semua riwayat servis, catatan BBM, dan pengingat yang terkait dengan kendaraan ini akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              onDelete(vehicle.id);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    final jsonStr = onExportData();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Ekspor Cadangan Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Data kendaraan, riwayat servis, dan BBM berhasil diekspor sebagai JSON:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: SingleChildScrollView(
                child: Text(
                  jsonStr,
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tutup'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonStr));
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data JSON berhasil disalin ke clipboard!')),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Salin JSON'),
          ),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Pulihkan / Impor Cadangan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tempel data cadangan JSON AutoLog ke kolom berikut:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: '{\n  "vehicles": [...],\n  "maintenance": [...]\n}',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              final ok = await onImportData(text);
              if (context.mounted) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok
                        ? 'Data berhasil dipulihkan!'
                        : 'Format JSON tidak valid!'),
                  ),
                );
              }
            },
            child: const Text('Impor Data'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Garasi Kendaraan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Tambah Kendaraan',
            onPressed: () => _navigateToAddVehicle(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Vehicles Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Daftar Kendaraan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '${vehicles.length} Kendaraan',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (vehicles.isEmpty)
            EmptyStateWidget(
              icon: Icons.garage,
              title: 'Garasi Anda Kosong',
              subtitle: 'Tambahkan sepeda motor atau mobil Anda untuk memulai pencatatan.',
              buttonText: 'Tambah Kendaraan',
              onButtonPressed: () => _navigateToAddVehicle(context),
            )
          else
            ...vehicles.map((v) {
              final isActive = activeVehicle?.id == v.id;
              return CustomCard(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                border: isActive
                    ? Border.all(color: const Color(0xFF0D9488), width: 2)
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            v.type.icon,
                            color: const Color(0xFF0D9488),
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Title & Plate
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      v.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  if (isActive)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0D9488),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'Aktif',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      v.licensePlate,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${v.year} • ${v.fuelType}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 10),

                    // Odometer & Actions Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () {
                            UpdateOdometerDialog.show(
                              context,
                              vehicle: v,
                              onSaved: (newOdo) =>
                                  onUpdateOdometer(v.id, newOdo),
                            );
                          },
                          child: Row(
                            children: [
                              const Icon(Icons.speed,
                                  size: 16, color: Color(0xFF0D9488)),
                              const SizedBox(width: 6),
                              Text(
                                '${CurrencyFormatter.formatNumber(v.currentOdometer)} KM',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.edit,
                                  size: 12, color: Color(0xFF94A3B8)),
                            ],
                          ),
                        ),

                        Row(
                          children: [
                            if (!isActive)
                              TextButton(
                                onPressed: () => onSelectActive(v.id),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  visualDensity: VisualDensity.compact,
                                ),
                                child: const Text('Pilih Aktif'),
                              ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              tooltip: 'Ubah Data',
                              onPressed: () => _navigateToEditVehicle(context, v),
                              visualDensity: VisualDensity.compact,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 18, color: Color(0xFFEF4444)),
                              tooltip: 'Hapus',
                              onPressed: () => _confirmDeleteVehicle(context, v),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 24),

          // App Settings & Data Management
          const Text(
            'Pengaturan & Data',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          CustomCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(
                    isDarkMode ? Icons.dark_mode : Icons.light_mode,
                    color: const Color(0xFF0D9488),
                  ),
                  title: const Text('Mode Gelap (Dark Mode)'),
                  value: isDarkMode,
                  activeThumbColor: const Color(0xFF0D9488),
                  onChanged: (_) => onToggleTheme(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.cloud_upload_outlined,
                      color: Color(0xFF3B82F6)),
                  title: const Text('Ekspor Cadangan (JSON)'),
                  subtitle: const Text('Simpan salinan data AutoLog Anda'),
                  onTap: () => _showExportDialog(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.cloud_download_outlined,
                      color: Color(0xFF10B981)),
                  title: const Text('Impor Cadangan (JSON)'),
                  subtitle: const Text('Pulihkan data dari format JSON'),
                  onTap: () => _showImportDialog(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.replay, color: Color(0xFFF59E0B)),
                  title: const Text('Muat Data Demo / Contoh'),
                  subtitle: const Text(
                      'Isi data realistis Motor Vario 160 & Mobil Avanza'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Muat Data Contoh?'),
                        content: const Text(
                          'Data saat ini akan digantikan dengan data contoh realistis lengkap dengan servis, BBM, dan jadwal pengingat.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Batal'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              onResetDemoData();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Data contoh berhasil dimuat!')),
                              );
                            },
                            child: const Text('Muat Contoh'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_forever,
                      color: Color(0xFFEF4444)),
                  title: const Text('Hapus Semua Data'),
                  subtitle:
                      const Text('Kosongkan semua kendaraan dan riwayat'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Hapus Semua Data?'),
                        content: const Text(
                          'Semua kendaraan, catatan servis, BBM, dan pengingat akan dihapus bersih.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Batal'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
                            ),
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              onClearAllData();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Semua data telah dikosongkan.')),
                              );
                            },
                            child: const Text('Kosongkan'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // App Info
          const Center(
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.directions_car,
                        size: 16, color: Color(0xFF0D9488)),
                    SizedBox(width: 6),
                    Text(
                      'AutoLog v1.0.0',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  'Aplikasi Pencatatan Pemeliharaan Kendaraan Bermotor',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

