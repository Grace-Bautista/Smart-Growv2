import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Thin wrapper around flutter_local_notifications so the rest of the app
/// doesn't need to know platform-specific notification details.
///
/// IMPORTANT / honest limitation: this shows a *local* OS notification
/// triggered by the app itself while it's running (foreground or briefly
/// backgrounded). It is NOT a server push. Because the ESP32 only talks
/// to the phone over its own local WiFi hotspot (see the firmware file),
/// there's no cloud relay that can wake the app or notify it while it's
/// fully closed, or while the phone isn't joined to the ESP32's WiFi.
class PushNotificationService {
  PushNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static int _nextId = 0;

  static Future<void> init() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
    );

    await _plugin.initialize(settings);

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  static Future<void> show({
    required String title,
    required String body,
  }) async {
    if (!_initialized) return;

    const androidDetails = AndroidNotificationDetails(
      'smart_grow_alerts',
      'Smart Grow Alerts',
      channelDescription:
          'Temperature, CO2, water level and sensor connection alerts',
      importance: Importance.high,
      priority: Priority.high,
    );
    const darwinDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _plugin.show(_nextId++, title, body, details);
  }
}
