import 'package:flutter/material.dart';

enum VehicleType {
  motorcycle,
  car,
}

extension VehicleTypeExtension on VehicleType {
  String get label {
    switch (this) {
      case VehicleType.motorcycle:
        return 'Sepeda Motor';
      case VehicleType.car:
        return 'Mobil';
    }
  }

  IconData get icon {
    switch (this) {
      case VehicleType.motorcycle:
        return Icons.two_wheeler;
      case VehicleType.car:
        return Icons.directions_car;
    }
  }
}

class Vehicle {
  final String id;
  final String name; // e.g. "Honda Vario 160"
  final VehicleType type;
  final String brand; // e.g. "Honda"
  final String model; // e.g. "Vario 160 ABS"
  final int year; // e.g. 2023
  final String licensePlate; // e.g. "B 4589 SKM"
  final int currentOdometer; // e.g. 14850
  final String fuelType; // e.g. "Pertamax"
  final String color; // e.g. "Hitam Matte"
  final String notes;
  final DateTime createdAt;

  Vehicle({
    required this.id,
    required this.name,
    required this.type,
    required this.brand,
    required this.model,
    required this.year,
    required this.licensePlate,
    required this.currentOdometer,
    this.fuelType = 'Pertamax',
    this.color = 'Hitam',
    this.notes = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'brand': brand,
      'model': model,
      'year': year,
      'licensePlate': licensePlate,
      'currentOdometer': currentOdometer,
      'fuelType': fuelType,
      'color': color,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] == 'car' ? VehicleType.car : VehicleType.motorcycle,
      brand: json['brand'] as String? ?? '',
      model: json['model'] as String? ?? '',
      year: json['year'] as int? ?? DateTime.now().year,
      licensePlate: json['licensePlate'] as String? ?? '',
      currentOdometer: json['currentOdometer'] as int? ?? 0,
      fuelType: json['fuelType'] as String? ?? 'Pertamax',
      color: json['color'] as String? ?? 'Hitam',
      notes: json['notes'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Vehicle copyWith({
    String? id,
    String? name,
    VehicleType? type,
    String? brand,
    String? model,
    int? year,
    String? licensePlate,
    int? currentOdometer,
    String? fuelType,
    String? color,
    String? notes,
    DateTime? createdAt,
  }) {
    return Vehicle(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      licensePlate: licensePlate ?? this.licensePlate,
      currentOdometer: currentOdometer ?? this.currentOdometer,
      fuelType: fuelType ?? this.fuelType,
      color: color ?? this.color,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

