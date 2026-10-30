class FuelRecord {
  final String id;
  final String vehicleId;
  final DateTime date;
  final int odometer;
  final double liters;
  final double pricePerLiter;
  final double totalCost;
  final String fuelType;
  final String gasStation;
  final bool isFullTank;
  final String notes;

  FuelRecord({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.odometer,
    required this.liters,
    required this.pricePerLiter,
    required this.totalCost,
    this.fuelType = 'Pertamax',
    this.gasStation = 'SPBU Pertamina',
    this.isFullTank = true,
    this.notes = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'date': date.toIso8601String(),
      'odometer': odometer,
      'liters': liters,
      'pricePerLiter': pricePerLiter,
      'totalCost': totalCost,
      'fuelType': fuelType,
      'gasStation': gasStation,
      'isFullTank': isFullTank,
      'notes': notes,
    };
  }

  factory FuelRecord.fromJson(Map<String, dynamic> json) {
    return FuelRecord(
      id: json['id'] as String,
      vehicleId: json['vehicleId'] as String,
      date: DateTime.parse(json['date'] as String),
      odometer: json['odometer'] as int? ?? 0,
      liters: (json['liters'] as num?)?.toDouble() ?? 0.0,
      pricePerLiter: (json['pricePerLiter'] as num?)?.toDouble() ?? 0.0,
      totalCost: (json['totalCost'] as num?)?.toDouble() ?? 0.0,
      fuelType: json['fuelType'] as String? ?? 'Pertamax',
      gasStation: json['gasStation'] as String? ?? 'SPBU Pertamina',
      isFullTank: json['isFullTank'] as bool? ?? true,
      notes: json['notes'] as String? ?? '',
    );
  }

  FuelRecord copyWith({
    String? id,
    String? vehicleId,
    DateTime? date,
    int? odometer,
    double? liters,
    double? pricePerLiter,
    double? totalCost,
    String? fuelType,
    String? gasStation,
    bool? isFullTank,
    String? notes,
  }) {
    return FuelRecord(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      date: date ?? this.date,
      odometer: odometer ?? this.odometer,
      liters: liters ?? this.liters,
      pricePerLiter: pricePerLiter ?? this.pricePerLiter,
      totalCost: totalCost ?? this.totalCost,
      fuelType: fuelType ?? this.fuelType,
      gasStation: gasStation ?? this.gasStation,
      isFullTank: isFullTank ?? this.isFullTank,
      notes: notes ?? this.notes,
    );
  }
}

