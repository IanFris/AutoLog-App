import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'providers/autolog_provider.dart';
import 'screens/main_navigation_screen.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set status bar and navigation bar styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  final storage = await StorageService.init();
  final provider = AutoLogProvider(storage);

  runApp(AutoLogApp(provider: provider));
}

class AutoLogApp extends StatelessWidget {
  final AutoLogProvider provider;

  const AutoLogApp({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: provider,
      builder: (context, _) {
        return MaterialApp(
          title: 'AutoLog',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: provider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: MainNavigationScreen(provider: provider),
        );
      },
    );
  }
}
