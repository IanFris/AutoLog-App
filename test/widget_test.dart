import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:autolog/main.dart';
import 'package:autolog/providers/autolog_provider.dart';
import 'package:autolog/services/storage_service.dart';

void main() {
  testWidgets('AutoLog app smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();
    final provider = AutoLogProvider(storage);

    await tester.pumpWidget(AutoLogApp(provider: provider));
    await tester.pumpAndSettle();

    expect(find.text('AutoLog'), findsWidgets);
  });
}
