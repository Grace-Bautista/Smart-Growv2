import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:smart_grow_code/auth/auth_gate.dart';
import 'package:smart_grow_code/dashboard/admin/user_management_screen.dart';
import 'package:smart_grow_code/dashboard/dashboard.dart';
import 'package:smart_grow_code/dashboard/login_screen.dart';
import 'package:smart_grow_code/firebase_options.dart';
import 'package:smart_grow_code/screens/sensor_test_screen.dart';

import 'package:smart_grow_code/services/alert_store.dart';
import 'package:smart_grow_code/services/app_settings_service.dart';
import 'package:smart_grow_code/services/esp32_service.dart';
import 'package:smart_grow_code/services/push_notification_service.dart';
import 'package:smart_grow_code/services/sensor_monitor_service.dart';
import 'package:smart_grow_code/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ------------------------------------------------------------
  // FIREBASE
  // ------------------------------------------------------------
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ------------------------------------------------------------
  // LOCAL STORAGE
  // ------------------------------------------------------------
  await Hive.initFlutter();

  await Hive.openBox('harvestBox');

  await AlertStore.init();

  await AppSettingsService.load();

  // ------------------------------------------------------------
  // LOCAL OS NOTIFICATIONS
  // ------------------------------------------------------------
  await PushNotificationService.init();

  // ------------------------------------------------------------
  // SENSOR MONITOR
  // ------------------------------------------------------------
  //
  // RTDB liveData requires an authenticated Firebase user.
  //
  // Therefore:
  //
  // Logged in  -> start monitoring
  // Logged out -> stop monitoring
  //
  FirebaseAuth.instance.authStateChanges().listen((user) async {
    if (user != null) {
      Esp32Service.instance.start();
      await SensorMonitorService.start();
    } else {
      await SensorMonitorService.stop();
      await Esp32Service.instance.stop();
    }
  });

  runApp(const SmartGrowApp());
}

class SmartGrowApp extends StatelessWidget {
  const SmartGrowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: AppSettingsService.settings,
      builder: (context, fontSettings, _) {
        final textScale = (fontSettings.bodyFontSize / 14)
            .clamp(0.8, 1.6)
            .toDouble();

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Smart Grow App',
          theme: AppTheme.light.copyWith(
            appBarTheme: AppTheme.light.appBarTheme.copyWith(
              titleTextStyle: AppTheme.light.appBarTheme.titleTextStyle
                  ?.copyWith(fontSize: fontSettings.headerFontSize),
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
            '/home': (context) => const DashboardScreen(),
            '/admin/users': (context) => const UserManagementScreen(),
            '/sensor-test': (context) => SensorTestScreen(),
          },
        );
      },
    );
  }
}
