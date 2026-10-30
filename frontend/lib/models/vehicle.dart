import 'package:flutter/material.dart';

enum VehicleType {
  motor,
  mobil,
}

extension VehicleTypeExt on VehicleType {
  String get label => this == VehicleType.motor ? 'Sepeda Motor' : 'Mobil';
  IconData get icon => this == VehicleType.motor ? Icons.two_wheeler : Icons.directions_car;
}

class Vehicle {
  final int id;
  final int userId;
  final VehicleType type;
  final String brandModel;
  final String licensePlate;
  final int currentOdometer;
  final DateTime? createdAt;

  Vehicle({
    required this.id,
    required this.userId,
    required this.type,
    required this.brandModel,
    required this.licensePlate,
    required this.currentOdometer,
    this.createdAt,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      type: (json['type'] as String? ?? 'motor').toLowerCase() == 'mobil'
          ? VehicleType.mobil
          : VehicleType.motor,
      brandModel: json['brand_model'] as String? ?? '',
      licensePlate: json['license_plate'] as String? ?? '',
      currentOdometer: (json['current_odometer'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type == VehicleType.mobil ? 'mobil' : 'motor',
      'brand_model': brandModel,
      'license_plate': licensePlate,
      'current_odometer': currentOdometer,
    };
  }

  Vehicle copyWith({
    int? id,
    int? userId,
    VehicleType? type,
    String? brandModel,
    String? licensePlate,
    int? currentOdometer,
    DateTime? createdAt,
  }) {
    return Vehicle(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      brandModel: brandModel ?? this.brandModel,
      licensePlate: licensePlate ?? this.licensePlate,
      currentOdometer: currentOdometer ?? this.currentOdometer,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
