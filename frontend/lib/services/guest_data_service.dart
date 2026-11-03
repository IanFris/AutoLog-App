import 'dart:convert';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../models/component_reminder.dart';
import '../models/expense_summary.dart';
import '../models/service_log.dart';
import '../models/service_type.dart';
import '../models/vehicle.dart';

class GuestDataService {
  static const _vehiclesKey = 'autolog_guest_vehicles';
  static const _logsKey = 'autolog_guest_service_logs';
  static const _nextVehicleIdKey = 'autolog_guest_next_vehicle_id';
  static const _nextLogIdKey = 'autolog_guest_next_log_id';

  static final List<ServiceType> _serviceTypes = [
    ServiceType(
        id: 1,
        name: 'Ganti Oli Mesin',
        defaultKmInterval: 3000,
        defaultMonthInterval: 2,
        icon: 'opacity'),
    ServiceType(
        id: 2,
        name: 'Ganti Oli Gardan / Transmisi',
        defaultKmInterval: 8000,
        defaultMonthInterval: 6,
        icon: 'settings'),
    ServiceType(
        id: 3,
        name: 'Servis Berkala / Tune Up',
        defaultKmInterval: 4000,
        defaultMonthInterval: 3),
    ServiceType(
        id: 4,
        name: 'Kampas Rem Depan / Belakang',
        defaultKmInterval: 10000,
        defaultMonthInterval: 8,
        icon: 'album'),
    ServiceType(
        id: 5,
        name: 'Ganti Busi',
        defaultKmInterval: 8000,
        defaultMonthInterval: 6,
        icon: 'flash_on'),
    ServiceType(
        id: 6,
        name: 'Filter Udara',
        defaultKmInterval: 12000,
        defaultMonthInterval: 10,
        icon: 'air'),
    ServiceType(
        id: 7,
        name: 'Ganti Ban & Spooring',
        defaultKmInterval: 20000,
        defaultMonthInterval: 18,
        icon: 'adjust'),
    ServiceType(
        id: 8,
        name: 'Aki / Battery Accu',
        defaultKmInterval: 24000,
        defaultMonthInterval: 24,
        icon: 'battery_charging_full'),
    ServiceType(
        id: 9,
        name: 'CVT Belt & Roller / Rantai',
        defaultKmInterval: 15000,
        defaultMonthInterval: 12,
        icon: 'sync'),
    ServiceType(
        id: 10,
        name: 'Air Radiator / Coolant',
        defaultKmInterval: 12000,
        defaultMonthInterval: 12,
        icon: 'waves'),
  ];

