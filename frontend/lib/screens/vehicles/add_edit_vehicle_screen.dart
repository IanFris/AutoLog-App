import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/vehicle.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vehicle_provider.dart';

class AddEditVehicleScreen extends StatefulWidget {
  final Vehicle? vehicle;

  const AddEditVehicleScreen({super.key, this.vehicle});

  @override
  State<AddEditVehicleScreen> createState() => _AddEditVehicleScreenState();
}

class _AddEditVehicleScreenState extends State<AddEditVehicleScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _selectedType;
  late final TextEditingController _brandModelController;
  late final TextEditingController _plateController;
  late final TextEditingController _odometerController;

  final List<String> _popularBrands = [
    'Honda Vario 160', 'Yamaha NMAX 155', 'Honda Beat', 'Toyota Avanza', 'Honda HR-V', 'Mitsubishi Xpander'
  ];

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    _selectedType = v?.type == VehicleType.mobil ? 'mobil' : 'motor';
    _brandModelController = TextEditingController(text: v?.brandModel ?? '');
    _plateController = TextEditingController(text: v?.licensePlate ?? '');
    _odometerController = TextEditingController(
      text: v?.currentOdometer != null ? v!.currentOdometer.toString() : '0',
    );
  }

  @override
  void dispose() {
    _brandModelController.dispose();
    _plateController.dispose();
    _odometerController.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final vp = context.read<VehicleProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    final odometer = int.tryParse(
            _odometerController.text.replaceAll('.', '').trim()) ??
        0;

    final success = await vp.addVehicle(
      userId: user.id,
      type: _selectedType,
      brandModel: _brandModelController.text.trim(),
      licensePlate: _plateController.text.trim().toUpperCase(),
      currentOdometer: odometer,
    );

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kendaraan berhasil ditambahkan!')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vp.errorMessage ?? 'Gagal menyimpan kendaraan.'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vp = context.watch<VehicleProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Kendaraan'),
        actions: [
          TextButton(
            onPressed: vp.isLoading ? null : _save,
            child: const Text(
              'Simpan',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF0D9488),
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Vehicle Type Segmented Selector
            const Text(
              'Jenis Kendaraan',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTypeOption(
                    typeKey: 'motor',
                    label: 'Sepeda Motor',
                    icon: Icons.two_wheeler,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTypeOption(
                    typeKey: 'mobil',
                    label: 'Mobil',
                    icon: Icons.directions_car,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Brand & Model
            TextFormField(
              controller: _brandModelController,
              decoration: const InputDecoration(
                labelText: 'Merk & Model Kendaraan *',
                hintText: 'Misal: Honda Vario 160 ABS',
                prefixIcon: Icon(Icons.drive_file_rename_outline),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Merk & model wajib diisi';
                return null;
              },
            ),

            const SizedBox(height: 8),

            // Quick suggestion chips
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: _popularBrands.map((b) {
                return ActionChip(
                  label: Text(b, style: const TextStyle(fontSize: 11)),
                  onPressed: () => setState(() => _brandModelController.text = b),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // License Plate
            TextFormField(
              controller: _plateController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Nomor Polisi (Plat) *',
                hintText: 'B 1234 ABC',
                prefixIcon: Icon(Icons.credit_card),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Nomor polisi wajib diisi';
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Current Odometer
            TextFormField(
              controller: _odometerController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Kilometer Saat Ini (KM) *',
                hintText: '14500',
                suffixText: 'KM',
                prefixIcon: Icon(Icons.speed),
              ),
              validator: (val) {
                final k = int.tryParse(val?.replaceAll('.', '') ?? '');
                if (k == null || k < 0) return 'Masukkan angka KM yang valid';
                return null;
              },
            ),

            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: vp.isLoading ? null : _save,
              child: vp.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Simpan Kendaraan', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeOption({
    required String typeKey,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedType == typeKey;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => setState(() => _selectedType = typeKey),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0D9488).withValues(alpha: 0.12)
              : isDark
                  ? const Color(0xFF1E293B)
                  : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0D9488)
                : isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFCBD5E1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: isSelected ? const Color(0xFF0D9488) : const Color(0xFF64748B),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? const Color(0xFF0D9488) : null,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
