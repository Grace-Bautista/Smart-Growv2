import 'dart:async';

import 'package:flutter/foundation.dart';

import 'alert_store.dart';
import 'esp32_service.dart';
import 'grow_log_store.dart';
import 'push_notification_service.dart';

/// Polls the ESP32 on a timer, keeps the latest reading available to any
/// screen via [latest], writes every reading to [GrowLogStore], and raises
/// alerts (persisted to [AlertStore] + an OS notification) whenever a
/// reading crosses a threshold or the device/sensor changes state.
///
/// Thresholds default to the same bands the ESP32 firmware itself uses to
/// auto-trigger the fan (see "esp32 demo firmware.txt": temperature on at
/// 28C / off at 26C, CO2 on at 900ppm / off at 700ppm). Adjust the
/// constants below if your crop needs different targets.
class SensorMonitorService {
  SensorMonitorService._();

  static const Duration pollInterval = GrowLogStore.pollInterval;

  // --- Thresholds (tune these for your setup) ---
  static const double tempHighC = 28.0;
  static const double tempNormalC = 26.0;
  static const int co2HighPpm = 900;
  static const int co2NormalPpm = 700;
  static const double humidityLowPct = 50.0;
  static const double humidityHighPct = 95.0;

  /// Minimum gap between repeat alerts of the *same* kind, so a value
  /// sitting just past a threshold doesn't spam a new alert every poll.
  static const Duration _cooldown = Duration(minutes: 15);

  /// Latest snapshot from the ESP32 — screens listen to this instead of
  /// each polling the device themselves.
  static final ValueNotifier<Esp32Snapshot> latest =
      ValueNotifier(Esp32Snapshot.offline());

  static Timer? _timer;
  static bool _started = false;
  static Esp32Snapshot? _previous;
  static final Map<String, DateTime> _lastFired = {};

  static Future<void> start() async {
    if (_started) return;
    _started = true;

    await _poll();
    _timer = Timer.periodic(pollInterval, (_) => _poll());
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
    _started = false;
  }

  /// Lets the UI (e.g. tapping the online/offline badge) force an
  /// immediate check instead of waiting for the next timer tick.
  static Future<void> refreshNow() => _poll();

  static Future<void> _poll() async {
    final snapshot = await Esp32Service.readSnapshot();
    latest.value = snapshot;

    await GrowLogStore.addReading(snapshot);
    await _evaluateAlerts(snapshot, _previous);
    _previous = snapshot;
  }

  static bool _offCooldown(String key) {
    final last = _lastFired[key];
    if (last == null) return true;
    return DateTime.now().difference(last) > _cooldown;
  }

  static Future<void> _raise({
    required String key,
    required String title,
    required String subtitle,
    required String iconKey,
    required int colorValue,
    AlertSeverity severity = AlertSeverity.warning,
  }) async {
    if (!_offCooldown(key)) return;
    _lastFired[key] = DateTime.now();

    await AlertStore.add(
      title: title,
      subtitle: subtitle,
      iconKey: iconKey,
      colorValue: colorValue,
      severity: severity,
    );
    await PushNotificationService.show(title: title, body: subtitle);
  }

  static Future<void> _evaluateAlerts(
    Esp32Snapshot snap,
    Esp32Snapshot? prev,
  ) async {
    // --- Device connectivity (edge-triggered: only on state change) ---
    if (prev != null && prev.connected && !snap.connected) {
      await _raise(
        key: 'device_offline',
        title: 'Device Offline',
        subtitle:
            'Lost connection to the ESP32. Make sure your phone is still joined to its WiFi hotspot.',
        iconKey: 'wifi_off',
        colorValue: 0xFFB56576,
        severity: AlertSeverity.critical,
      );
    } else if (prev != null && !prev.connected && snap.connected) {
      await _raise(
        key: 'device_online',
        title: 'Device Reconnected',
        subtitle: 'The app reconnected to the ESP32.',
        iconKey: 'wifi',
        colorValue: 0xFF2A9D8F,
        severity: AlertSeverity.info,
      );
    }

    if (!snap.connected) {
      // Nothing else is meaningful to check without a live reading.
      return;
    }

    // --- Sensor link (edge-triggered) ---
    if (prev != null && prev.sensorOnline && !snap.sensorOnline) {
      await _raise(
        key: 'sensor_offline',
        title: 'Sensor Link Lost',
        subtitle: 'The SCD40 stopped reporting readings.',
        iconKey: 'sensors_off',
        colorValue: 0xFF6D597A,
        severity: AlertSeverity.critical,
      );
    } else if (prev != null && !prev.sensorOnline && snap.sensorOnline) {
      await _raise(
        key: 'sensor_online',
        title: 'Sensor Link Restored',
        subtitle: 'SCD40 communication resumed and live readings returned.',
        iconKey: 'sensors',
        colorValue: 0xFF2A9D8F,
        severity: AlertSeverity.info,
      );
    }

    // --- Water level (level-triggered, cooldown-limited) ---
    if (!snap.waterPresent) {
      await _raise(
        key: 'water_low',
        title: 'Low Water Detected',
        subtitle: 'The tank is reporting empty. The refill pump was armed.',
        iconKey: 'opacity',
        colorValue: 0xFF264653,
      );
    }

    // --- Temperature ---
    final temp = snap.temperature;
    if (temp != null) {
      if (temp >= tempHighC) {
        await _raise(
          key: 'temp_high',
          title: 'Temperature Alert',
          subtitle:
              'Grow room temperature reached ${temp.toStringAsFixed(1)}C. '
              'Ventilation should kick in automatically.',
          iconKey: 'thermostat',
          colorValue: 0xFFE76F51,
        );
      } else if (temp <= tempNormalC) {
        // Back to normal — allow the next breach to alert right away
        // instead of waiting out the cooldown from the last one.
        _lastFired.remove('temp_high');
      }
    }

    // --- CO2 ---
    final co2 = snap.co2;
    if (co2 != null) {
      if (co2 >= co2HighPpm) {
        await _raise(
          key: 'co2_high',
          title: 'CO2 Ventilation Triggered',
          subtitle:
              'CO2 rose to $co2 ppm, above the $co2HighPpm ppm target band.',
          iconKey: 'air',
          colorValue: 0xFFF4A261,
        );
      } else if (co2 <= co2NormalPpm) {
        _lastFired.remove('co2_high');
      }
    }

    // --- Humidity ---
    final humidity = snap.humidity;
    if (humidity != null) {
      if (humidity < humidityLowPct) {
        await _raise(
          key: 'humidity_low',
          title: 'Humidity Dropped',
          subtitle:
              'Relative humidity fell to ${humidity.toStringAsFixed(0)}%. '
              'Check misting coverage and bag moisture.',
          iconKey: 'water_drop',
          colorValue: 0xFF2A9D8F,
        );
      } else if (humidity > humidityHighPct) {
        await _raise(
          key: 'humidity_high',
          title: 'Humidity Too High',
          subtitle:
              'Relative humidity reached ${humidity.toStringAsFixed(0)}%, risking mold.',
          iconKey: 'water_drop',
          colorValue: 0xFFE76F51,
        );
      } else {
        _lastFired.remove('humidity_low');
        _lastFired.remove('humidity_high');
      }
    }
  }
}
