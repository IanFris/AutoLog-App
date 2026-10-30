import 'package:flutter/material.dart';
import '../models/maintenance_record.dart';
import '../models/service_reminder.dart';
import '../models/vehicle.dart';
import '../widgets/empty_state.dart';
import '../widgets/reminder_card.dart';
import 'add_edit_service_screen.dart';

class ReminderListScreen extends StatefulWidget {
  final Vehicle? vehicle;
  final List<ServiceReminder> reminders;
  final Function(ServiceReminder reminder) onAdd;
  final Function(String id) onDelete;
  final Function(String reminderId, {MaintenanceRecord? newServiceRecord}) onComplete;

  const ReminderListScreen({
    super.key,
    required this.vehicle,
    required this.reminders,
    required this.onAdd,
    required this.onDelete,
    required this.onComplete,
  });

  @override
  State<ReminderListScreen> createState() => _ReminderListScreenState();
}

class _ReminderListScreenState extends State<ReminderListScreen> {
  int _selectedFilter = 0; // 0: Semua, 1: Perlu Servis, 2: Aman

  List<ServiceReminder> get _filteredReminders {
    final curOdo = widget.vehicle?.currentOdometer ?? 0;
    if (_selectedFilter == 1) {
      return widget.reminders.where((r) {
        final s = r.getStatus(curOdo);
        return s == ReminderStatus.terlewat || s == ReminderStatus.mendekati;
      }).toList();
    } else if (_selectedFilter == 2) {
      return widget.reminders.where((r) {
        return r.getStatus(curOdo) == ReminderStatus.aman;
      }).toList();
    }
    return widget.reminders;
  }

  void _showAddReminderDialog() {
    if (widget.vehicle == null) return;

    final titleController = TextEditingController();
    final kmController = TextEditingController();
    final notesController = TextEditingController();
    String categoryKey = MaintenanceCategory.all.first.key;
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Buat Pengingat Servis'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: categoryKey,
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: MaintenanceCategory.all.map((c) {
                    return DropdownMenuItem(
                      value: c.key,
                      child: Text(c.label, style: const TextStyle(fontSize: 12)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() {
                        categoryKey = val;
                        final c = MaintenanceCategory.fromKey(val);
                        titleController.text = '${c.label} Mendatang';
                        if (c.defaultKmInterval > 0) {
                          kmController.text = (widget.vehicle!.currentOdometer +
                                  c.defaultKmInterval)
                              .toString();
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Judul Pengingat *',
                    hintText: 'Cth: Ganti Oli Mesin 15.000 KM',
                    prefixIcon: Icon(Icons.alarm),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: kmController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Target Kilometer (KM)',
                    hintText: 'Cth: 15000',
                    suffixText: 'KM',
                    prefixIcon: Icon(Icons.speed),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Target Tanggal (Opsional)',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      selectedDate != null
                          ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                          : 'Pilih Tanggal',
                      style: TextStyle(
                        color: selectedDate != null ? null : const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Catatan (Opsional)',
                    prefixIcon: Icon(Icons.notes),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final title = titleController.text.trim();
                if (title.isEmpty) return;

                final targetKm = int.tryParse(kmController.text.trim());

                final reminder = ServiceReminder(
                  id: 'rem_${DateTime.now().millisecondsSinceEpoch}',
                  vehicleId: widget.vehicle!.id,
                  title: title,
                  categoryKey: categoryKey,
                  targetOdometer: targetKm,
                  targetDate: selectedDate,
                  lastServiceOdometer: widget.vehicle!.currentOdometer,
                  lastServiceDate: DateTime.now(),
                  notes: notesController.text.trim(),
                );

                widget.onAdd(reminder);
                Navigator.of(ctx).pop();
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleServiceNow(ServiceReminder reminder) async {
    if (widget.vehicle == null) return;

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditServiceScreen(
          vehicle: widget.vehicle!,
          initialCategoryKey: reminder.categoryKey,
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      final record = result['record'] as MaintenanceRecord;
      widget.onComplete(reminder.id, newServiceRecord: record);
    }
  }

  @override
  Widget build(BuildContext context) {
    final curOdo = widget.vehicle?.currentOdometer ?? 0;
    final filtered = _filteredReminders;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengingat & Jadwal Servis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_alert_outlined),
            tooltip: 'Tambah Pengingat',
            onPressed: widget.vehicle != null ? _showAddReminderDialog : null,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs Container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Theme.of(context).cardColor,
            child: Row(
              children: [
                _buildFilterPill(0, 'Semua (${widget.reminders.length})'),
                const SizedBox(width: 8),
                _buildFilterPill(1, 'Perlu Servis', isAlert: true),
                const SizedBox(width: 8),
                _buildFilterPill(2, 'Aman'),
              ],
            ),
          ),

          const Divider(height: 1),

          // Reminder List
          Expanded(
            child: filtered.isEmpty
                ? EmptyStateWidget(
                    icon: Icons.event_available,
                    title: 'Tidak Ada Jadwal Servis',
                    subtitle: widget.vehicle == null
                        ? 'Pilih atau tambahkan kendaraan terlebih dahulu.'
                        : 'Semua jadwal servis Anda sudah terlaksana atau belum ada pengingat.',
                    buttonText: widget.vehicle != null ? 'Buat Pengingat' : null,
                    onButtonPressed:
                        widget.vehicle != null ? _showAddReminderDialog : null,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, index) {
                      final item = filtered[index];
                      return Dismissible(
                        key: Key(item.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => widget.onDelete(item.id),
                        child: ReminderCard(
                          reminder: item,
                          currentOdometer: curOdo,
                          onServiceNow: () => _handleServiceNow(item),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: widget.vehicle != null
          ? FloatingActionButton.extended(
              onPressed: _showAddReminderDialog,
              icon: const Icon(Icons.add_alert),
              label: const Text('Buat Pengingat'),
            )
          : null,
    );
  }

  Widget _buildFilterPill(int index, String label, {bool isAlert = false}) {
    final isSelected = _selectedFilter == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedFilter = index),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isAlert
                    ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                    : const Color(0xFF0D9488).withValues(alpha: 0.15))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? (isAlert ? const Color(0xFFEF4444) : const Color(0xFF0D9488))
                  : const Color(0xFFCBD5E1),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? (isAlert ? const Color(0xFFEF4444) : const Color(0xFF0D9488))
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
