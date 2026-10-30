import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';

class VehicleProvider extends ChangeNotifier {
  List<Vehicle> _vehicles = [];
  Vehicle? _activeVehicle;
  bool _isLoading = false;
  String? _errorMessage;

  List<Vehicle> get vehicles => _vehicles;
  Vehicle? get activeVehicle => _activeVehicle;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchVehicles(int userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _vehicles = await ApiService.getVehicles(userId);
      final savedActiveId = await SessionService.getActiveVehicleId();

      if (_vehicles.isNotEmpty) {
        if (savedActiveId != null && _vehicles.any((v) => v.id == savedActiveId)) {
          _activeVehicle = _vehicles.firstWhere((v) => v.id == savedActiveId);
        } else {
          _activeVehicle = _vehicles.first;
          await SessionService.saveActiveVehicleId(_activeVehicle!.id);
        }
      } else {
        _activeVehicle = null;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void setActiveVehicle(Vehicle vehicle) {
    _activeVehicle = vehicle;
    SessionService.saveActiveVehicleId(vehicle.id);
    notifyListeners();
  }

  Future<bool> addVehicle({
    required int userId,
    required String type,
    required String brandModel,
    required String licensePlate,
    required int currentOdometer,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newVehicle = await ApiService.createVehicle(
        userId: userId,
        type: type,
        brandModel: brandModel,
        licensePlate: licensePlate,
        currentOdometer: currentOdometer,
      );

      _vehicles.insert(0, newVehicle);
      _activeVehicle = newVehicle;
      await SessionService.saveActiveVehicleId(newVehicle.id);

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

  Future<bool> updateOdometer(int newOdometer) async {
    if (_activeVehicle == null) return false;

    try {
      await ApiService.updateOdometer(_activeVehicle!.id, newOdometer);
      final updated = _activeVehicle!.copyWith(currentOdometer: newOdometer);
      _activeVehicle = updated;

      final index = _vehicles.indexWhere((v) => v.id == updated.id);
      if (index != -1) {
        _vehicles[index] = updated;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
