import 'package:flutter/material.dart';
import '../models/component_reminder.dart';
import '../utils/currency_formatter.dart';
import 'custom_card.dart';

class ComponentStatusCard extends StatelessWidget {
  final ComponentReminder reminder;
  final VoidCallback? onServiceNow;

  const ComponentStatusCard({
    super.key,
    required this.reminder,
    this.onServiceNow,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = reminder.color;

    return CustomCard(
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon + Title + Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  reminder.iconData,
                  color: statusColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.serviceTypeName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      reminder.dueKm != null
                          ? 'Target: ${CurrencyFormatter.formatNumber(reminder.dueKm)} KM'
                          : 'Jadwal Rutin',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Status Badge (Hijau, Kuning, Merah)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      reminder.statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: reminder.progressPercentage,
              minHeight: 6,
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF334155)
                  : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),

          const SizedBox(height: 12),

          // KM & Due Date Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (reminder.remainingKm != null)
                Row(
                  children: [
                    const Icon(Icons.speed, size: 14, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text(
                      reminder.remainingKm! < 0
                          ? 'Terlewat ${CurrencyFormatter.formatNumber(reminder.remainingKm!.abs())} KM'
                          : 'Sisa ${CurrencyFormatter.formatNumber(reminder.remainingKm!)} KM',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: reminder.remainingKm! <= 0
                            ? const Color(0xFFEF4444)
                            : null,
                      ),
                    ),
                  ],
                ),
              if (reminder.dueDate != null)
                Row(
                  children: [
                    const Icon(Icons.event, size: 14, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text(
                      reminder.remainingDays != null &&
                              reminder.remainingDays! < 0
                          ? 'Terlewat ${reminder.remainingDays!.abs()} hari'
                          : reminder.remainingDays != null &&
                                  reminder.remainingDays! <= 7
                              ? 'Sisa ${reminder.remainingDays} hari'
                              : reminder.dueDate!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: reminder.remainingDays != null &&
                                reminder.remainingDays! < 0
                            ? const Color(0xFFEF4444)
                            : null,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          if (onServiceNow != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  side: BorderSide(color: statusColor),
                  foregroundColor: statusColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: onServiceNow,
                icon: const Icon(Icons.build_circle_outlined, size: 16),
                label: const Text(
                  'Servis Komponen Ini',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
