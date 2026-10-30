import 'package:flutter/material.dart';
import '../models/fuel_record.dart';
import '../models/vehicle.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../widgets/custom_card.dart';
import '../widgets/empty_state.dart';
import 'add_fuel_screen.dart';

class FuelHistoryScreen extends StatelessWidget {
  final Vehicle? vehicle;
  final List<FuelRecord> fuelRecords;
  final double averageEfficiency;
  final Function(FuelRecord record) onAdd;
  final Function(String id) onDelete;

  const FuelHistoryScreen({
    super.key,
    required this.vehicle,
    required this.fuelRecords,
    required this.averageEfficiency,
    required this.onAdd,
    required this.onDelete,
  });

  Future<void> _navigateToAddFuel(BuildContext context) async {
    if (vehicle == null) return;

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddFuelScreen(vehicle: vehicle!),
      ),
    );

    if (result != null && result is FuelRecord) {
      onAdd(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalCost = fuelRecords.fold(0.0, (sum, f) => sum + f.totalCost);
    final totalLiters = fuelRecords.fold(0.0, (sum, f) => sum + f.liters);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan BBM & Konsumsi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.local_gas_station_outlined),
            tooltip: 'Isi BBM',
            onPressed: vehicle != null ? () => _navigateToAddFuel(context) : null,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Metrics Card
          if (vehicle != null && fuelRecords.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).cardColor,
              child: Row(
                children: [
                  Expanded(
                    child: _buildMetric(
                      context,
                      label: 'Total Biaya BBM',
                      value: CurrencyFormatter.formatCompact(totalCost),
                      icon: Icons.payments,
                      color: const Color(0xFF0D9488),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetric(
                      context,
                      label: 'Konsumsi Rata-rata',
                      value: averageEfficiency > 0
                          ? '${averageEfficiency.toStringAsFixed(1)} KM/L'
                          : '-',
                      icon: Icons.speed,
                      color: const Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetric(
                      context,
                      label: 'Total Liter',
                      value: '${totalLiters.toStringAsFixed(1)} L',
                      icon: Icons.opacity,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
            ),

          const Divider(height: 1),

          // Fuel Logs List
          Expanded(
            child: fuelRecords.isEmpty
                ? EmptyStateWidget(
                    icon: Icons.local_gas_station,
                    title: 'Belum Ada Catatan BBM',
                    subtitle: vehicle == null
                        ? 'Pilih atau tambahkan kendaraan terlebih dahulu.'
                        : 'Catat setiap pengisian bahan bakar untuk memantau pengeluaran dan efisiensi konsumsi kendaraan.',
                    buttonText: vehicle != null ? 'Catat Isi BBM' : null,
                    onButtonPressed:
                        vehicle != null ? () => _navigateToAddFuel(context) : null,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: fuelRecords.length,
                    itemBuilder: (ctx, index) {
                      final item = fuelRecords[index];
                      return Dismissible(
                        key: Key(item.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => onDelete(item.id),
                        child: CustomCard(
                          padding: const EdgeInsets.all(14),
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D9488)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.local_gas_station,
                                  color: Color(0xFF0D9488),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          item.fuelType,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        if (item.isFullTank)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF10B981)
                                                  .withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'Full',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF10B981),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${item.gasStation} • ${CurrencyFormatter.formatNumber(item.odometer)} KM',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormatter.format(item.date),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    CurrencyFormatter.format(item.totalCost),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0D9488),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${item.liters.toStringAsFixed(1)} Liter',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: vehicle != null
          ? FloatingActionButton.extended(
              onPressed: () => _navigateToAddFuel(context),
              icon: const Icon(Icons.add),
              label: const Text('Isi BBM'),
            )
          : null,
    );
  }

  Widget _buildMetric(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E293B)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF334155)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

