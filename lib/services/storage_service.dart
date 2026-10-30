import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vehicle.dart';
import '../models/maintenance_record.dart';
import '../models/fuel_record.dart';
import '../models/service_reminder.dart';
import 'mock_data.dart';

class StorageService {
  static const String _keyVehicles = 'autolog_vehicles';
  static const String _keyMaintenance = 'autolog_maintenance';
  static const String _keyFuel = 'autolog_fuel';
  static const String _keyReminders = 'autolog_reminders';
  static const String _keyActiveVehicleId = 'autolog_active_vehicle_id';
  static const String _keyDarkMode = 'autolog_dark_mode';
  static const String _keyInitialized = 'autolog_is_initialized';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    final service = StorageService(prefs);
    if (!service.isInitialized) {
      await service.seedInitialData();
    }
    return service;
  }

  bool get isInitialized => _prefs.getBool(_keyInitialized) ?? false;

  Future<void> seedInitialData() async {
    await saveVehicles(MockData.vehicles);
    await saveMaintenanceRecords(MockData.maintenanceRecords);
    await saveFuelRecords(MockData.fuelRecords);
    await saveReminders(MockData.serviceReminders);
    await setActiveVehicleId(MockData.vehicles.first.id);
    await _prefs.setBool(_keyInitialized, true);
  }

  // Vehicles
  List<Vehicle> getVehicles() {
    final jsonStr = _prefs.getString(_keyVehicles);
    if (jsonStr == null) return [];
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((item) => Vehicle.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> saveVehicles(List<Vehicle> vehicles) {
    final jsonStr = jsonEncode(vehicles.map((v) => v.toJson()).toList());
    return _prefs.setString(_keyVehicles, jsonStr);
  }

  // Active Vehicle ID
  String? getActiveVehicleId() {
    return _prefs.getString(_keyActiveVehicleId);
  }

  Future<bool> setActiveVehicleId(String id) {
    return _prefs.setString(_keyActiveVehicleId, id);
  }

  // Maintenance Records
  List<MaintenanceRecord> getMaintenanceRecords() {
    final jsonStr = _prefs.getString(_keyMaintenance);
    if (jsonStr == null) return [];
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((item) => MaintenanceRecord.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> saveMaintenanceRecords(List<MaintenanceRecord> records) {
    final jsonStr = jsonEncode(records.map((r) => r.toJson()).toList());
    return _prefs.setString(_keyMaintenance, jsonStr);
  }

  // Fuel Records
  List<FuelRecord> getFuelRecords() {
    final jsonStr = _prefs.getString(_keyFuel);
    if (jsonStr == null) return [];
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((item) => FuelRecord.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> saveFuelRecords(List<FuelRecord> records) {
    final jsonStr = jsonEncode(records.map((r) => r.toJson()).toList());
    return _prefs.setString(_keyFuel, jsonStr);
  }

  // Reminders
  List<ServiceReminder> getReminders() {
    final jsonStr = _prefs.getString(_keyReminders);
    if (jsonStr == null) return [];
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((item) => ServiceReminder.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> saveReminders(List<ServiceReminder> reminders) {
    final jsonStr = jsonEncode(reminders.map((r) => r.toJson()).toList());
    return _prefs.setString(_keyReminders, jsonStr);
  }

  // Theme
  bool get isDarkMode => _prefs.getBool(_keyDarkMode) ?? false;

  Future<bool> setDarkMode(bool value) {
    return _prefs.setBool(_keyDarkMode, value);
  }

  // Full Backup Export
  String exportBackupJson() {
    final data = {
      'vehicles': getVehicles().map((v) => v.toJson()).toList(),
      'maintenance': getMaintenanceRecords().map((m) => m.toJson()).toList(),
      'fuel': getFuelRecords().map((f) => f.toJson()).toList(),
      'reminders': getReminders().map((r) => r.toJson()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
      'app': 'AutoLog',
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  // Full Backup Import
  Future<bool> importBackupJson(String jsonStr) async {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonStr);
      if (data.containsKey('vehicles')) {
        final List<dynamic> vList = data['vehicles'];
        await saveVehicles(vList.map((e) => Vehicle.fromJson(e)).toList());
      }
      if (data.containsKey('maintenance')) {
        final List<dynamic> mList = data['maintenance'];
        await saveMaintenanceRecords(
            mList.map((e) => MaintenanceRecord.fromJson(e)).toList());
      }
      if (data.containsKey('fuel')) {
        final List<dynamic> fList = data['fuel'];
        await saveFuelRecords(fList.map((e) => FuelRecord.fromJson(e)).toList());
      }
      if (data.containsKey('reminders')) {
        final List<dynamic> rList = data['reminders'];
        await saveReminders(
            rList.map((e) => ServiceReminder.fromJson(e)).toList());
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  // Reset all data
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}

