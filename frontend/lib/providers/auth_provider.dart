import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _loadSession();
  }

  Future<void> _loadSession() async {
    final user = await SessionService.getUser();
    if (user == null || user.token == null || user.token!.isEmpty) {
      await SessionService.clearUser();
      _currentUser = null;
    } else {
      _currentUser = user;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await ApiService.login(email, password);
      _currentUser = user;
      await SessionService.saveUser(user);
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

  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await ApiService.register(name, email, password);
      _currentUser = user;
      await SessionService.saveUser(user);
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

  Future<void> logout() async {
    final token = _currentUser?.token;
    _currentUser = null;
    await SessionService.clearUser();
    notifyListeners();

    if (token == null || token.isEmpty) return;

    try {
      await ApiService.logout(token);
      _errorMessage = null;
    } catch (e) {
      _errorMessage =
          'Sesi lokal sudah dihapus, tetapi server belum mengonfirmasi logout.';
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
