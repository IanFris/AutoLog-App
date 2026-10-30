import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/service_type.dart';
import '../models/service_log.dart';
import '../models/component_reminder.dart';
import '../models/expense_summary.dart';
import '../services/api_service.dart';

class ServiceProvider extends ChangeNotifier {
  List<ServiceType> _serviceTypes = [];
  List<ServiceLog> _serviceLogs = [];
  List<ComponentReminder> _reminders = [];
  ExpenseSummary? _expenses;

  bool _isLoading = false;
  String? _errorMessage;

  List<ServiceType> get serviceTypes => _serviceTypes;
  List<ServiceLog> get serviceLogs => _serviceLogs;
  List<ComponentReminder> get reminders => _reminders;
  ExpenseSummary? get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<ComponentReminder> get urgentReminders => _reminders
      .where((r) =>
          r.statusColor == ReminderColorStatus.merah ||
          r.statusColor == ReminderColorStatus.kuning)
      .toList();

  Future<void> fetchServiceTypes() async {
    try {
      _serviceTypes = await ApiService.getServiceTypes();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchVehicleData(int vehicleId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_serviceTypes.isEmpty) {
        _serviceTypes = await ApiService.getServiceTypes();
      }

      final results = await Future.wait([
        ApiService.getServiceLogs(vehicleId),
        ApiService.getReminders(vehicleId),
        ApiService.getExpenses(vehicleId),
      ]);

      _serviceLogs = results[0] as List<ServiceLog>;
      _reminders = results[1] as List<ComponentReminder>;
      _expenses = results[2] as ExpenseSummary;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> addServiceLog({
    required int vehicleId,
    required int serviceTypeId,
    required String serviceDate,
    required int odometerKm,
    required double cost,
    String? workshopName,
    String? notes,
    XFile? receiptPhoto,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newLog = await ApiService.createServiceLog(
        vehicleId: vehicleId,
        serviceTypeId: serviceTypeId,
        serviceDate: serviceDate,
        odometerKm: odometerKm,
        cost: cost,
        workshopName: workshopName,
        notes: notes,
        receiptPhoto: receiptPhoto,
      );

      _serviceLogs.insert(0, newLog);

      // Refresh reminders and expenses
      await Future.wait([
        ApiService.getReminders(vehicleId).then((r) => _reminders = r),
        ApiService.getExpenses(vehicleId).then((e) => _expenses = e),
      ]);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}

