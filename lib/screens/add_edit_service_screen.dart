import 'package:flutter/material.dart';
import '../models/maintenance_record.dart';
import '../models/vehicle.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';

class AddEditServiceScreen extends StatefulWidget {
  final Vehicle vehicle;
  final MaintenanceRecord? record;
  final String? initialCategoryKey;

  const AddEditServiceScreen({
    super.key,
    required this.vehicle,
    this.record,
    this.initialCategoryKey,
  });

  @override
  State<AddEditServiceScreen> createState() => _AddEditServiceScreenState();
}

class _AddEditServiceScreenState extends State<AddEditServiceScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _selectedCategoryKey;
  late DateTime _selectedDate;
  late final TextEditingController _titleController;
  late final TextEditingController _odometerController;
  late final TextEditingController _workshopController;
  late final TextEditingController _costController;
  late final TextEditingController _notesController;
  late final TextEditingController _partTagController;

  final List<String> _partsReplaced = [];

  // Next reminder options
  bool _enableNextReminder = true;
  late final TextEditingController _intervalKmController;
  late final TextEditingController _intervalMonthController;

  final List<String> _popularWorkshops = [
    'Bengkel Resmi AHASS',
    'Planet Ban',
    'Auto2000',
    'Shop & Drive',
    'Nawilis Ban',
    'Bengkel Mandiri',
  ];

  @override
  void initState() {
    super.initState();
    final r = widget.record;

    _selectedCategoryKey = r?.categoryKey ??
        widget.initialCategoryKey ??
        MaintenanceCategory.all.first.key;
    final cat = MaintenanceCategory.fromKey(_selectedCategoryKey);

    _selectedDate = r?.date ?? DateTime.now();
    _titleController =
        TextEditingController(text: r?.title ?? cat.label);
    _odometerController = TextEditingController(
      text: r?.odometer != null
          ? r!.odometer.toString()
          : widget.vehicle.currentOdometer.toString(),
    );
    _workshopController =
        TextEditingController(text: r?.workshopName ?? 'Bengkel Resmi');
    _costController = TextEditingController(
      text: r?.cost != null ? r!.cost.toInt().toString() : '',
    );
    _notesController = TextEditingController(text: r?.notes ?? '');
    _partTagController = TextEditingController();

    if (r != null) {
      _partsReplaced.addAll(r.partsReplaced);
      _enableNextReminder = false; // By default don't auto-create duplicate if editing
    }

    _intervalKmController = TextEditingController(
      text: cat.defaultKmInterval > 0 ? cat.defaultKmInterval.toString() : '3000',
    );
    _intervalMonthController = TextEditingController(
      text: cat.defaultMonthInterval.toString(),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _odometerController.dispose();
    _workshopController.dispose();
    _costController.dispose();
    _notesController.dispose();
    _partTagController.dispose();
    _intervalKmController.dispose();
    _intervalMonthController.dispose();
    super.dispose();
  }

  void _onCategoryChanged(String key) {
    setState(() {
      _selectedCategoryKey = key;
      final cat = MaintenanceCategory.fromKey(key);
      _titleController.text = cat.label;
      if (cat.defaultKmInterval > 0) {
        _intervalKmController.text = cat.defaultKmInterval.toString();
      }
      _intervalMonthController.text = cat.defaultMonthInterval.toString();
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _addPartTag() {
    final text = _partTagController.text.trim();
    if (text.isNotEmpty && !_partsReplaced.contains(text)) {
      setState(() {
        _partsReplaced.add(text);
        _partTagController.clear();
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final odometer = int.tryParse(
            _odometerController.text.replaceAll('.', '').trim()) ??
        widget.vehicle.currentOdometer;
    final cost =
        double.tryParse(_costController.text.replaceAll('.', '').trim()) ?? 0.0;
    final intervalKm = int.tryParse(_intervalKmController.text.trim());
    final intervalMonth = int.tryParse(_intervalMonthController.text.trim());

    DateTime? nextDate;
    int? nextOdo;

    if (_enableNextReminder) {
      if (intervalKm != null && intervalKm > 0) {
        nextOdo = odometer + intervalKm;
      }
      if (intervalMonth != null && intervalMonth > 0) {
        nextDate = DateTime(
          _selectedDate.year,
          _selectedDate.month + intervalMonth,
          _selectedDate.day,
        );
      }
    }

    final record = MaintenanceRecord(
      id: widget.record?.id ?? 'mr_${DateTime.now().millisecondsSinceEpoch}',
      vehicleId: widget.vehicle.id,
      date: _selectedDate,
      odometer: odometer,
      title: _titleController.text.trim(),
      categoryKey: _selectedCategoryKey,
      workshopName: _workshopController.text.trim(),
      cost: cost,
      notes: _notesController.text.trim(),
      partsReplaced: _partsReplaced,
      nextServiceDate: nextDate,
      nextServiceOdometer: nextOdo,
    );

    Navigator.of(context).pop({
      'record': record,
      'createNextReminder': _enableNextReminder && widget.record == null,
      'intervalKm': intervalKm,
      'intervalMonths': intervalMonth,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.record != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Ubah Catatan Servis' : 'Catat Pemeliharaan'),
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
            // Vehicle Info Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(widget.vehicle.type.icon, color: const Color(0xFF0D9488)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.vehicle.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          '${widget.vehicle.licensePlate} • KM Terakhir: ${CurrencyFormatter.formatNumber(widget.vehicle.currentOdometer)} KM',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Category Selection Dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedCategoryKey,
              decoration: const InputDecoration(
                labelText: 'Kategori Pemeliharaan *',
                prefixIcon: Icon(Icons.category),
              ),
              items: MaintenanceCategory.all.map((c) {
                return DropdownMenuItem(
                  value: c.key,
                  child: Row(
                    children: [
                      Icon(c.icon, size: 18, color: c.color),
                      const SizedBox(width: 10),
                      Text(c.label, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) _onCategoryChanged(val);
              },
            ),

            const SizedBox(height: 16),

            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Judul Servis / Pekerjaan *',
                hintText: 'Misal: Ganti Oli Mesin SPX2',
                prefixIcon: Icon(Icons.build_outlined),
              ),
              validator: (val) =>
                  val == null || val.trim().isEmpty ? 'Wajib diisi' : null,
            ),

            const SizedBox(height: 16),

            // Date & Odometer Row
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Tanggal Servis *',
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
                      labelText: 'KM Servis *',
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

            // Cost & Workshop
            TextFormField(
              controller: _costController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Total Biaya (Rp) *',
                hintText: '150000',
                prefixText: 'Rp ',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Biaya wajib diisi';
                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _workshopController,
              decoration: const InputDecoration(
                labelText: 'Nama Bengkel / Tempat Servis *',
                hintText: 'Misal: AHASS Cawang, Planet Ban',
                prefixIcon: Icon(Icons.storefront_outlined),
              ),
              validator: (val) =>
                  val == null || val.trim().isEmpty ? 'Nama bengkel wajib diisi' : null,
            ),

            const SizedBox(height: 8),

            // Popular Workshops Chips
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: _popularWorkshops.map((w) {
                return ActionChip(
                  label: Text(w, style: const TextStyle(fontSize: 11)),
                  onPressed: () => setState(() => _workshopController.text = w),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Parts Replaced Section
            const Text(
              'Suku Cadang / Part Yang Diganti',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _partTagController,
                    onSubmitted: (_) => _addPartTag(),
                    decoration: const InputDecoration(
                      hintText: 'Tambah part (cth: Oli SPX 2, Busi)',
                      prefixIcon: Icon(Icons.add_shopping_cart),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addPartTag,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  child: const Text('Tambah'),
                ),
              ],
            ),

            if (_partsReplaced.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _partsReplaced.map((part) {
                  return Chip(
                    label: Text(part, style: const TextStyle(fontSize: 12)),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      setState(() => _partsReplaced.remove(part));
                    },
                    backgroundColor: const Color(0xFF0D9488).withValues(alpha: 0.1),
                    side: BorderSide.none,
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Catatan & Rekomendasi Mekanik',
                hintText: 'Misal: Kondisi kampas rem belakang mulai tipis, perlu diganti 2000 KM lagi.',
                prefixIcon: Icon(Icons.notes),
              ),
            ),

            const SizedBox(height: 24),

            // Next Service Reminder Switch Card
            if (!isEditing) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1E293B)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _enableNextReminder
                        ? const Color(0xFF0D9488)
                        : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.alarm_on, color: Color(0xFF0D9488)),
                            SizedBox(width: 8),
                            Text(
                              'Pengingat Servis Berikutnya',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: _enableNextReminder,
                          activeThumbColor: const Color(0xFF0D9488),
                          onChanged: (val) =>
                              setState(() => _enableNextReminder = val),
                        ),
                      ],
                    ),
                    if (_enableNextReminder) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'AutoLog akan mengingatkan Anda saat KM atau tanggal servis berikutnya mendekati:',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _intervalKmController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Interval KM',
                                suffixText: 'KM',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _intervalMonthController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Interval Bulan',
                                suffixText: 'Bulan',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Submit Button
            ElevatedButton(
              onPressed: _save,
              child: Text(
                isEditing ? 'Simpan Perubahan' : 'Catat Pemeliharaan Sekarang',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

