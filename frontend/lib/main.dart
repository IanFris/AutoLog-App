import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/vehicle_provider.dart';
import 'providers/service_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const AutoLogApp());
}

class AutoLogApp extends StatelessWidget {
  const AutoLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<VehicleProvider>(
            create: (_) => VehicleProvider()),
        ChangeNotifierProvider<ServiceProvider>(
            create: (_) => ServiceProvider()),
        ChangeNotifierProvider<SettingsProvider>(
            create: (_) => SettingsProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return Consumer<SettingsProvider>(
            builder: (context, settings, _) {
              return MaterialApp(
                title: 'AutoLog',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: settings.themeMode,
                home: auth.isInitializing || !settings.isInitialized
                    ? const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      )
                    : auth.isAuthenticated
                        ? const MainNavigationScreen()
                        : const LoginScreen(),
              );
            },
          );
        },
      ),
    );
  }
}
