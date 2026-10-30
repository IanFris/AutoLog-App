import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../utils/currency_formatter.dart';

class UpdateOdometerDialog extends StatefulWidget {
  final Vehicle vehicle;
  final Function(int newOdometer) onSaved;

  const UpdateOdometerDialog({
    super.key,
    required this.vehicle,
    required this.onSaved,
  });

  static Future<void> show(
    BuildContext context, {
    required Vehicle vehicle,
    required Function(int newOdometer) onSaved,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => UpdateOdometerDialog(
        vehicle: vehicle,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<UpdateOdometerDialog> createState() => _UpdateOdometerDialogState();
}

class _UpdateOdometerDialogState extends State<UpdateOdometerDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.vehicle.currentOdometer.toString(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final value = int.tryParse(_controller.text.replaceAll('.', '').trim());
    if (value == null) {
      setState(() => _errorText = 'Masukkan angka kilometer yang valid');
      return;
    }
    if (value < 0) {
      setState(() => _errorText = 'Kilometer tidak boleh negatif');
      return;
    }

    widget.onSaved(value);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0D9488).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.speed, color: Color(0xFF0D9488), size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Perbarui Odometer',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kendaraan: ${widget.vehicle.name}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          Text(
            'KM saat ini: ${CurrencyFormatter.formatNumber(widget.vehicle.currentOdometer)} KM',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Kilometer Baru (KM)',
              suffixText: 'KM',
              errorText: _errorText,
              prefixIcon: const Icon(Icons.edit_road),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tips: Perbarui KM secara berkala agar pengingat servis tetap akurat.',
            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

