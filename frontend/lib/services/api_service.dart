import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../core/constants/api_constants.dart';
import '../models/user.dart';
import '../models/vehicle.dart';
import '../models/service_type.dart';
import '../models/service_log.dart';
import '../models/component_reminder.dart';
import '../models/expense_summary.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiService {
  // Helper internal untuk menangani respon
  static Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (data['status'] == 'success') {
          return data;
        }
        throw ApiException(data['message'] ?? 'Terjadi kesalahan sistem');
      } else {
        throw ApiException(
          data['message'] ?? 'Gagal menghubungi server (HTTP ${response.statusCode})',
          response.statusCode,
        );
      }
    } on FormatException {
      throw ApiException('Format respon dari server tidak valid.');
    }
  }

  // --- 1. AUTH ---
  static Future<User> login(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConstants.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final json = _handleResponse(res);
      final userData = json['data']['user'] as Map<String, dynamic>;
      return User.fromJson(userData);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal terhubung ke server Laragon: $e');
    }
  }

  static Future<User> register(String name, String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConstants.register),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );

      final json = _handleResponse(res);
      final userData = json['data']['user'] as Map<String, dynamic>;
      return User.fromJson(userData);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal terhubung ke server Laragon: $e');
    }
  }

  // --- 2. VEHICLES ---
  static Future<List<Vehicle>> getVehicles(int userId) async {
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.vehicles}?user_id=$userId'),
      );

      final json = _handleResponse(res);
      final list = json['data'] as List<dynamic>;
      return list.map((item) => Vehicle.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal mengambil daftar kendaraan: $e');
    }
  }

  static Future<Vehicle> createVehicle({
    required int userId,
    required String type,
    required String brandModel,
    required String licensePlate,
    required int currentOdometer,
  }) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConstants.vehicles),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'type': type,
          'brand_model': brandModel,
          'license_plate': licensePlate,
          'current_odometer': currentOdometer,
        }),
      );

      final json = _handleResponse(res);
      return Vehicle.fromJson(json['data'] as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal menambahkan kendaraan: $e');
    }
  }

  static Future<void> updateOdometer(int vehicleId, int newOdometer) async {
    try {
      final res = await http.put(
        Uri.parse(ApiConstants.vehicles),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': vehicleId,
          'current_odometer': newOdometer,
        }),
      );
      _handleResponse(res);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal memperbarui odometer: $e');
    }
  }

  // --- 3. SERVICE TYPES ---
  static Future<List<ServiceType>> getServiceTypes() async {
    try {
      final res = await http.get(Uri.parse(ApiConstants.serviceTypes));
      final json = _handleResponse(res);
      final list = json['data'] as List<dynamic>;
      return list.map((item) => ServiceType.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal mengambil katalog jenis servis: $e');
    }
  }

  // --- 4. SERVICE LOGS ---
  static Future<List<ServiceLog>> getServiceLogs(int vehicleId) async {
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.serviceLogs}?vehicle_id=$vehicleId'),
      );
      final json = _handleResponse(res);
      final list = json['data'] as List<dynamic>;
      return list.map((item) => ServiceLog.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal mengambil riwayat servis: $e');
    }
  }

  static Future<ServiceLog> createServiceLog({
    required int vehicleId,
    required int serviceTypeId,
    required String serviceDate,
    required int odometerKm,
    required double cost,
    String? workshopName,
    String? notes,
    XFile? receiptPhoto,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.serviceLogs);
      final request = http.MultipartRequest('POST', uri);

      request.fields['vehicle_id'] = vehicleId.toString();
      request.fields['service_type_id'] = serviceTypeId.toString();
      request.fields['service_date'] = serviceDate;
      request.fields['odometer_km'] = odometerKm.toString();
      request.fields['cost'] = cost.toString();
      if (workshopName != null) request.fields['workshop_name'] = workshopName;
      if (notes != null) request.fields['notes'] = notes;

      if (receiptPhoto != null) {
        final bytes = await receiptPhoto.readAsBytes();
        final multipartFile = http.MultipartFile.fromBytes(
          'receipt_photo',
          bytes,
          filename: receiptPhoto.name,
        );
        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final json = _handleResponse(response);
      return ServiceLog.fromJson(json['data'] as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal menyimpan catatan servis: $e');
    }
  }

  // --- 5. DASHBOARD REMINDERS (Status Hijau, Kuning, Merah) ---
  static Future<List<ComponentReminder>> getReminders(int vehicleId) async {
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.reminders}?vehicle_id=$vehicleId'),
      );
      final json = _handleResponse(res);
      final list = json['data']['reminders'] as List<dynamic>;
      return list
          .map((item) => ComponentReminder.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal memuat status pengingat: $e');
    }
  }

  // --- 6. DASHBOARD EXPENSES ---
  static Future<ExpenseSummary> getExpenses(int vehicleId) async {
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.expenses}?vehicle_id=$vehicleId'),
      );
      final json = _handleResponse(res);
      return ExpenseSummary.fromJson(json['data'] as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal memuat rekapitulasi biaya: $e');
    }
  }
}

