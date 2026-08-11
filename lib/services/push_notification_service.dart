import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Handles operating-system notifications for Smart-Grow.
///
/// The notification condition is detected by SensorMonitorService from
/// Firebase RTDB live data. Alert history itself is stored separately
/// by AlertStore.
class PushNotificationService {
  PushNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static int _nextId = 0;

  static Future<void> init() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const darwinInit = DarwinInitializationSettings();

    const settings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
    );

    await _plugin.initialize(
      settings,
    );

    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin
        ?.requestNotificationsPermission();

    const channel = AndroidNotificationChannel(
      'smart_grow_alerts',
      'Smart Grow Alerts',
      description:
          'Environmental, device, sensor, water level, and component alerts.',
      importance: Importance.high,
    );

    await androidPlugin?.createNotificationChannel(
      channel,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    _initialized = true;
  }

  static Future<void> show({
    required String title,
    required String body,
  }) async {
    if (!_initialized) {
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'smart_grow_alerts',
      'Smart Grow Alerts',
      channelDescription:
          'Environmental, device, sensor, water level, and component alerts.',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _plugin.show(
      _nextId++,
      title,
      body,
      details,
    );
  }
}