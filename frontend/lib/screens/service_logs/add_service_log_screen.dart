import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/vehicle.dart';
import '../../providers/service_provider.dart';
import '../../utils/date_formatter.dart';

class AddServiceLogScreen extends StatefulWidget {
  final Vehicle? vehicle;
  final int? initialServiceTypeId;

  const AddServiceLogScreen({
    super.key,
    required this.vehicle,
    this.initialServiceTypeId,
  });

  @override
  State<AddServiceLogScreen> createState() => _AddServiceLogScreenState();
}

class _AddServiceLogScreenState extends State<AddServiceLogScreen> {
  final _formKey = GlobalKey<FormState>();

  int? _selectedServiceTypeId;
  late DateTime _selectedDate;
  late final TextEditingController _odometerController;
  late final TextEditingController _costController;
  late final TextEditingController _workshopController;
  late final TextEditingController _notesController;

  XFile? _receiptPhoto;
  final ImagePicker _picker = ImagePicker();

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
    _selectedServiceTypeId = widget.initialServiceTypeId;
    _selectedDate = DateTime.now();
    _odometerController = TextEditingController(
      text: widget.vehicle?.currentOdometer.toString() ?? '0',
    );
    _costController = TextEditingController();
    _workshopController = TextEditingController(text: 'Bengkel Resmi');
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _odometerController.dispose();
    _costController.dispose();
    _workshopController.dispose();
    _notesController.dispose();
    super.dispose();
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() => _receiptPhoto = picked);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih foto: $e')),
        );
      }
    }
  }

  void _showImagePickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Unggah Foto Nota Servis',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF0D9488)),
                title: const Text('Ambil Foto Kamera'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF3B82F6)),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.vehicle == null) return;

    if (_selectedServiceTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih jenis servis.')),
      );
      return;
    }

    final sp = context.read<ServiceProvider>();
    final odo = int.tryParse(
            _odometerController.text.replaceAll('.', '').trim()) ??
        widget.vehicle!.currentOdometer;
    final cost =
        double.tryParse(_costController.text.replaceAll('.', '').trim()) ?? 0.0;
    final dateStr =
        "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";

    final success = await sp.addServiceLog(
      vehicleId: widget.vehicle!.id,
      serviceTypeId: _selectedServiceTypeId!,
      serviceDate: dateStr,
      odometerKm: odo,
      cost: cost,
      workshopName: _workshopController.text.trim(),
      notes: _notesController.text.trim(),
      receiptPhoto: _receiptPhoto,
    );

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Catatan servis berhasil disimpan ke server!')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sp.errorMessage ?? 'Gagal menyimpan servis.'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<ServiceProvider>();
    final types = sp.serviceTypes;

    if (_selectedServiceTypeId == null && types.isNotEmpty) {
      _selectedServiceTypeId = types.first.id;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catat Pemeliharaan Servis'),
        actions: [
          TextButton(
            onPressed: sp.isLoading ? null : _save,
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
            // Vehicle Badge
            if (widget.vehicle != null)
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
                    Icon(widget.vehicle!.type.icon, color: const Color(0xFF0D9488)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.vehicle!.brandModel,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            '${widget.vehicle!.licensePlate} • KM Saat Ini: ${widget.vehicle!.currentOdometer} KM',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Dropdown Jenis Servis
            DropdownButtonFormField<int>(
              initialValue: _selectedServiceTypeId,
              decoration: const InputDecoration(
                labelText: 'Jenis Pemeliharaan / Servis *',
                prefixIcon: Icon(Icons.category),
              ),
              items: types.map((t) {
                return DropdownMenuItem(
                  value: t.id,
                  child: Row(
                    children: [
                      Icon(t.iconData, size: 18, color: t.color),
                      const SizedBox(width: 10),
                      Text(t.name, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedServiceTypeId = val);
              },
            ),

            const SizedBox(height: 16),

            // Tanggal Servis & Odometer KM
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
                        style: const TextStyle(fontSize: 13),
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
                      if (k == null || k < 0) return 'KM tidak valid';
                      return null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Biaya Servis
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

            // Nama Bengkel
            TextFormField(
              controller: _workshopController,
              decoration: const InputDecoration(
                labelText: 'Tempat Bengkel *',
                hintText: 'AHASS, Planet Ban, dll',
                prefixIcon: Icon(Icons.storefront_outlined),
              ),
              validator: (val) =>
                  val == null || val.trim().isEmpty ? 'Nama bengkel wajib diisi' : null,
            ),

            const SizedBox(height: 8),

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

            // Catatan
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Catatan & Rekomendasi Mekanik',
                hintText: 'Misal: Ganti oli mesin full sintetis & stel rantai',
                prefixIcon: Icon(Icons.notes),
              ),
            ),

            const SizedBox(height: 20),

            // Upload Foto Nota
            const Text(
              'Foto Bukti / Nota Servis',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),

            if (_receiptPhoto != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF0D9488)),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: kIsWeb
                          ? Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.receipt),
                            )
                          : Image.file(
                              File(_receiptPhoto!.path),
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _receiptPhoto!.name,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Text(
                            'Foto siap diunggah ke Laragon',
                            style: TextStyle(fontSize: 11, color: Color(0xFF10B981)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Color(0xFFEF4444)),
                      onPressed: () => setState(() => _receiptPhoto = null),
                    ),
                  ],
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: _showImagePickerSheet,
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Ambil Foto / Pilih Gambar Nota'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),

            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: sp.isLoading ? null : _save,
              child: sp.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Simpan Catatan Servis', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
