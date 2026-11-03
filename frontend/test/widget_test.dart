import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:autolog/main.dart';
import 'package:autolog/models/service_log.dart';
import 'package:autolog/models/vehicle.dart';
import 'package:autolog/providers/auth_provider.dart';
import 'package:autolog/providers/vehicle_provider.dart';
import 'package:autolog/screens/vehicles/add_edit_vehicle_screen.dart';
import 'package:autolog/utils/service_log_csv_exporter.dart';

void main() {
  test('CSV export escapes special characters and includes all service fields',
      () {
    final csv = ServiceLogCsvExporter.createCsv([
      ServiceLog(
        id: 1,
        vehicleId: 2,
        serviceTypeId: 3,
        serviceDate: DateTime(2026, 11, 3),
        odometerKm: 12500,
        cost: 275000,
        workshopName: '=HYPERLINK("https://example.invalid","Bengkel")',
        notes: '@SUM(A1:A2)\nGanti oli, cek rem',
        serviceTypeName: 'Servis, rutin',
      ),
    ]);

    expect(csv.startsWith('\uFEFF'), isTrue);
    expect(csv, contains('"Tanggal Servis","Jenis Servis","Odometer (KM)"'));
    expect(
        csv,
        contains(
            '"\u0027=HYPERLINK(""https://example.invalid"",""Bengkel"")"'));
    expect(csv, contains('"\u0027@SUM(A1:A2)\nGanti oli, cek rem"'));
    expect(csv, contains('"275000.00"'));
  });

  testWidgets('AutoLog app smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const AutoLogApp());
    await tester.pumpAndSettle();

    expect(find.text('AutoLog'), findsWidgets);
  });

  testWidgets('Edit vehicle screen shows edit mode for existing vehicle',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
          ChangeNotifierProvider<VehicleProvider>(
              create: (_) => VehicleProvider()),
        ],
        child: MaterialApp(
          home: AddEditVehicleScreen(
            vehicle: Vehicle(
              id: 10,
              userId: 1,
              type: VehicleType.motor,
              brandModel: 'Honda Vario 160',
              licensePlate: 'B 1234 XYZ',
              currentOdometer: 15000,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Edit Kendaraan'), findsOneWidget);
    expect(find.text('Simpan Perubahan'), findsWidgets);
    expect(find.text('Honda Vario 160'), findsWidgets);
  });
}
