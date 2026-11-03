import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../services/api_service.dart';
import '../services/guest_data_service.dart';
import '../services/session_service.dart';

class VehicleProvider extends ChangeNotifier {
  List<Vehicle> _vehicles = [];
  Vehicle? _activeVehicle;
  bool _isLoading = false;
  String? _errorMessage;
  int _requestId = 0;
  int? _userId;
  bool _isGuest = false;

  List<Vehicle> get vehicles => _vehicles;
  Vehicle? get activeVehicle => _activeVehicle;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchVehicles(int userId) async {
    final requestId = ++_requestId;
    _isGuest = await SessionService.isGuest();
    if (_userId != userId) {
      _userId = userId;
      _vehicles = [];
      _activeVehicle = null;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final vehicles = _isGuest
          ? await GuestDataService.getVehicles(userId)
          : await ApiService.getVehicles(userId);
      if (requestId != _requestId) return;

      _vehicles = vehicles;
      final savedActiveId =
          await SessionService.getActiveVehicleId(guest: _isGuest);
      if (requestId != _requestId) return;

      if (_vehicles.isNotEmpty) {
        if (savedActiveId != null &&
            _vehicles.any((v) => v.id == savedActiveId)) {
          _activeVehicle = _vehicles.firstWhere((v) => v.id == savedActiveId);
        } else {
          _activeVehicle = _vehicles.first;
          await SessionService.saveActiveVehicleId(_activeVehicle!.id,
              guest: _isGuest);
          if (requestId != _requestId) return;
        }
      } else {
        _activeVehicle = null;
      }

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
    _userId = null;
    _isGuest = false;
    _vehicles = [];
    _activeVehicle = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  void setActiveVehicle(Vehicle vehicle) {
    _activeVehicle = vehicle;
    SessionService.saveActiveVehicleId(vehicle.id, guest: _isGuest);
    notifyListeners();
  }

  Future<bool> addVehicle({
    required int userId,
    required String type,
    required String brandModel,
    required String licensePlate,
    required int currentOdometer,
  }) async {
    _userId ??= userId;
    if (_userId != userId) return false;
    var requestId = _requestId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newVehicle = _isGuest
          ? await GuestDataService.createVehicle(
              userId: userId,
              type: type,
              brandModel: brandModel,
              licensePlate: licensePlate,
              currentOdometer: currentOdometer,
            )
          : await ApiService.createVehicle(
              userId: userId,
              type: type,
              brandModel: brandModel,
              licensePlate: licensePlate,
              currentOdometer: currentOdometer,
            );

      if (_userId != userId) return true;
      requestId = ++_requestId;
      _vehicles.insert(0, newVehicle);
      _activeVehicle = newVehicle;
      await SessionService.saveActiveVehicleId(newVehicle.id, guest: _isGuest);

      if (requestId != _requestId) return true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      if (requestId != _requestId) return false;
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateOdometer(int newOdometer) async {
    if (_activeVehicle == null) return false;
    final vehicle = _activeVehicle!;
    final requestId = _requestId;
    _errorMessage = null;

    try {
      if (_isGuest) {
        await GuestDataService.updateOdometer(vehicle.id, newOdometer);
      } else {
        await ApiService.updateOdometer(vehicle.id, newOdometer);
      }
      if (requestId != _requestId) return true;
      final updated = vehicle.copyWith(currentOdometer: newOdometer);
      if (_activeVehicle?.id == vehicle.id) {
        _activeVehicle = updated;
      }

      final index = _vehicles.indexWhere((v) => v.id == updated.id);
      if (index != -1) {
        _vehicles[index] = updated;
      }

      notifyListeners();
      return true;
    } catch (e) {
      if (requestId != _requestId) return false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateVehicle({
    required int vehicleId,
    String? type,
    String? brandModel,
    String? licensePlate,
    int? currentOdometer,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_isGuest) {
        await GuestDataService.updateVehicle(
          vehicleId: vehicleId,
          type: type,
          brandModel: brandModel,
          licensePlate: licensePlate,
          currentOdometer: currentOdometer,
        );
      } else {
        await ApiService.updateVehicle(
          vehicleId: vehicleId,
          type: type,
          brandModel: brandModel,
          licensePlate: licensePlate,
          currentOdometer: currentOdometer,
        );
      }

      final index = _vehicles.indexWhere((v) => v.id == vehicleId);
      final updatedVehicle = (index >= 0)
          ? _vehicles[index].copyWith(
              type: type != null
                  ? (type == 'mobil' ? VehicleType.mobil : VehicleType.motor)
                  : _vehicles[index].type,
              brandModel: brandModel ?? _vehicles[index].brandModel,
              licensePlate: licensePlate ?? _vehicles[index].licensePlate,
              currentOdometer:
                  currentOdometer ?? _vehicles[index].currentOdometer,
            )
          : _activeVehicle;

      if (updatedVehicle != null) {
        if (_activeVehicle?.id == vehicleId) {
          _activeVehicle = updatedVehicle;
        }
        if (index >= 0) {
          _vehicles[index] = updatedVehicle;
        }
      }

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

  Future<bool> deleteVehicle(int vehicleId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_isGuest) {
        await GuestDataService.deleteVehicle(vehicleId);
      } else {
        await ApiService.deleteVehicle(vehicleId);
      }

      _vehicles.removeWhere((v) => v.id == vehicleId);
      if (_activeVehicle?.id == vehicleId) {
        _activeVehicle = _vehicles.isNotEmpty ? _vehicles.first : null;
        if (_activeVehicle != null) {
          await SessionService.saveActiveVehicleId(_activeVehicle!.id,
              guest: _isGuest);
        } else {
          await SessionService.clearActiveVehicleId(guest: _isGuest);
        }
      }

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
