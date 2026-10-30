import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../models/maintenance_record.dart';
import '../models/fuel_record.dart';
import '../models/service_reminder.dart';
import '../services/storage_service.dart';

class AutoLogProvider extends ChangeNotifier {
  final StorageService _storage;

  List<Vehicle> _vehicles = [];
  String? _activeVehicleId;
  List<MaintenanceRecord> _maintenanceRecords = [];
  List<FuelRecord> _fuelRecords = [];
  List<ServiceReminder> _reminders = [];
  bool _isDarkMode = false;
  bool _isLoading = true;

  AutoLogProvider(this._storage) {
    _loadData();
  }

  bool get isLoading => _isLoading;
  bool get isDarkMode => _isDarkMode;
  List<Vehicle> get vehicles => List.unmodifiable(_vehicles);
  List<MaintenanceRecord> get maintenanceRecords =>
      List.unmodifiable(_maintenanceRecords);
  List<FuelRecord> get fuelRecords => List.unmodifiable(_fuelRecords);
  List<ServiceReminder> get reminders => List.unmodifiable(_reminders);

  Vehicle? get activeVehicle {
    if (_vehicles.isEmpty) return null;
    return _vehicles.firstWhere(
      (v) => v.id == _activeVehicleId,
      orElse: () => _vehicles.first,
    );
  }

  void _loadData() {
    _vehicles = _storage.getVehicles();
    _activeVehicleId = _storage.getActiveVehicleId();
    if (_vehicles.isNotEmpty &&
        (_activeVehicleId == null ||
            !_vehicles.any((v) => v.id == _activeVehicleId))) {
      _activeVehicleId = _vehicles.first.id;
    }
    _maintenanceRecords = _storage.getMaintenanceRecords();
    _fuelRecords = _storage.getFuelRecords();
    _reminders = _storage.getReminders();
    _isDarkMode = _storage.isDarkMode;
    _isLoading = false;
    notifyListeners();
  }

