import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/api_constants.dart';

class SettingsProvider extends ChangeNotifier {
  static const _themeModeKey = 'autolog_theme_mode';
  static const _apiBaseUrlKey = 'autolog_api_base_url';

  ThemeMode _themeMode = ThemeMode.system;
  bool _isInitialized = false;
  String? _errorMessage;

  ThemeMode get themeMode => _themeMode;
  bool get isInitialized => _isInitialized;
  String get apiBaseUrl => ApiConstants.baseUrl;
  String? get errorMessage => _errorMessage;

  SettingsProvider() {
    load();
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeModeKey);
      _themeMode = switch (savedTheme) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

      final savedBaseUrl = prefs.getString(_apiBaseUrlKey);
      if (savedBaseUrl != null) {
        ApiConstants.setCustomBaseUrl(savedBaseUrl);
      }
    } catch (e) {
      _errorMessage = 'Gagal memuat pengaturan: $e';
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<bool> setThemeMode(ThemeMode mode) async {
    _errorMessage = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };
      if (!await prefs.setString(_themeModeKey, saved)) {
        throw StateError('Preferensi tema tidak dapat disimpan.');
      }
      _themeMode = mode;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menyimpan tema: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> setApiBaseUrl(String value) async {
    final normalized = value.trim().replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.tryParse(normalized);
    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty ||
        uri.query.isNotEmpty ||
        uri.fragment.isNotEmpty) {
      _errorMessage = 'Masukkan URL server HTTP/HTTPS yang valid.';
      notifyListeners();
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setString(_apiBaseUrlKey, normalized)) {
        throw StateError('URL server tidak dapat disimpan.');
      }
      ApiConstants.setCustomBaseUrl(normalized);
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menyimpan URL server: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetApiBaseUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.remove(_apiBaseUrlKey)) {
        throw StateError('URL server tidak dapat direset.');
      }
      ApiConstants.setCustomBaseUrl('');
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal mereset URL server: $e';
      notifyListeners();
      return false;
    }
  }
}
