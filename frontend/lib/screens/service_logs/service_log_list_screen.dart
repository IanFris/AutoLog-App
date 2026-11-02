import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/api_constants.dart';
import '../../models/service_log.dart';
import '../../models/vehicle.dart';
import '../../providers/vehicle_provider.dart';
import '../../providers/service_provider.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/date_formatter.dart';
import '../../utils/service_log_csv_exporter.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/empty_state.dart';
import 'add_service_log_screen.dart';

class ServiceLogListScreen extends StatefulWidget {
  const ServiceLogListScreen({super.key});

  @override
  State<ServiceLogListScreen> createState() => _ServiceLogListScreenState();
}

class _ServiceLogListScreenState extends State<ServiceLogListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isExporting = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showReceiptDialog(BuildContext context, ServiceLog log) {
    if (log.receiptPhotoUrl == null || log.receiptPhotoUrl!.isEmpty) return;

    final fullUrl = '${ApiConstants.uploadsBaseUrl}${log.receiptPhotoUrl}';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(log.serviceTypeName ?? 'Nota Servis'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${DateFormatter.format(log.serviceDate)} • ${log.workshopName}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                fullUrl,
                fit: BoxFit.contain,
                loadingBuilder: (ctx, child, progress) {
                  if (progress == null) return child;
                  return const SizedBox(
                    height: 150,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (ctx, _, __) => Container(
                  height: 120,
                  alignment: Alignment.center,
                  color: Colors.grey.shade200,
                  child: const Text('Foto nota tidak dapat dimuat.'),
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
        ],
      ),
    );
  }

  Future<void> _exportServiceLogs(
      Vehicle vehicle, List<ServiceLog> logs) async {
    setState(() => _isExporting = true);
    try {
      final date = DateFormat('yyyyMMdd').format(DateTime.now());
      final safePlate = vehicle.licensePlate.replaceAll(
        RegExp(r'[^A-Za-z0-9_-]'),
        '_',
      );
      final fileName = 'autolog_riwayat_${safePlate}_$date.csv';
      final csv = ServiceLogCsvExporter.createCsv(logs);
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              Uint8List.fromList(utf8.encode(csv)),
              mimeType: 'text/csv',
              name: fileName,
            ),
          ],
          fileNameOverrides: [fileName],
          title: 'Riwayat Servis ${vehicle.brandModel}',
          downloadFallbackEnabled: true,
        ),
      );
      if (mounted && result.status == ShareResultStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Riwayat servis berhasil dibagikan.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengekspor riwayat servis: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vp = context.watch<VehicleProvider>();
    final sp = context.watch<ServiceProvider>();
    final logs = sp.serviceLogs;
    final vehicle = vp.activeVehicle;

    final query = _searchController.text.trim().toLowerCase();
    final filtered = logs.where((l) {
      if (query.isEmpty) return true;
      final name = (l.serviceTypeName ?? '').toLowerCase();
      final workshop = l.workshopName.toLowerCase();
      final notes = (l.notes ?? '').toLowerCase();
      return name.contains(query) ||
          workshop.contains(query) ||
          notes.contains(query);
    }).toList();

    final totalCost = filtered.fold(0.0, (sum, item) => sum + item.cost);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pemeliharaan'),
        actions: [
          IconButton(
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.file_download_outlined),
            tooltip: 'Ekspor riwayat ke CSV',
            onPressed: vehicle == null || logs.isEmpty || _isExporting
                ? null
                : () => _exportServiceLogs(vehicle, logs),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Tambah Servis',
            onPressed: vehicle != null
                ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AddServiceLogScreen(vehicle: vehicle),
                      ),
                    );
                  }
                : null,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            color: Theme.of(context).cardColor,
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Cari servis, bengkel, atau catatan...',
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
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
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
                        color: Color(0xFF64748B)),
                  ),
                  Text(
                    'Total: ${CurrencyFormatter.format(totalCost)}',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0D9488)),
                  ),
                ],
              ),
            ),

          // Logs List
          Expanded(
            child: sp.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.history,
                        title: 'Belum Ada Riwayat Servis',
                        subtitle: vehicle == null
                            ? 'Pilih kendaraan Anda terlebih dahulu.'
                            : 'Mulai catat pemeliharaan kendaraan Anda sekarang.',
                        buttonText: vehicle != null ? 'Catat Servis' : null,
                        onButtonPressed: vehicle != null
                            ? () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        AddServiceLogScreen(vehicle: vehicle),
                                  ),
                                );
                              }
                            : null,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, index) {
                          final item = filtered[index];
                          final hasPhoto = item.receiptPhotoUrl != null &&
                              item.receiptPhotoUrl!.isNotEmpty;

                          return CustomCard(
                            padding: const EdgeInsets.all(14),
                            margin: const EdgeInsets.only(bottom: 10),
                            onTap: hasPhoto
                                ? () => _showReceiptDialog(context, item)
                                : null,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Category Icon
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0D9488)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.build_circle,
                                    color: Color(0xFF0D9488),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.serviceTypeName ?? 'Pemeliharaan',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${item.workshopName} • ${DateFormatter.format(item.serviceDate)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? const Color(0xFF334155)
                                                  : const Color(0xFFE2E8F0),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '${CurrencyFormatter.formatNumber(item.odometerKm)} KM',
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                          if (hasPhoto) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF3B82F6)
                                                    .withValues(alpha: 0.12),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.receipt,
                                                      size: 12,
                                                      color: Color(0xFF3B82F6)),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Nota',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(0xFF3B82F6),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (item.notes != null &&
                                          item.notes!.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          item.notes!,
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF94A3B8)),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 8),

                                // Cost
                                Text(
                                  CurrencyFormatter.format(item.cost),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0D9488),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: vehicle != null
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AddServiceLogScreen(vehicle: vehicle),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Catat Servis'),
            )
          : null,
    );
  }
}