  // Active Vehicle Filtered Lists
  List<MaintenanceRecord> get activeVehicleRecords {
    if (activeVehicle == null) return [];
    final list = _maintenanceRecords
        .where((r) => r.vehicleId == activeVehicle!.id)
        .toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  List<FuelRecord> get activeVehicleFuel {
    if (activeVehicle == null) return [];
    final list = _fuelRecords
        .where((f) => f.vehicleId == activeVehicle!.id)
        .toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  List<ServiceReminder> get activeVehicleReminders {
    if (activeVehicle == null) return [];
    final list = _reminders
        .where((r) => r.vehicleId == activeVehicle!.id && r.isActive)
        .toList();
    final curOdo = activeVehicle!.currentOdometer;

    // Sort: terlewat first, then mendekati, then aman
    list.sort((a, b) {
      final statusA = a.getStatus(curOdo);
      final statusB = b.getStatus(curOdo);
      if (statusA == statusB) {
        final remA = a.getRemainingKm(curOdo) ?? 999999;
        final remB = b.getRemainingKm(curOdo) ?? 999999;
        return remA.compareTo(remB);
      }
      if (statusA == ReminderStatus.terlewat) return -1;
      if (statusB == ReminderStatus.terlewat) return 1;
      if (statusA == ReminderStatus.mendekati) return -1;
      if (statusB == ReminderStatus.mendekati) return 1;
      return 0;
    });

    return list;
  }

  List<ServiceReminder> get activeVehicleDueReminders {
    if (activeVehicle == null) return [];
    final curOdo = activeVehicle!.currentOdometer;
    return activeVehicleReminders.where((r) {
      final status = r.getStatus(curOdo);
      return status == ReminderStatus.terlewat ||
          status == ReminderStatus.mendekati;
    }).toList();
  }

  // Analytics & Statistics
  double get totalMaintenanceCostAllTime {
    return activeVehicleRecords.fold(0.0, (sum, r) => sum + r.cost);
  }

  double get totalMaintenanceCostThisMonth {
    final now = DateTime.now();
    return activeVehicleRecords
        .where((r) => r.date.year == now.year && r.date.month == now.month)
        .fold(0.0, (sum, r) => sum + r.cost);
  }

  double get totalMaintenanceCostThisYear {
    final now = DateTime.now();
    return activeVehicleRecords
        .where((r) => r.date.year == now.year)
        .fold(0.0, (sum, r) => sum + r.cost);
  }

  double get totalFuelCostAllTime {
    return activeVehicleFuel.fold(0.0, (sum, f) => sum + f.totalCost);
  }

  Map<String, double> get categoryCostBreakdown {
    final map = <String, double>{};
    for (final record in activeVehicleRecords) {
      final label = record.category.label;
      map[label] = (map[label] ?? 0.0) + record.cost;
    }
    return map;
  }

  Map<String, double> get monthlyExpenseTrends {
    final map = <String, double>{};
    final now = DateTime.now();

    // Last 6 months
    for (int i = 5; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final key = '${monthDate.month}/${monthDate.year}';
      map[key] = 0.0;
    }

    for (final record in activeVehicleRecords) {
      final key = '${record.date.month}/${record.date.year}';
      if (map.containsKey(key)) {
        map[key] = (map[key] ?? 0.0) + record.cost;
      }
    }
    return map;
  }

  double get averageFuelEfficiency {
    final logs = activeVehicleFuel;
    if (logs.length < 2) return 0.0;
    // Calculate difference between oldest and newest odometer divided by total liters (excluding first)
    final sortedByOdo = List<FuelRecord>.from(logs)
      ..sort((a, b) => a.odometer.compareTo(b.odometer));
    final totalDistance =
        sortedByOdo.last.odometer - sortedByOdo.first.odometer;
    final totalLiters =
        sortedByOdo.skip(1).fold(0.0, (sum, f) => sum + f.liters);
    if (totalLiters <= 0 || totalDistance <= 0) return 0.0;
    return totalDistance / totalLiters;
  }

  // --- ACTIONS ---

  void setActiveVehicle(String id) {
    if (_vehicles.any((v) => v.id == id)) {
      _activeVehicleId = id;
      _storage.setActiveVehicleId(id);
      notifyListeners();
    }
  }

  Future<void> addVehicle(Vehicle vehicle) async {
    _vehicles.add(vehicle);
    _activeVehicleId = vehicle.id;
    await _storage.saveVehicles(_vehicles);
    await _storage.setActiveVehicleId(vehicle.id);
    notifyListeners();
  }

  Future<void> updateVehicle(Vehicle vehicle) async {
    final idx = _vehicles.indexWhere((v) => v.id == vehicle.id);
    if (idx != -1) {
      _vehicles[idx] = vehicle;
      await _storage.saveVehicles(_vehicles);
      notifyListeners();
    }
  }

  Future<void> deleteVehicle(String id) async {
    _vehicles.removeWhere((v) => v.id == id);
    _maintenanceRecords.removeWhere((r) => r.vehicleId == id);
    _fuelRecords.removeWhere((f) => f.vehicleId == id);
    _reminders.removeWhere((r) => r.vehicleId == id);

    if (_activeVehicleId == id) {
      _activeVehicleId = _vehicles.isNotEmpty ? _vehicles.first.id : null;
    }

    await _storage.saveVehicles(_vehicles);
    await _storage.saveMaintenanceRecords(_maintenanceRecords);
    await _storage.saveFuelRecords(_fuelRecords);
    await _storage.saveReminders(_reminders);
    if (_activeVehicleId != null) {
      await _storage.setActiveVehicleId(_activeVehicleId!);
    }
    notifyListeners();
  }

  Future<void> updateOdometer(String vehicleId, int newOdometer) async {
    final idx = _vehicles.indexWhere((v) => v.id == vehicleId);
    if (idx != -1) {
      _vehicles[idx] =
          _vehicles[idx].copyWith(currentOdometer: newOdometer);
      await _storage.saveVehicles(_vehicles);
      notifyListeners();
    }
  }

  Future<void> addMaintenanceRecord(
    MaintenanceRecord record, {
    bool createNextReminder = false,
    int? intervalKm,
    int? intervalMonths,
  }) async {
    _maintenanceRecords.add(record);

    // Auto-update vehicle odometer if record's odometer is higher
    if (activeVehicle != null && record.odometer > activeVehicle!.currentOdometer) {
      await updateOdometer(record.vehicleId, record.odometer);
    }

    // Auto-create next reminder if requested
    if (createNextReminder) {
      final targetKm = intervalKm != null && intervalKm > 0
          ? record.odometer + intervalKm
          : null;
      final targetDate = intervalMonths != null && intervalMonths > 0
          ? DateTime(
              record.date.year,
              record.date.month + intervalMonths,
              record.date.day,
            )
          : null;

      final reminder = ServiceReminder(
        id: 'rem_${DateTime.now().millisecondsSinceEpoch}',
        vehicleId: record.vehicleId,
        title: '${record.category.label} Berikutnya',
        categoryKey: record.categoryKey,
        targetOdometer: targetKm,
        targetDate: targetDate,
        lastServiceOdometer: record.odometer,
        lastServiceDate: record.date,
        notes: 'Dibuat otomatis dari catatan servis tanggal ${record.date.day}/${record.date.month}/${record.date.year}',
      );
      _reminders.add(reminder);
      await _storage.saveReminders(_reminders);
    }

    await _storage.saveMaintenanceRecords(_maintenanceRecords);
    notifyListeners();
  }

  Future<void> updateMaintenanceRecord(MaintenanceRecord record) async {
    final idx = _maintenanceRecords.indexWhere((r) => r.id == record.id);
    if (idx != -1) {
      _maintenanceRecords[idx] = record;
      await _storage.saveMaintenanceRecords(_maintenanceRecords);
      notifyListeners();
    }
  }

  Future<void> deleteMaintenanceRecord(String id) async {
    _maintenanceRecords.removeWhere((r) => r.id == id);
    await _storage.saveMaintenanceRecords(_maintenanceRecords);
    notifyListeners();
  }

  Future<void> addFuelRecord(FuelRecord record) async {
    _fuelRecords.add(record);
    if (activeVehicle != null && record.odometer > activeVehicle!.currentOdometer) {
      await updateOdometer(record.vehicleId, record.odometer);
    }
    await _storage.saveFuelRecords(_fuelRecords);
    notifyListeners();
  }

  Future<void> deleteFuelRecord(String id) async {
    _fuelRecords.removeWhere((f) => f.id == id);
    await _storage.saveFuelRecords(_fuelRecords);
    notifyListeners();
  }

  Future<void> addReminder(ServiceReminder reminder) async {
    _reminders.add(reminder);
    await _storage.saveReminders(_reminders);
    notifyListeners();
  }

  Future<void> updateReminder(ServiceReminder reminder) async {
    final idx = _reminders.indexWhere((r) => r.id == reminder.id);
    if (idx != -1) {
      _reminders[idx] = reminder;
      await _storage.saveReminders(_reminders);
      notifyListeners();
    }
  }

  Future<void> deleteReminder(String id) async {
    _reminders.removeWhere((r) => r.id == id);
    await _storage.saveReminders(_reminders);
    notifyListeners();
  }

  Future<void> completeReminder(
    String reminderId, {
    MaintenanceRecord? newServiceRecord,
  }) async {
    final idx = _reminders.indexWhere((r) => r.id == reminderId);
    if (idx != -1) {
      _reminders[idx] = _reminders[idx].copyWith(isActive: false);
      await _storage.saveReminders(_reminders);

      if (newServiceRecord != null) {
        await addMaintenanceRecord(newServiceRecord);
      } else {
        notifyListeners();
      }
    }
  }

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    await _storage.setDarkMode(_isDarkMode);
    notifyListeners();
  }

  Future<void> resetToMockData() async {
    _isLoading = true;
    notifyListeners();
    await _storage.clearAll();
    await _storage.seedInitialData();
    _loadData();
  }

  Future<void> clearAllData() async {
    _isLoading = true;
    notifyListeners();
    await _storage.clearAll();
    _vehicles = [];
    _activeVehicleId = null;
    _maintenanceRecords = [];
    _fuelRecords = [];
    _reminders = [];
    _isLoading = false;
    notifyListeners();
  }

  String exportBackup() => _storage.exportBackupJson();

  Future<bool> importBackup(String jsonStr) async {
    final success = await _storage.importBackupJson(jsonStr);
    if (success) {
      _loadData();
    }
    return success;
  }
}
