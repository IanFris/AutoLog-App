import 'package:flutter/material.dart';

enum ReminderColorStatus {
  hijau,
  kuning,
  merah,
}

class ComponentReminder {
  final int id;
  final int vehicleId;
  final int serviceTypeId;
  final String serviceTypeName;
  final String serviceTypeIcon;
  final int? dueKm;
  final String? dueDate;
  final int? remainingKm;
  final int? remainingDays;
  final ReminderColorStatus statusColor;
  final String statusLabel;
  final String badgeColorHex;
  final double progressPercentage;

  ComponentReminder({
    required this.id,
    required this.vehicleId,
    required this.serviceTypeId,
    required this.serviceTypeName,
    required this.serviceTypeIcon,
    this.dueKm,
    this.dueDate,
    this.remainingKm,
    this.remainingDays,
    required this.statusColor,
    required this.statusLabel,
    required this.badgeColorHex,
    required this.progressPercentage,
  });

  factory ComponentReminder.fromJson(Map<String, dynamic> json) {
    final colorStr = (json['status_color'] as String? ?? 'hijau').toLowerCase();
    ReminderColorStatus colorStatus;
    if (colorStr == 'merah') {
      colorStatus = ReminderColorStatus.merah;
    } else if (colorStr == 'kuning') {
      colorStatus = ReminderColorStatus.kuning;
    } else {
      colorStatus = ReminderColorStatus.hijau;
    }

    return ComponentReminder(
      id: (json['id'] as num).toInt(),
      vehicleId: (json['vehicle_id'] as num).toInt(),
      serviceTypeId: (json['service_type_id'] as num).toInt(),
      serviceTypeName: json['service_type_name'] as String? ?? 'Komponen',
      serviceTypeIcon: json['service_type_icon'] as String? ?? 'build',
      dueKm: (json['due_km'] as num?)?.toInt(),
      dueDate: json['due_date'] as String?,
      remainingKm: (json['remaining_km'] as num?)?.toInt(),
      remainingDays: (json['remaining_days'] as num?)?.toInt(),
      statusColor: colorStatus,
      statusLabel: json['status_label'] as String? ?? 'Aman',
      badgeColorHex: json['badge_color_hex'] as String? ?? '#10B981',
      progressPercentage: (json['progress_percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Color get color {
    switch (statusColor) {
      case ReminderColorStatus.merah:
        return const Color(0xFFEF4444);
      case ReminderColorStatus.kuning:
        return const Color(0xFFF59E0B);
      case ReminderColorStatus.hijau:
        return const Color(0xFF10B981);
    }
  }

  IconData get iconData {
    switch (statusColor) {
      case ReminderColorStatus.merah:
        return Icons.warning_rounded;
      case ReminderColorStatus.kuning:
        return Icons.access_time_filled;
      case ReminderColorStatus.hijau:
        return Icons.check_circle_rounded;
    }
  }
}

