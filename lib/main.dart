import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_grow_code/auth/auth_gate.dart';
import 'package:smart_grow_code/dashboard/dashboard.dart';
import 'package:smart_grow_code/dashboard/login_screen.dart';
import 'package:smart_grow_code/dashboard/admin/user_management_screen.dart';
import 'package:smart_grow_code/firebase_options.dart';
import 'package:smart_grow_code/services/alert_store.dart';
import 'package:smart_grow_code/services/app_settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Hive.initFlutter();
  await Hive.openBox('harvestBox');
  await AppSettingsService.load();

  runApp(const SmartGrowApp());
}

class SmartGrowApp extends StatelessWidget {
  const SmartGrowApp({super.key});
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppFontSettings>(
      valueListenable: AppSettingsService.settings,
      builder: (context, fontSettings, _) {
        final textScale = (fontSettings.bodyFontSize / 14)
            .clamp(0.8, 1.6)
            .toDouble();

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Smart Grow App',
          theme: ThemeData(
            primarySwatch: Colors.brown,
            appBarTheme: AppBarTheme(
              titleTextStyle: TextStyle(
                fontSize: fontSettings.headerFontSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: TextScaler.linear(textScale),
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          routes: {
            '/': (context) => const AuthGate(),
            '/login': (context) => const LoginScreen(),
            '/home': (context) => const SmartGrowDashboard(),
            '/admin/users': (context) => const UserManagementScreen(),
            '/sensor-test': (context) => SensorTestScreen(),
          },
        );
      },
    );
  }
}
