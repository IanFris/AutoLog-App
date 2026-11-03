import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:autolog/main.dart';
import 'package:autolog/models/service_log.dart';
import 'package:autolog/models/vehicle.dart';
import 'package:autolog/providers/auth_provider.dart';
import 'package:autolog/providers/service_provider.dart';
import 'package:autolog/providers/vehicle_provider.dart';
import 'package:autolog/models/user.dart';
import 'package:autolog/services/session_service.dart';
import 'package:autolog/screens/vehicles/add_edit_vehicle_screen.dart';
import 'package:autolog/screens/service_logs/add_service_log_screen.dart';
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

  testWidgets('guest can enter without registering',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const AutoLogApp());
    await tester.pumpAndSettle();

    final guestButton = find.text('Lanjutkan sebagai Tamu');
    await tester.ensureVisible(guestButton);
    await tester.tap(guestButton);
    await tester.pumpAndSettle();

    expect(find.textContaining('Mode Tamu: data tersimpan'), findsOneWidget);
    expect((await SessionService.getUser())?.isGuest, isTrue);
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

  testWidgets('service type dropdown loads and allows selection',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await SessionService.saveUser(
      User(
        id: 0,
        name: 'Tamu',
        email: 'guest@local.autolog',
        isGuest: true,
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
          ChangeNotifierProvider<ServiceProvider>(
              create: (_) => ServiceProvider()),
        ],
        child: MaterialApp(
          home: AddServiceLogScreen(
            vehicle: Vehicle(
              id: 1,
              userId: 0,
              type: VehicleType.motor,
              brandModel: 'Honda Vario',
              licensePlate: 'B 1234 XYZ',
              currentOdometer: 12000,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final serviceDropdown = find.byType(DropdownButtonFormField<int>);
    expect(serviceDropdown, findsOneWidget);
    await tester.ensureVisible(serviceDropdown);
    await tester.tap(serviceDropdown);
    await tester.pumpAndSettle();

    final serviceOption = find.text('Ganti Oli Gardan / Transmisi');
    expect(serviceOption, findsOneWidget);
    await tester.tap(serviceOption);
    await tester.pumpAndSettle();
    expect(serviceOption, findsOneWidget);
  });

  test('guest vehicle and service data stays in local storage', () async {
    SharedPreferences.setMockInitialValues({});
    await SessionService.saveUser(
      User(
        id: 0,
        name: 'Tamu',
        email: 'guest@local.autolog',
        isGuest: true,
      ),
    );

    final vehicles = VehicleProvider();
    await vehicles.fetchVehicles(0);
    expect(vehicles.vehicles, isEmpty);
    expect(
      await vehicles.addVehicle(
        userId: 0,
        type: 'motor',
        brandModel: 'Honda Vario',
        licensePlate: 'B 1234 XYZ',
        currentOdometer: 12000,
      ),
      isTrue,
    );

    final vehicle = vehicles.activeVehicle!;
    final services = ServiceProvider();
    await services.fetchServiceTypes();
    await services.fetchVehicleData(vehicle.id);
    expect(services.serviceTypes, isNotEmpty);

    final now = DateTime.now();
    final date =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    expect(
      await services.addServiceLog(
        vehicleId: vehicle.id,
        serviceTypeId: services.serviceTypes.first.id,
        serviceDate: date,
        odometerKm: 12500,
        cost: 150000,
        workshopName: 'Bengkel Lokal',
      ),
      isTrue,
    );
    expect(services.serviceLogs, hasLength(1));
    expect(services.expenses?.totalAllTime, 150000);
    expect(services.reminders, hasLength(1));

    final log = services.serviceLogs.single;
    expect(
      await services.updateServiceLog(
        serviceLogId: log.id,
        vehicleId: vehicle.id,
        serviceTypeId: log.serviceTypeId,
        serviceDate: date,
        odometerKm: 12500,
        cost: 175000,
        workshopName: 'Bengkel Lokal',
      ),
      isTrue,
    );
    expect(services.expenses?.totalAllTime, 175000);
    expect(
      await services.deleteServiceLog(log.id, vehicleId: vehicle.id),
      isTrue,
    );
    expect(services.serviceLogs, isEmpty);

    final restored = VehicleProvider();
    await restored.fetchVehicles(0);
    expect(restored.vehicles, hasLength(1));
    expect(restored.vehicles.single.brandModel, 'Honda Vario');
  });
}
