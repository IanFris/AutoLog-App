class ServiceLog {
  final int id;
  final int vehicleId;
  final int serviceTypeId;
  final DateTime serviceDate;
  final int odometerKm;
  final double cost;
  final String workshopName;
  final String? notes;
  final String? receiptPhotoUrl;
  final String? serviceTypeName;
  final String? serviceTypeIcon;
  final DateTime? createdAt;

  ServiceLog({
    required this.id,
    required this.vehicleId,
    required this.serviceTypeId,
    required this.serviceDate,
    required this.odometerKm,
    required this.cost,
    this.workshopName = 'Bengkel Umum',
    this.notes,
    this.receiptPhotoUrl,
    this.serviceTypeName,
    this.serviceTypeIcon,
    this.createdAt,
  });

  factory ServiceLog.fromJson(Map<String, dynamic> json) {
    return ServiceLog(
      id: (json['id'] as num).toInt(),
      vehicleId: (json['vehicle_id'] as num).toInt(),
      serviceTypeId: (json['service_type_id'] as num).toInt(),
      serviceDate: json['service_date'] != null
          ? DateTime.parse(json['service_date'].toString())
          : DateTime.now(),
      odometerKm: (json['odometer_km'] as num?)?.toInt() ?? 0,
      cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
      workshopName: json['workshop_name'] as String? ?? 'Bengkel Umum',
      notes: json['notes'] as String?,
      receiptPhotoUrl: json['receipt_photo_url'] as String?,
      serviceTypeName: json['service_type_name'] as String?,
      serviceTypeIcon: json['service_type_icon'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'service_type_id': serviceTypeId,
      'service_date': serviceDate.toIso8601String().substring(0, 10),
      'odometer_km': odometerKm,
      'cost': cost,
      'workshop_name': workshopName,
      'notes': notes,
      'receipt_photo_url': receiptPhotoUrl,
    };
  }
}

