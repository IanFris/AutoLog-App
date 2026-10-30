import 'package:flutter/foundation.dart';

class ApiConstants {
  // Base URL default otomatis sesuai platform:
  // - Web / Windows Desktop: http://localhost/autolog/api
  // - Android Emulator: http://10.0.2.2/autolog/api
  // - HP Fisik Android: ganti ke IP Wi-Fi lokal, misal http://192.168.1.10/autolog/api
  static String _customBaseUrl = '';

  static String get baseUrl {
    if (_customBaseUrl.isNotEmpty) return _customBaseUrl;

    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
      return 'http://localhost/autolog/api';
    } else {
      // Android Emulator loopback
      return 'http://10.0.2.2/autolog/api';
    }
  }

  static void setCustomBaseUrl(String url) {
    _customBaseUrl = url.trim().replaceAll(RegExp(r'/$'), '');
  }

  // Endpoints
  static String get login => '$baseUrl/auth/login.php';
  static String get register => '$baseUrl/auth/register.php';
  static String get vehicles => '$baseUrl/vehicles/index.php';
  static String get serviceTypes => '$baseUrl/service_types/index.php';
  static String get serviceLogs => '$baseUrl/service_logs/index.php';
  static String get reminders => '$baseUrl/dashboard/reminders.php';
  static String get expenses => '$baseUrl/dashboard/expenses.php';

  // Base URL untuk akses file foto nota uploads
  static String get uploadsBaseUrl {
    final parent = baseUrl.replaceAll(RegExp(r'/api$'), '');
    return '$parent/api/';
  }
}
