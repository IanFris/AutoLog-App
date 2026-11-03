import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/service_type.dart';
import '../models/service_log.dart';
import '../models/component_reminder.dart';
import '../models/expense_summary.dart';
import '../services/api_service.dart';
import '../services/guest_data_service.dart';
import '../services/session_service.dart';

class ServiceProvider extends ChangeNotifier {
  List<ServiceType> _serviceTypes = [];
  List<ServiceLog> _serviceLogs = [];
  List<ComponentReminder> _reminders = [];
  ExpenseSummary? _expenses;

  bool _isLoading = false;
  String? _errorMessage;
  int _requestId = 0;
  int? _vehicleId;
  bool _isGuest = false;

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
      _isGuest = await SessionService.isGuest();
      _serviceTypes = _isGuest
          ? await GuestDataService.getServiceTypes()
          : await ApiService.getServiceTypes();
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> fetchVehicleData(int vehicleId) async {
    final requestId = ++_requestId;
    _isGuest = await SessionService.isGuest();
    if (_vehicleId != vehicleId) {
      _vehicleId = vehicleId;
      _serviceLogs = [];
      _reminders = [];
      _expenses = null;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_isGuest) {
        _serviceTypes = await GuestDataService.getServiceTypes();
      } else if (_serviceTypes.isEmpty) {
        _serviceTypes = await ApiService.getServiceTypes();
      }

      final results = await Future.wait<Object>([
        _isGuest
            ? GuestDataService.getServiceLogs(vehicleId)
            : ApiService.getServiceLogs(vehicleId),
        _isGuest
            ? GuestDataService.getReminders(vehicleId)
            : ApiService.getReminders(vehicleId),
        _isGuest
            ? GuestDataService.getExpenses(vehicleId)
            : ApiService.getExpenses(vehicleId),
      ]);

      if (requestId != _requestId) return;
      _serviceLogs = results[0] as List<ServiceLog>;
      _reminders = results[1] as List<ComponentReminder>;
      _expenses = results[2] as ExpenseSummary;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      if (requestId != _requestId) return;
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void reset() {
    _requestId++;
    _vehicleId = null;
    _isGuest = false;
    _serviceTypes = [];
    _serviceLogs = [];
    _reminders = [];
    _expenses = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
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
    final requestId = _requestId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_isGuest) {
        await GuestDataService.createServiceLog(
          vehicleId: vehicleId,
          serviceTypeId: serviceTypeId,
          serviceDate: serviceDate,
          odometerKm: odometerKm,
          cost: cost,
          workshopName: workshopName,
          notes: notes,
          receiptPhoto: receiptPhoto,
        );
      } else {
        await ApiService.createServiceLog(
          vehicleId: vehicleId,
          serviceTypeId: serviceTypeId,
          serviceDate: serviceDate,
          odometerKm: odometerKm,
          cost: cost,
          workshopName: workshopName,
          notes: notes,
          receiptPhoto: receiptPhoto,
        );
      }

      if (_vehicleId == vehicleId) {
        await fetchVehicleData(vehicleId);
      } else if (requestId == _requestId) {
        _isLoading = false;
        notifyListeners();
      }
      return true;
    } catch (e) {
      if (requestId != _requestId) return false;
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateServiceLog({
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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_isGuest) {
        await GuestDataService.updateServiceLog(
          serviceLogId: serviceLogId,
          vehicleId: vehicleId,
          serviceTypeId: serviceTypeId,
          serviceDate: serviceDate,
          odometerKm: odometerKm,
          cost: cost,
          workshopName: workshopName,
          notes: notes,
          receiptPhoto: receiptPhoto,
        );
      } else {
        await ApiService.updateServiceLog(
          serviceLogId: serviceLogId,
          vehicleId: vehicleId,
          serviceTypeId: serviceTypeId,
          serviceDate: serviceDate,
          odometerKm: odometerKm,
          cost: cost,
          workshopName: workshopName,
          notes: notes,
          receiptPhoto: receiptPhoto,
        );
      }

      if (_vehicleId == vehicleId) {
        await fetchVehicleData(vehicleId);
      }
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteServiceLog(int serviceLogId,
      {required int vehicleId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_isGuest) {
        await GuestDataService.deleteServiceLog(serviceLogId);
      } else {
        await ApiService.deleteServiceLog(serviceLogId);
      }
      if (_vehicleId == vehicleId) {
        await fetchVehicleData(vehicleId);
      }
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
