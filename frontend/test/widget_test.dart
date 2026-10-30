import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:autolog/main.dart';

void main() {
  testWidgets('AutoLog app smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const AutoLogApp());
    await tester.pumpAndSettle();

    expect(find.text('AutoLog'), findsWidgets);
  });
}
