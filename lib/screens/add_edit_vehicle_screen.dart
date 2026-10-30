import 'package:flutter/material.dart';
import '../models/vehicle.dart';

class AddEditVehicleScreen extends StatefulWidget {
  final Vehicle? vehicle;

  const AddEditVehicleScreen({super.key, this.vehicle});

  @override
  State<AddEditVehicleScreen> createState() => _AddEditVehicleScreenState();
}

class _AddEditVehicleScreenState extends State<AddEditVehicleScreen> {
  final _formKey = GlobalKey<FormState>();

  late VehicleType _selectedType;
  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late final TextEditingController _modelController;
  late final TextEditingController _yearController;
  late final TextEditingController _plateController;
  late final TextEditingController _odometerController;
  late final TextEditingController _fuelTypeController;
  late final TextEditingController _colorController;
  late final TextEditingController _notesController;

  final List<String> _popularBrands = [
    'Honda', 'Yamaha', 'Toyota', 'Suzuki', 'Daihatsu', 'Mitsubishi', 'Kawasaki', 'Vespa'
  ];

  final List<String> _fuelOptions = [
    'Pertamax', 'Pertalite', 'Pertamax Turbo', 'Dexlite', 'Solar', 'Listrik (EV)'
  ];

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    _selectedType = v?.type ?? VehicleType.motorcycle;
    _nameController = TextEditingController(text: v?.name ?? '');
    _brandController = TextEditingController(text: v?.brand ?? 'Honda');
    _modelController = TextEditingController(text: v?.model ?? '');
    _yearController = TextEditingController(
        text: v?.year != null ? v!.year.toString() : DateTime.now().year.toString());
    _plateController = TextEditingController(text: v?.licensePlate ?? '');
    _odometerController = TextEditingController(
        text: v?.currentOdometer != null ? v!.currentOdometer.toString() : '0');
    _fuelTypeController = TextEditingController(text: v?.fuelType ?? 'Pertamax');
    _colorController = TextEditingController(text: v?.color ?? 'Hitam');
    _notesController = TextEditingController(text: v?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _plateController.dispose();
    _odometerController.dispose();
    _fuelTypeController.dispose();
    _colorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final year = int.tryParse(_yearController.text.trim()) ?? DateTime.now().year;
    final odometer = int.tryParse(
            _odometerController.text.replaceAll('.', '').trim()) ??
        0;

    final vehicle = Vehicle(
      id: widget.vehicle?.id ??
          'v_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      type: _selectedType,
      brand: _brandController.text.trim(),
      model: _modelController.text.trim(),
      year: year,
      licensePlate: _plateController.text.trim().toUpperCase(),
      currentOdometer: odometer,
      fuelType: _fuelTypeController.text.trim(),
      color: _colorController.text.trim(),
      notes: _notesController.text.trim(),
      createdAt: widget.vehicle?.createdAt,
    );

    Navigator.of(context).pop(vehicle);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.vehicle != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Ubah Kendaraan' : 'Tambah Kendaraan'),
        actions: [
          TextButton(
            onPressed: _save,
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
                    type: VehicleType.motorcycle,
                    label: 'Sepeda Motor',
                    icon: Icons.two_wheeler,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTypeOption(
                    type: VehicleType.car,
                    label: 'Mobil',
                    icon: Icons.directions_car,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Vehicle Nickname / Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama / Panggilan Kendaraan *',
                hintText: 'Misal: Honda Vario 160 Hitam',
                prefixIcon: Icon(Icons.drive_file_rename_outline),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Nama kendaraan wajib diisi';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Brand & Model Row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _brandController,
                    decoration: const InputDecoration(
                      labelText: 'Merk *',
                      hintText: 'Honda, Toyota, dll',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Wajib diisi' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _modelController,
                    decoration: const InputDecoration(
                      labelText: 'Model / Tipe',
                      hintText: 'Vario 160 ABS',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Popular Brand Chips
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: _popularBrands.map((b) {
                return ActionChip(
                  label: Text(b, style: const TextStyle(fontSize: 11)),
                  onPressed: () => setState(() => _brandController.text = b),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // License Plate & Year
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _plateController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Nomor Polisi (Plat) *',
                      hintText: 'B 1234 ABC',
                      prefixIcon: Icon(Icons.credit_card),
                    ),
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Wajib diisi' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _yearController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Tahun *',
                      hintText: '2023',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    validator: (val) {
                      final y = int.tryParse(val ?? '');
                      if (y == null || y < 1970 || y > 2030) {
                        return 'Tahun tidak valid';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Current Odometer (KM)
            TextFormField(
              controller: _odometerController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Kilometer Saat Ini (KM) *',
                hintText: 'Misal: 14500',
                suffixText: 'KM',
                prefixIcon: Icon(Icons.speed),
              ),
              validator: (val) {
                final k = int.tryParse(val?.replaceAll('.', '') ?? '');
                if (k == null || k < 0) return 'Masukkan angka KM valid';
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Fuel Type & Color
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _fuelOptions.contains(_fuelTypeController.text)
                        ? _fuelTypeController.text
                        : _fuelOptions.first,
                    decoration: const InputDecoration(
                      labelText: 'Bahan Bakar',
                      prefixIcon: Icon(Icons.local_gas_station_outlined),
                    ),
                    items: _fuelOptions.map((f) {
                      return DropdownMenuItem(value: f, child: Text(f));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _fuelTypeController.text = val);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _colorController,
                    decoration: const InputDecoration(
                      labelText: 'Warna Kendaraan',
                      hintText: 'Hitam, Putih, dll',
                      prefixIcon: Icon(Icons.palette_outlined),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Catatan Tambahan (Opsional)',
                hintText: 'Misal: Asuransi All Risk s.d Des 2026',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),

            const SizedBox(height: 30),

            // Save Button
            ElevatedButton(
              onPressed: _save,
              child: Text(
                isEditing ? 'Perbarui Data Kendaraan' : 'Simpan Kendaraan',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeOption({
    required VehicleType type,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedType == type;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => setState(() => _selectedType = type),
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

