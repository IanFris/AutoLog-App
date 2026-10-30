import 'package:flutter/material.dart';
import '../models/maintenance_record.dart';
import '../models/vehicle.dart';
import '../utils/currency_formatter.dart';
import '../widgets/empty_state.dart';
import '../widgets/service_record_tile.dart';
import 'add_edit_service_screen.dart';
import 'service_detail_screen.dart';

class ServiceHistoryScreen extends StatefulWidget {
  final Vehicle? vehicle;
  final List<MaintenanceRecord> records;
  final Function(MaintenanceRecord record, {bool createNextReminder, int? intervalKm, int? intervalMonths}) onAdd;
  final Function(MaintenanceRecord record) onUpdate;
  final Function(String id) onDelete;

  const ServiceHistoryScreen({
    super.key,
    required this.vehicle,
    required this.records,
    required this.onAdd,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<ServiceHistoryScreen> createState() => _ServiceHistoryScreenState();
}

class _ServiceHistoryScreenState extends State<ServiceHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategoryKey = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MaintenanceRecord> get _filteredRecords {
    final query = _searchController.text.trim().toLowerCase();

    return widget.records.where((r) {
      final matchesCategory = _selectedCategoryKey == 'all' ||
          r.categoryKey == _selectedCategoryKey;

      final matchesQuery = query.isEmpty ||
          r.title.toLowerCase().contains(query) ||
          r.workshopName.toLowerCase().contains(query) ||
          r.notes.toLowerCase().contains(query) ||
          r.partsReplaced.any((p) => p.toLowerCase().contains(query));

      return matchesCategory && matchesQuery;
    }).toList();
  }

  Future<void> _navigateToAddService() async {
    if (widget.vehicle == null) return;

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditServiceScreen(
          vehicle: widget.vehicle!,
          initialCategoryKey: _selectedCategoryKey != 'all'
              ? _selectedCategoryKey
              : null,
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      widget.onAdd(
        result['record'] as MaintenanceRecord,
        createNextReminder: result['createNextReminder'] as bool? ?? false,
        intervalKm: result['intervalKm'] as int?,
        intervalMonths: result['intervalMonths'] as int?,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredRecords;
    final totalFilteredCost =
        filtered.fold(0.0, (sum, item) => sum + item.cost);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pemeliharaan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Tambah Servis',
            onPressed: widget.vehicle != null ? _navigateToAddService : null,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: Column(
              children: [
                // Search Input
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Cari servis, bengkel, atau part...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                ),

                const SizedBox(height: 10),

                // Category Chips (Horizontal Scroll)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: const Text('Semua'),
                          selected: _selectedCategoryKey == 'all',
                          onSelected: (_) {
                            setState(() => _selectedCategoryKey = 'all');
                          },
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                        ),
                      ),
                      ...MaintenanceCategory.all.map((cat) {
                        final isSelected = _selectedCategoryKey == cat.key;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            avatar: Icon(cat.icon, size: 14, color: cat.color),
                            label: Text(cat.label,
                                style: const TextStyle(fontSize: 12)),
                            selected: isSelected,
                            onSelected: (_) {
                              setState(() => _selectedCategoryKey = cat.key);
                            },
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Total Summary Strip
          if (filtered.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF0F172A)
                  : const Color(0xFFF1F5F9),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${filtered.length} Catatan Servis',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    'Total: ${CurrencyFormatter.format(totalFilteredCost)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0D9488),
                    ),
                  ),
                ],
              ),
            ),

          // Records List / Empty State
          Expanded(
            child: filtered.isEmpty
                ? EmptyStateWidget(
                    icon: Icons.history,
                    title: 'Belum Ada Riwayat Servis',
                    subtitle: widget.vehicle == null
                        ? 'Pilih atau tambahkan kendaraan terlebih dahulu.'
                        : _searchController.text.isNotEmpty
                            ? 'Tidak ada catatan servis yang cocok dengan pencarian Anda.'
                            : 'Mulai catat servis berkala, ganti oli, atau perbaikan kendaraan Anda.',
                    buttonText: widget.vehicle != null ? 'Catat Servis' : null,
                    onButtonPressed:
                        widget.vehicle != null ? _navigateToAddService : null,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, index) {
                      final item = filtered[index];
                      return ServiceRecordTile(
                        record: item,
                        onTap: () {
                          if (widget.vehicle == null) return;
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ServiceDetailScreen(
                                record: item,
                                vehicle: widget.vehicle!,
                                onUpdate: widget.onUpdate,
                                onDelete: () => widget.onDelete(item.id),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: widget.vehicle != null
          ? FloatingActionButton.extended(
              onPressed: _navigateToAddService,
              icon: const Icon(Icons.add),
              label: const Text('Catat Servis'),
            )
          : null,
    );
  }
}

