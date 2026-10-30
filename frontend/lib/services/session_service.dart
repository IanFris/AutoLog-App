import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class SessionService {
  static const String _keyUser = 'autolog_current_user';
  static const String _keyActiveVehicleId = 'autolog_active_vehicle_id';

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
  }

  static Future<void> saveActiveVehicleId(int vehicleId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyActiveVehicleId, vehicleId);
  }

  static Future<int?> getActiveVehicleId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyActiveVehicleId);
  }
}