  static Future<List<Map<String, dynamic>>> _readList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(key);
    if (value == null) return [];
    final decoded = jsonDecode(value);
    if (decoded is! List) {
      throw const FormatException('Data lokal AutoLog tidak valid.');
    }
    return decoded.cast<Map<String, dynamic>>();
  }

  static Future<void> _writeList(
    String key,
    List<Map<String, dynamic>> values,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(key, jsonEncode(values))) {
      throw StateError('Gagal menyimpan data AutoLog di perangkat.');
    }
  }

  static Future<int> _nextId(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(key) ?? 1;
    if (!await prefs.setInt(key, id + 1)) {
      throw StateError('Gagal membuat ID data lokal.');
    }
    return id;
  }

  static Future<List<Vehicle>> getVehicles(int userId) async {
    final rows = await _readList(_vehiclesKey);
    return rows
        .where((row) => row['user_id'] == userId)
        .map(Vehicle.fromJson)
        .toList();
  }

  static Future<Vehicle> createVehicle({
    required int userId,
    required String type,
    required String brandModel,
    required String licensePlate,
    required int currentOdometer,
  }) async {
    final rows = await _readList(_vehiclesKey);
    final vehicle = Vehicle(
      id: await _nextId(_nextVehicleIdKey),
      userId: userId,
      type: type == 'mobil' ? VehicleType.mobil : VehicleType.motor,
      brandModel: brandModel,
      licensePlate: licensePlate,
      currentOdometer: currentOdometer,
      createdAt: DateTime.now(),
    );
    rows.add(vehicle.toJson());
    await _writeList(_vehiclesKey, rows);
    return vehicle;
  }

  static Future<void> updateVehicle({
    required int vehicleId,
    String? type,
    String? brandModel,
    String? licensePlate,
    int? currentOdometer,
  }) async {
    final rows = await _readList(_vehiclesKey);
    final index = rows.indexWhere((row) => row['id'] == vehicleId);
    if (index < 0) throw StateError('Kendaraan tidak ditemukan di perangkat.');
    final vehicle = Vehicle.fromJson(rows[index]).copyWith(
      type: type == null
          ? null
          : type == 'mobil'
              ? VehicleType.mobil
              : VehicleType.motor,
      brandModel: brandModel,
      licensePlate: licensePlate,
      currentOdometer: currentOdometer,
    );
    rows[index] = vehicle.toJson();
    await _writeList(_vehiclesKey, rows);
  }

  static Future<void> updateOdometer(int vehicleId, int newOdometer) =>
      updateVehicle(vehicleId: vehicleId, currentOdometer: newOdometer);

  static Future<void> deleteVehicle(int vehicleId) async {
    final vehicles = await _readList(_vehiclesKey);
    final logs = await _readList(_logsKey);
    if (!vehicles.any((row) => row['id'] == vehicleId)) {
      throw StateError('Kendaraan tidak ditemukan di perangkat.');
    }
    final removedLogs = logs.where((row) => row['vehicle_id'] == vehicleId);
    for (final row in removedLogs) {
      await _deleteReceipt(row['receipt_photo_url'] as String?);
    }
    vehicles.removeWhere((row) => row['id'] == vehicleId);
    logs.removeWhere((row) => row['vehicle_id'] == vehicleId);
    await _writeList(_vehiclesKey, vehicles);
    await _writeList(_logsKey, logs);
  }

  static Future<List<ServiceType>> getServiceTypes() async =>
      List.unmodifiable(_serviceTypes);

  static Future<List<ServiceLog>> getServiceLogs(int vehicleId) async {
    final rows = await _readList(_logsKey);
    return rows.where((row) => row['vehicle_id'] == vehicleId).map((row) {
      final log = ServiceLog.fromJson(row);
      final type = _serviceTypes.firstWhere(
        (item) => item.id == log.serviceTypeId,
        orElse: () => ServiceType(
          id: log.serviceTypeId,
          name: 'Servis',
          defaultKmInterval: 0,
          defaultMonthInterval: 0,
        ),
      );
      return ServiceLog(
        id: log.id,
        vehicleId: log.vehicleId,
        serviceTypeId: log.serviceTypeId,
        serviceDate: log.serviceDate,
        odometerKm: log.odometerKm,
        cost: log.cost,
        workshopName: log.workshopName,
        notes: log.notes,
        receiptPhotoUrl: log.receiptPhotoUrl,
        serviceTypeName: type.name,
        serviceTypeIcon: type.icon,
        createdAt: log.createdAt,
      );
    }).toList()
      ..sort((a, b) {
        final dateOrder = b.serviceDate.compareTo(a.serviceDate);
        return dateOrder != 0 ? dateOrder : b.id.compareTo(a.id);
      });
  }

  static Future<ServiceLog> createServiceLog({
    required int vehicleId,
    required int serviceTypeId,
    required String serviceDate,
    required int odometerKm,
    required double cost,
    String? workshopName,
    String? notes,
    XFile? receiptPhoto,
  }) async {
    final id = await _nextId(_nextLogIdKey);
    final photoPath =
        receiptPhoto == null ? null : await _saveReceipt(id, receiptPhoto);
    final log = ServiceLog(
      id: id,
      vehicleId: vehicleId,
      serviceTypeId: serviceTypeId,
      serviceDate: DateTime.parse(serviceDate),
      odometerKm: odometerKm,
      cost: cost,
      workshopName: workshopName ?? 'Bengkel Umum',
      notes: notes,
      receiptPhotoUrl: photoPath,
    );
    final rows = await _readList(_logsKey);
    rows.add(log.toJson()..['created_at'] = DateTime.now().toIso8601String());
    await _writeList(_logsKey, rows);
    final vehicles = await _readList(_vehiclesKey);
    final vehicleIndex = vehicles.indexWhere((row) => row['id'] == vehicleId);
    if (vehicleIndex >= 0) {
      final vehicle = Vehicle.fromJson(vehicles[vehicleIndex]);
      if (odometerKm > vehicle.currentOdometer) {
        vehicles[vehicleIndex] =
            vehicle.copyWith(currentOdometer: odometerKm).toJson();
        await _writeList(_vehiclesKey, vehicles);
      }
    }
    return log;
  }

  static Future<void> updateServiceLog({
    required int serviceLogId,
    required int vehicleId,
    required int serviceTypeId,
    required String serviceDate,
    required int odometerKm,
    required double cost,
    String? workshopName,
    String? notes,
    XFile? receiptPhoto,
  }) async {
    final rows = await _readList(_logsKey);
    final index = rows.indexWhere((row) => row['id'] == serviceLogId);
    if (index < 0) {
      throw StateError('Catatan servis tidak ditemukan di perangkat.');
    }
    final previousPhoto = rows[index]['receipt_photo_url'] as String?;
    final photoPath = receiptPhoto == null
        ? previousPhoto
        : await _saveReceipt(serviceLogId, receiptPhoto);
    final updated = ServiceLog(
      id: serviceLogId,
      vehicleId: vehicleId,
      serviceTypeId: serviceTypeId,
      serviceDate: DateTime.parse(serviceDate),
      odometerKm: odometerKm,
      cost: cost,
      workshopName: workshopName ?? 'Bengkel Umum',
      notes: notes,
      receiptPhotoUrl: photoPath,
      createdAt: DateTime.tryParse(rows[index]['created_at']?.toString() ?? ''),
    );
    rows[index] = updated.toJson()
      ..['created_at'] = updated.createdAt?.toIso8601String();
    await _writeList(_logsKey, rows);
    if (receiptPhoto != null && previousPhoto != photoPath) {
      await _deleteReceipt(previousPhoto);
    }
    final vehicles = await _readList(_vehiclesKey);
    final vehicleIndex = vehicles.indexWhere((row) => row['id'] == vehicleId);
    if (vehicleIndex >= 0) {
      final vehicle = Vehicle.fromJson(vehicles[vehicleIndex]);
      if (odometerKm > vehicle.currentOdometer) {
        vehicles[vehicleIndex] =
            vehicle.copyWith(currentOdometer: odometerKm).toJson();
        await _writeList(_vehiclesKey, vehicles);
      }
    }
  }

  static Future<void> deleteServiceLog(int serviceLogId) async {
    final rows = await _readList(_logsKey);
    final index = rows.indexWhere((row) => row['id'] == serviceLogId);
    if (index < 0) {
      throw StateError('Catatan servis tidak ditemukan di perangkat.');
    }
    final photoPath = rows[index]['receipt_photo_url'] as String?;
    rows.removeAt(index);
    await _writeList(_logsKey, rows);
    await _deleteReceipt(photoPath);
  }

  static Future<List<ComponentReminder>> getReminders(int vehicleId) async {
    final vehicles = await getVehicles(0);
    final vehicleIndex = vehicles.indexWhere((item) => item.id == vehicleId);
    if (vehicleIndex < 0) return [];
    final vehicle = vehicles[vehicleIndex];
    final logs = await getServiceLogs(vehicleId);
    final reminders = <ComponentReminder>[];

    for (final type in _serviceTypes) {
      final matching = logs.where((log) => log.serviceTypeId == type.id);
      if (matching.isEmpty) continue;
      final lastLog = matching.first;
      final dueKm = type.defaultKmInterval > 0
          ? lastLog.odometerKm + type.defaultKmInterval
          : null;
      final dueDate = type.defaultMonthInterval > 0
          ? _addMonths(lastLog.serviceDate, type.defaultMonthInterval)
          : null;
      final remainingKm =
          dueKm == null ? null : dueKm - vehicle.currentOdometer;
      final remainingDays = dueDate == null
          ? null
          : DateUtils.dateOnly(dueDate)
              .difference(DateUtils.dateOnly(DateTime.now()))
              .inDays;
      final overdue = (remainingKm != null && remainingKm <= 0) ||
          (remainingDays != null && remainingDays < 0);
      final near = (remainingKm != null &&
              remainingKm > 0 &&
              remainingKm <= 500) ||
          (remainingDays != null && remainingDays >= 0 && remainingDays <= 7);
      final color = overdue
          ? ReminderColorStatus.merah
          : near
              ? ReminderColorStatus.kuning
              : ReminderColorStatus.hijau;
      final progress = type.defaultKmInterval > 0 && dueKm != null
          ? ((vehicle.currentOdometer - (dueKm - type.defaultKmInterval)) /
                  type.defaultKmInterval)
              .clamp(0.0, 1.0)
          : 0.5;
      reminders.add(ComponentReminder(
        id: lastLog.id,
        vehicleId: vehicleId,
        serviceTypeId: type.id,
        serviceTypeName: type.name,
        serviceTypeIcon: type.icon,
        dueKm: dueKm,
        dueDate:
            dueDate == null ? null : DateFormat('yyyy-MM-dd').format(dueDate),
        remainingKm: remainingKm,
        remainingDays: remainingDays,
        statusColor: color,
        statusLabel: overdue
            ? 'Wajib Servis!'
            : near
                ? 'Mendekati Waktu Servis'
                : 'Aman',
        badgeColorHex: overdue
            ? '#EF4444'
            : near
                ? '#F59E0B'
                : '#10B981',
        progressPercentage: progress,
      ));
    }
    reminders.sort((a, b) => (a.dueKm ?? 0).compareTo(b.dueKm ?? 0));
    return reminders;
  }

  static Future<ExpenseSummary> getExpenses(int vehicleId) async {
    final logs = await getServiceLogs(vehicleId);
    final now = DateTime.now();
    final totals = <int, double>{};
    final counts = <int, int>{};
    double all = 0;
    double month = 0;
    double year = 0;
    for (final log in logs) {
      all += log.cost;
      if (log.serviceDate.year == now.year) {
        year += log.cost;
        if (log.serviceDate.month == now.month) month += log.cost;
      }
      totals.update(log.serviceTypeId, (value) => value + log.cost,
          ifAbsent: () => log.cost);
      counts.update(log.serviceTypeId, (value) => value + 1, ifAbsent: () => 1);
    }
    final categories = totals.entries.map((entry) {
      final type = _serviceTypes.firstWhere(
        (item) => item.id == entry.key,
        orElse: () => ServiceType(
          id: entry.key,
          name: 'Servis',
          defaultKmInterval: 0,
          defaultMonthInterval: 0,
        ),
      );
      return ExpenseCategory(
        name: type.name,
        icon: type.icon,
        cost: entry.value,
        count: counts[entry.key] ?? 0,
        percentage: all == 0 ? 0 : (entry.value / all) * 100,
      );
    }).toList()
      ..sort((a, b) => b.cost.compareTo(a.cost));

    final monthlyTotals = <DateTime, double>{};
    for (final log in logs) {
      final key = DateTime(log.serviceDate.year, log.serviceDate.month);
      monthlyTotals.update(key, (value) => value + log.cost,
          ifAbsent: () => log.cost);
    }
    final currentMonth = DateTime(now.year, now.month);
    final trends = List.generate(6, (index) {
      final offset = 5 - index;
      final key = DateTime(currentMonth.year, currentMonth.month - offset);
      return MonthlyExpenseTrend(
        monthKey: DateFormat('yyyy-MM').format(key),
        monthLabel: DateFormat('MMM yyyy').format(key),
        totalCost: monthlyTotals[key] ?? 0,
      );
    });
    final vehicles = await getVehicles(0);
    final vehicleIndex = vehicles.indexWhere((item) => item.id == vehicleId);
    final vehicle = vehicleIndex < 0 ? null : vehicles[vehicleIndex];
    return ExpenseSummary(
      totalAllTime: all,
      totalThisMonth: month,
      totalThisYear: year,
      serviceCount: logs.length,
      costPerKm: vehicle != null && vehicle.currentOdometer > 0
          ? double.parse((all / vehicle.currentOdometer).toStringAsFixed(2))
          : 0,
      categoryBreakdown: categories,
      monthlyTrends: trends,
    );
  }

  static DateTime _addMonths(DateTime date, int months) {
    final monthIndex = date.month - 1 + months;
    final year = date.year + monthIndex ~/ 12;
    final month = monthIndex % 12 + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, date.day > lastDay ? lastDay : date.day);
  }

  static Future<String> _saveReceipt(int logId, XFile photo) async {
    final directory = await getApplicationDocumentsDirectory();
    final receiptDirectory =
        Directory('${directory.path}${Platform.pathSeparator}autolog_receipts');
    await receiptDirectory.create(recursive: true);
    final extension = photo.name.contains('.')
        ? photo.name.substring(photo.name.lastIndexOf('.'))
        : '.jpg';
    final path =
        '${receiptDirectory.path}${Platform.pathSeparator}receipt_${logId}_${DateTime.now().microsecondsSinceEpoch}$extension';
    await File(path).writeAsBytes(await photo.readAsBytes(), flush: true);
    return path;
  }

  static Future<void> _deleteReceipt(String? path) async {
    if (path == null || path.isEmpty) return;
    final file = File(path);
    if (await file.exists()) await file.delete();
  }
}
