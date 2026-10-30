import 'package:flutter/material.dart';
import '../models/fuel_record.dart';
import '../models/vehicle.dart';
import '../utils/date_formatter.dart';

class AddFuelScreen extends StatefulWidget {
  final Vehicle vehicle;

  const AddFuelScreen({super.key, required this.vehicle});

  @override
  State<AddFuelScreen> createState() => _AddFuelScreenState();
}

class _AddFuelScreenState extends State<AddFuelScreen> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _selectedDate;
  late final TextEditingController _odometerController;
  late final TextEditingController _litersController;
  late final TextEditingController _pricePerLiterController;
  late final TextEditingController _totalCostController;
  late final TextEditingController _fuelTypeController;
  late final TextEditingController _gasStationController;
  late final TextEditingController _notesController;
  bool _isFullTank = true;

  final List<String> _fuelTypes = [
    'Pertamax',
    'Pertalite',
    'Pertamax Turbo',
    'Dexlite',
    'Solar',
    'Shell Super',
    'Shell V-Power',
    'BP 92',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _odometerController = TextEditingController(
      text: widget.vehicle.currentOdometer.toString(),
    );
    _litersController = TextEditingController();
    _pricePerLiterController = TextEditingController(text: '12950'); // standard Pertamax
    _totalCostController = TextEditingController();
    _fuelTypeController = TextEditingController(text: widget.vehicle.fuelType);
    _gasStationController =
        TextEditingController(text: 'SPBU Pertamina');
    _notesController = TextEditingController();

    _litersController.addListener(_recalcTotal);
    _pricePerLiterController.addListener(_recalcTotal);
  }

  @override
  void dispose() {
    _odometerController.dispose();
    _litersController.dispose();
    _pricePerLiterController.dispose();
    _totalCostController.dispose();
    _fuelTypeController.dispose();
    _gasStationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _recalcTotal() {
    final l = double.tryParse(_litersController.text.replaceAll(',', '.')) ?? 0;
    final p = double.tryParse(
            _pricePerLiterController.text.replaceAll('.', '').replaceAll(',', '.')) ??
        0;
    if (l > 0 && p > 0) {
      final total = (l * p).round();
      _totalCostController.text = total.toString();
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final odo = int.tryParse(
            _odometerController.text.replaceAll('.', '').trim()) ??
        widget.vehicle.currentOdometer;
    final liters =
        double.tryParse(_litersController.text.replaceAll(',', '.').trim()) ??
            0.0;
    final pricePerL = double.tryParse(
            _pricePerLiterController.text.replaceAll('.', '').trim()) ??
        0.0;
    final total = double.tryParse(
            _totalCostController.text.replaceAll('.', '').trim()) ??
        (liters * pricePerL);

    final record = FuelRecord(
      id: 'fr_${DateTime.now().millisecondsSinceEpoch}',
      vehicleId: widget.vehicle.id,
      date: _selectedDate,
      odometer: odo,
      liters: liters,
      pricePerLiter: pricePerL,
      totalCost: total,
      fuelType: _fuelTypeController.text.trim(),
      gasStation: _gasStationController.text.trim(),
      isFullTank: _isFullTank,
      notes: _notesController.text.trim(),
    );

    Navigator.of(context).pop(record);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catat Isi BBM'),
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
            // Vehicle badge
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(widget.vehicle.type.icon, color: const Color(0xFF0D9488)),
                  const SizedBox(width: 10),
                  Text(
                    '${widget.vehicle.name} (${widget.vehicle.licensePlate})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Date & Odometer
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Tanggal Pengisian *',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        DateFormatter.format(_selectedDate),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _odometerController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'KM Pengisian *',
                      suffixText: 'KM',
                      prefixIcon: Icon(Icons.speed),
                    ),
                    validator: (val) {
                      final k = int.tryParse(val?.replaceAll('.', '') ?? '');
                      if (k == null || k < 0) return 'Tidak valid';
                      return null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Fuel Type Dropdown
            DropdownButtonFormField<String>(
              initialValue: _fuelTypes.contains(_fuelTypeController.text)
                  ? _fuelTypeController.text
                  : _fuelTypes.first,
              decoration: const InputDecoration(
                labelText: 'Jenis BBM',
                prefixIcon: Icon(Icons.local_gas_station),
              ),
              items: _fuelTypes.map((f) {
                return DropdownMenuItem(value: f, child: Text(f));
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _fuelTypeController.text = val);
                }
              },
            ),

            const SizedBox(height: 16),

            // Liters & Price per liter
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _litersController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Jumlah Liter *',
                      hintText: '4.5',
                      suffixText: 'L',
                      prefixIcon: Icon(Icons.opacity),
                    ),
                    validator: (val) {
                      final l = double.tryParse(val?.replaceAll(',', '.') ?? '');
                      if (l == null || l <= 0) return 'Isi liter';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _pricePerLiterController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Harga / Liter (Rp)',
                      hintText: '12950',
                      prefixText: 'Rp ',
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Total Cost
            TextFormField(
              controller: _totalCostController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Total Biaya (Rp) *',
                hintText: '50000',
                prefixText: 'Rp ',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Wajib diisi';
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Gas Station
            TextFormField(
              controller: _gasStationController,
              decoration: const InputDecoration(
                labelText: 'Nama SPBU / Lokasi',
                hintText: 'Cth: SPBU Pertamina Cipinang',
                prefixIcon: Icon(Icons.place_outlined),
              ),
            ),

            const SizedBox(height: 16),

            // Full Tank Switch
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Isi Tangki Penuh (Full Tank)'),
              subtitle: const Text(
                'Digunakan untuk menghitung konsumsi BBM (KM/Liter)',
                style: TextStyle(fontSize: 12),
              ),
              value: _isFullTank,
              activeThumbColor: const Color(0xFF0D9488),
              onChanged: (val) => setState(() => _isFullTank = val),
            ),

            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Catatan (Opsional)',
                prefixIcon: Icon(Icons.notes),
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _save,
              child: const Text('Simpan Catatan BBM', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
