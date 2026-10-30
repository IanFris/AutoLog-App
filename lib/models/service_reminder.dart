import 'package:flutter/material.dart';
import 'maintenance_record.dart';

enum ReminderStatus {
  aman,
  mendekati,
  terlewat,
}

extension ReminderStatusExtension on ReminderStatus {
  String get label {
    switch (this) {
      case ReminderStatus.aman:
        return 'Jadwal Aman';
      case ReminderStatus.mendekati:
        return 'Mendekati Waktu Servis';
      case ReminderStatus.terlewat:
        return 'Lewat Batas Servis!';
    }
  }

  Color get color {
    switch (this) {
      case ReminderStatus.aman:
        return const Color(0xFF10B981); // Emerald
      case ReminderStatus.mendekati:
        return const Color(0xFFF59E0B); // Amber
      case ReminderStatus.terlewat:
        return const Color(0xFFEF4444); // Red
    }
  }

  IconData get icon {
    switch (this) {
      case ReminderStatus.aman:
        return Icons.check_circle_outline;
      case ReminderStatus.mendekati:
        return Icons.access_time;
      case ReminderStatus.terlewat:
        return Icons.warning_amber_rounded;
    }
  }
}

class ServiceReminder {
  final String id;
  final String vehicleId;
  final String title;
  final String categoryKey;
  final int? targetOdometer;
  final DateTime? targetDate;
  final int? lastServiceOdometer;
  final DateTime? lastServiceDate;
  final String notes;
  final bool isActive;

  ServiceReminder({
    required this.id,
    required this.vehicleId,
    required this.title,
    required this.categoryKey,
    this.targetOdometer,
    this.targetDate,
    this.lastServiceOdometer,
    this.lastServiceDate,
    this.notes = '',
    this.isActive = true,
  });

  MaintenanceCategory get category => MaintenanceCategory.fromKey(categoryKey);

  ReminderStatus getStatus(int currentOdometer, {DateTime? referenceDate}) {
    final now = referenceDate ?? DateTime.now();

    // Check overdue
    if (targetOdometer != null && currentOdometer >= targetOdometer!) {
      return ReminderStatus.terlewat;
    }
    if (targetDate != null && now.isAfter(targetDate!)) {
      return ReminderStatus.terlewat;
    }

    // Check due soon (within 500 km or 7 days)
    if (targetOdometer != null && (targetOdometer! - currentOdometer) <= 500) {
      return ReminderStatus.mendekati;
    }
    if (targetDate != null && targetDate!.difference(now).inDays <= 7) {
      return ReminderStatus.mendekati;
    }

    return ReminderStatus.aman;
  }

  int? getRemainingKm(int currentOdometer) {
    if (targetOdometer == null) return null;
    return targetOdometer! - currentOdometer;
  }

  int? getRemainingDays({DateTime? referenceDate}) {
    if (targetDate == null) return null;
    final now = referenceDate ?? DateTime.now();
    return targetDate!.difference(now).inDays;
  }

  double getProgress(int currentOdometer) {
    if (targetOdometer != null && lastServiceOdometer != null) {
      final totalInterval = targetOdometer! - lastServiceOdometer!;
      if (totalInterval <= 0) return 1.0;
      final traveled = currentOdometer - lastServiceOdometer!;
      return (traveled / totalInterval).clamp(0.0, 1.0);
    }
    if (targetDate != null && lastServiceDate != null) {
      final totalDays = targetDate!.difference(lastServiceDate!).inDays;
      if (totalDays <= 0) return 1.0;
      final passedDays = DateTime.now().difference(lastServiceDate!).inDays;
      return (passedDays / totalDays).clamp(0.0, 1.0);
    }
    return 0.5;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'title': title,
      'categoryKey': categoryKey,
      'targetOdometer': targetOdometer,
      'targetDate': targetDate?.toIso8601String(),
      'lastServiceOdometer': lastServiceOdometer,
      'lastServiceDate': lastServiceDate?.toIso8601String(),
      'notes': notes,
      'isActive': isActive,
    };
  }

  factory ServiceReminder.fromJson(Map<String, dynamic> json) {
    return ServiceReminder(
      id: json['id'] as String,
      vehicleId: json['vehicleId'] as String,
      title: json['title'] as String,
      categoryKey: json['categoryKey'] as String? ?? 'lainnya',
      targetOdometer: json['targetOdometer'] as int?,
      targetDate: json['targetDate'] != null
          ? DateTime.tryParse(json['targetDate'] as String)
          : null,
      lastServiceOdometer: json['lastServiceOdometer'] as int?,
      lastServiceDate: json['lastServiceDate'] != null
          ? DateTime.tryParse(json['lastServiceDate'] as String)
          : null,
      notes: json['notes'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  ServiceReminder copyWith({
    String? id,
    String? vehicleId,
    String? title,
    String? categoryKey,
    int? targetOdometer,
    DateTime? targetDate,
    int? lastServiceOdometer,
    DateTime? lastServiceDate,
    String? notes,
    bool? isActive,
  }) {
    return ServiceReminder(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      title: title ?? this.title,
      categoryKey: categoryKey ?? this.categoryKey,
      targetOdometer: targetOdometer ?? this.targetOdometer,
      targetDate: targetDate ?? this.targetDate,
      lastServiceOdometer: lastServiceOdometer ?? this.lastServiceOdometer,
      lastServiceDate: lastServiceDate ?? this.lastServiceDate,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
    );
  }
}

