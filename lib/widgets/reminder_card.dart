import 'package:flutter/material.dart';
import '../models/service_reminder.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import 'custom_card.dart';

class ReminderCard extends StatelessWidget {
  final ServiceReminder reminder;
  final int currentOdometer;
  final VoidCallback? onServiceNow;
  final VoidCallback? onDismiss;
  final VoidCallback? onTap;

  const ReminderCard({
    super.key,
    required this.reminder,
    required this.currentOdometer,
    this.onServiceNow,
    this.onDismiss,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = reminder.getStatus(currentOdometer);
    final remainingKm = reminder.getRemainingKm(currentOdometer);
    final remainingDays = reminder.getRemainingDays();
    final progress = reminder.getProgress(currentOdometer);

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case ReminderStatus.terlewat:
        statusColor = const Color(0xFFEF4444);
        statusText = 'Lewat Batas Servis';
        statusIcon = Icons.warning_rounded;
        break;
      case ReminderStatus.mendekati:
        statusColor = const Color(0xFFF59E0B);
        statusText = 'Segera Servis';
        statusIcon = Icons.access_time_filled;
        break;
      case ReminderStatus.aman:
        statusColor = const Color(0xFF10B981);
        statusText = 'Jadwal Aman';
        statusIcon = Icons.check_circle;
        break;
    }

    return CustomCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Category Icon + Title + Status Pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: reminder.category.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  reminder.category.icon,
                  color: reminder.category.color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      reminder.category.label,
                      style: TextStyle(
                        fontSize: 12,
                        color: reminder.category.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
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
              value: progress,
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF334155)
                  : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 6,
            ),
          ),

          const SizedBox(height: 12),

          // Target KM & Target Date Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // KM Target info
              if (reminder.targetOdometer != null) ...[
                Row(
                  children: [
                    const Icon(Icons.speed, size: 15, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text(
                      remainingKm != null && remainingKm < 0
                          ? 'Terlewat ${CurrencyFormatter.formatNumber(remainingKm.abs())} KM'
                          : remainingKm != null
                              ? 'Sisa ${CurrencyFormatter.formatNumber(remainingKm)} KM'
                              : 'Target: ${CurrencyFormatter.formatNumber(reminder.targetOdometer)} KM',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: remainingKm != null && remainingKm <= 0
                            ? const Color(0xFFEF4444)
                            : null,
                      ),
                    ),
                  ],
                ),
              ],

              // Date Target info
              if (reminder.targetDate != null) ...[
                Row(
                  children: [
                    const Icon(Icons.event, size: 15, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text(
                      remainingDays != null && remainingDays < 0
                          ? 'Terlewat ${remainingDays.abs()} hari'
                          : remainingDays != null && remainingDays <= 7
                              ? 'Sisa $remainingDays hari'
                              : DateFormatter.format(reminder.targetDate),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: remainingDays != null && remainingDays < 0
                            ? const Color(0xFFEF4444)
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),

          // Action row if callback provided
          if (onServiceNow != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
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
                    icon: const Icon(Icons.build_circle_outlined, size: 18),
                    label: const Text(
                      'Servis Sekarang',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

