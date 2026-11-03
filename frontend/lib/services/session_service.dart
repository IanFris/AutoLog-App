import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class SessionService {
  static const String _keyUser = 'autolog_current_user';
  static const String _keyActiveVehicleId = 'autolog_active_vehicle_id';
  static const String _keyGuestActiveVehicleId =
      'autolog_guest_active_vehicle_id';

  static Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUser, jsonEncode(user.toJson()));
  }

  static Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keyUser);
    if (str == null) return null;
    try {
      return User.fromJson(jsonDecode(str));
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUser);
    await prefs.remove(_keyActiveVehicleId);
    await prefs.remove(_keyGuestActiveVehicleId);
  }

  static Future<bool> isGuest() async => (await getUser())?.isGuest ?? false;

  static Future<void> saveActiveVehicleId(int vehicleId,
      {bool guest = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        guest ? _keyGuestActiveVehicleId : _keyActiveVehicleId, vehicleId);
  }

  static Future<void> clearActiveVehicleId({bool guest = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(guest ? _keyGuestActiveVehicleId : _keyActiveVehicleId);
  }

  static Future<int?> getActiveVehicleId({bool guest = false}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(guest ? _keyGuestActiveVehicleId : _keyActiveVehicleId);
  }
}
