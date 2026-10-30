import 'package:flutter/material.dart';

class MaintenanceCategory {
  final String key;
  final String label;
  final IconData icon;
  final Color color;
  final int defaultKmInterval;
  final int defaultMonthInterval;

  const MaintenanceCategory({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
    this.defaultKmInterval = 3000,
    this.defaultMonthInterval = 3,
  });

  static const List<MaintenanceCategory> all = [
    MaintenanceCategory(
      key: 'oli_mesin',
      label: 'Ganti Oli Mesin',
      icon: Icons.opacity,
      color: Color(0xFFEAB308), // Amber
      defaultKmInterval: 3000,
      defaultMonthInterval: 2,
    ),
    MaintenanceCategory(
      key: 'oli_gardan',
      label: 'Ganti Oli Gardan / Transmisi',
      icon: Icons.settings,
      color: Color(0xFFF97316), // Orange
      defaultKmInterval: 8000,
      defaultMonthInterval: 6,
    ),
    MaintenanceCategory(
      key: 'servis_rutin',
      label: 'Servis Berkala / Tune Up',
      icon: Icons.build,
      color: Color(0xFF0284C7), // Sky blue
      defaultKmInterval: 4000,
      defaultMonthInterval: 3,
    ),
    MaintenanceCategory(
      key: 'kampas_rem',
      label: 'Kampas Rem Depan / Belakang',
      icon: Icons.album_outlined,
      color: Color(0xFFEF4444), // Red
      defaultKmInterval: 10000,
      defaultMonthInterval: 8,
    ),
    MaintenanceCategory(
      key: 'busi',
      label: 'Ganti Busi',
      icon: Icons.flash_on,
      color: Color(0xFF8B5CF6), // Purple
      defaultKmInterval: 8000,
      defaultMonthInterval: 6,
    ),
    MaintenanceCategory(
      key: 'filter_udara',
      label: 'Filter Udara',
      icon: Icons.air,
      color: Color(0xFF14B8A6), // Teal
      defaultKmInterval: 12000,
      defaultMonthInterval: 10,
    ),
    MaintenanceCategory(
      key: 'ban',
      label: 'Ganti Ban & Spooring',
      icon: Icons.adjust,
      color: Color(0xFF64748B), // Slate
      defaultKmInterval: 20000,
      defaultMonthInterval: 18,
    ),
    MaintenanceCategory(
      key: 'aki',
      label: 'Aki / Battery Accu',
      icon: Icons.battery_charging_full,
      color: Color(0xFF10B981), // Emerald
      defaultKmInterval: 24000,
      defaultMonthInterval: 24,
    ),
    MaintenanceCategory(
      key: 'cvt_rantai',
      label: 'CVT Belt & Roller / Rantai',
      icon: Icons.sync,
      color: Color(0xFFD97706), // Amber dark
      defaultKmInterval: 15000,
      defaultMonthInterval: 12,
    ),
    MaintenanceCategory(
      key: 'radiator',
      label: 'Air Radiator / Coolant',
      icon: Icons.waves,
      color: Color(0xFF06B6D4), // Cyan
      defaultKmInterval: 12000,
      defaultMonthInterval: 12,
    ),
    MaintenanceCategory(
      key: 'pajak_stnk',
      label: 'Pajak STNK / PKB',
      icon: Icons.receipt_long,
      color: Color(0xFF6366F1), // Indigo
      defaultKmInterval: 0,
      defaultMonthInterval: 12,
    ),
    MaintenanceCategory(
      key: 'cuci_detailing',
      label: 'Cuci & Detailing Kendaraan',
      icon: Icons.local_car_wash,
      color: Color(0xFF38BDF8), // Light blue
      defaultKmInterval: 0,
      defaultMonthInterval: 1,
    ),
    MaintenanceCategory(
      key: 'lainnya',
      label: 'Perbaikan / Suku Cadang Lain',
      icon: Icons.handyman,
      color: Color(0xFF6B7280), // Gray
      defaultKmInterval: 5000,
      defaultMonthInterval: 6,
    ),
  ];

  static MaintenanceCategory fromKey(String key) {
    return all.firstWhere(
      (element) => element.key == key,
      orElse: () => all.last,
    );
  }

  static MaintenanceCategory fromLabel(String label) {
    return all.firstWhere(
      (element) => element.label.toLowerCase() == label.toLowerCase(),
      orElse: () => all.last,
    );
  }
}

class MaintenanceRecord {
  final String id;
  final String vehicleId;
  final DateTime date;
  final int odometer; // KM at service
  final String title;
  final String categoryKey;
  final String workshopName;
  final double cost;
  final String notes;
  final List<String> partsReplaced;
  final DateTime? nextServiceDate;
  final int? nextServiceOdometer;
  final bool isCompleted;

  MaintenanceRecord({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.odometer,
    required this.title,
    required this.categoryKey,
    required this.workshopName,
    required this.cost,
    this.notes = '',
    this.partsReplaced = const [],
    this.nextServiceDate,
    this.nextServiceOdometer,
    this.isCompleted = true,
  });

  MaintenanceCategory get category => MaintenanceCategory.fromKey(categoryKey);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'date': date.toIso8601String(),
      'odometer': odometer,
      'title': title,
      'categoryKey': categoryKey,
      'workshopName': workshopName,
      'cost': cost,
      'notes': notes,
      'partsReplaced': partsReplaced,
      'nextServiceDate': nextServiceDate?.toIso8601String(),
      'nextServiceOdometer': nextServiceOdometer,
      'isCompleted': isCompleted,
    };
  }

  factory MaintenanceRecord.fromJson(Map<String, dynamic> json) {
    return MaintenanceRecord(
      id: json['id'] as String,
      vehicleId: json['vehicleId'] as String,
      date: DateTime.parse(json['date'] as String),
      odometer: json['odometer'] as int? ?? 0,
      title: json['title'] as String? ?? 'Perawatan Kendaraan',
      categoryKey: json['categoryKey'] as String? ?? 'lainnya',
      workshopName: json['workshopName'] as String? ?? 'Bengkel Mandiri',
      cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String? ?? '',
      partsReplaced: (json['partsReplaced'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      nextServiceDate: json['nextServiceDate'] != null
          ? DateTime.tryParse(json['nextServiceDate'] as String)
          : null,
      nextServiceOdometer: json['nextServiceOdometer'] as int?,
      isCompleted: json['isCompleted'] as bool? ?? true,
    );
  }

  MaintenanceRecord copyWith({
    String? id,
    String? vehicleId,
    DateTime? date,
    int? odometer,
    String? title,
    String? categoryKey,
    String? workshopName,
    double? cost,
    String? notes,
    List<String>? partsReplaced,
    DateTime? nextServiceDate,
    int? nextServiceOdometer,
    bool? isCompleted,
  }) {
    return MaintenanceRecord(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      date: date ?? this.date,
      odometer: odometer ?? this.odometer,
      title: title ?? this.title,
      categoryKey: categoryKey ?? this.categoryKey,
      workshopName: workshopName ?? this.workshopName,
      cost: cost ?? this.cost,
      notes: notes ?? this.notes,
      partsReplaced: partsReplaced ?? this.partsReplaced,
      nextServiceDate: nextServiceDate ?? this.nextServiceDate,
      nextServiceOdometer: nextServiceOdometer ?? this.nextServiceOdometer,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

