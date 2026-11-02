import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:autolog/main.dart';
import 'package:autolog/models/service_log.dart';
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
}
