import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:smart_grow_code/models/sensor_data.dart';
import 'package:smart_grow_code/services/alert_store.dart';
import 'package:smart_grow_code/services/esp32_service.dart';
import 'package:smart_grow_code/services/push_notification_service.dart';
import 'package:smart_grow_code/services/sensor_service.dart';

/// Watches the authoritative Firebase RTDB live state and creates
/// Smart-Grow alerts when important conditions occur.
///
/// This service DOES NOT poll the ESP32.
///
/// Live flow:
///
/// Firebase RTDB
///   -> SensorService
///   -> SensorMonitorService
///   -> AlertStore
///   -> Android/iOS local notification
class SensorMonitorService {
  SensorMonitorService._();

  // ------------------------------------------------------------
  // ENVIRONMENT TARGETS
  // ------------------------------------------------------------

  static const double tempLowC = 21.0;
  static const double tempHighC = 31.0;

  static const double humidityLowPct = 75.0;
  static const double humidityHighPct = 96.0;

  /// We don't currently have a finalized numeric low-water threshold
  /// in the RTDB contract.
  ///
  /// Leave null until this is matched to the ESP32 refill threshold.
  ///
  /// Example:
  /// static const double? waterLowPct = 20.0;
  static const double? waterLowPct = null;

  /// Secondary protection against duplicate alerts after app restart.
  static const Duration _cooldown = Duration(minutes: 15);

  // ------------------------------------------------------------
  // LIVE STATE
  // ------------------------------------------------------------

  static final ValueNotifier<SensorData?> latest = ValueNotifier<SensorData?>(
    null,
  );

  static StreamSubscription<SensorData>? _subscription;

  static bool _started = false;

  /// Conditions currently active.
  ///
  /// Example:
  /// humidity_low is added when humidity first drops below 75%.
  /// It remains here until humidity returns to normal.
  static final Set<String> _activeConditions = <String>{};

  /// In-memory last-fired timestamps.
  ///
  /// AlertStore is also checked so cooldown protection survives
  /// application restarts.
  static final Map<String, DateTime> _lastFired = <String, DateTime>{};

  static VoidCallback? _espConnectionListener;
  static EspConnectionState _previousEspState = EspConnectionState.unknown;

  /// Keeps asynchronous evaluations in sequence so two rapid Firebase
  /// events cannot create duplicate notifications simultaneously.
  static Future<void> _evaluationQueue = Future<void>.value();

  /// Connection-state alerts use their own queue so they are not
  /// delayed behind environmental/sensor evaluations.
  static Future<void> _connectionQueue = Future<void>.value();

  // ------------------------------------------------------------
  // START / STOP
  // ------------------------------------------------------------

  static Future<void> start() async {
    if (_started) return;

    _started = true;

    // Shared stabilized ESP32 state used by Dashboard, Settings,
    // and Notifications.
    final esp32 = Esp32Service.instance;

    esp32.start();

    _previousEspState = esp32.connectionState.value;

    _espConnectionListener = () {
      _handleEspConnectionChange(esp32.connectionState.value);
    };

    esp32.connectionState.addListener(_espConnectionListener!);

    // RTDB sensor/component data is still monitored normally.
    _subscription = SensorService.instance.watchLiveData().listen(
      (snapshot) {
        latest.value = snapshot;
        _queueEvaluation(snapshot);
      },
      onError: (Object error) {
        _queueStreamError(error);
      },
    );
  }

  static Future<void> stop() async {
    final listener = _espConnectionListener;

    if (listener != null) {
      Esp32Service.instance.connectionState.removeListener(listener);
    }

    _espConnectionListener = null;
    _previousEspState = EspConnectionState.unknown;

    await _subscription?.cancel();
    _subscription = null;

    _started = false;

    latest.value = null;

    _activeConditions.clear();
  }

  // ------------------------------------------------------------
  // SHARED ESP32 CONNECTION EVENTS
  // ------------------------------------------------------------

  static void _handleEspConnectionChange(EspConnectionState current) {
    final previous = _previousEspState;

    // Unknown -> known is initial synchronization, not a transition alert.
    if (previous == EspConnectionState.unknown) {
      _previousEspState = current;
      return;
    }

    // Ignore duplicate state emissions.
    if (previous == current || current == EspConnectionState.unknown) {
      return;
    }

    _previousEspState = current;

    if (current == EspConnectionState.online) {
      _queueDeviceOnline();
    } else {
      _queueDeviceOffline();
    }
  }

  static void _queueDeviceOffline() {
    _connectionQueue = _connectionQueue
        .then((_) async {
          await _activateCondition(
            key: 'device_offline',
            title: 'Device Offline',
            subtitle: 'Smart-Grow lost connection to the ESP32.',
            iconKey: 'wifi_off',
            colorValue: 0xFFB56576,
            severity: AlertSeverity.critical,
            useCooldown: false,
          );
        })
        .catchError((Object error) {
          debugPrint('ESP32 offline notification error: $error');
        });
  }

  static void _queueDeviceOnline() {
    _connectionQueue = _connectionQueue
        .then((_) async {
          _clearCondition('device_offline');

          await _raiseEvent(
            key: 'device_online',
            title: 'Device Reconnected',
            subtitle: 'Smart-Grow reconnected to the ESP32.',
            iconKey: 'wifi',
            colorValue: 0xFF2A9D8F,
            severity: AlertSeverity.info,
            useCooldown: false,
          );
        })
        .catchError((Object error) {
          debugPrint('ESP32 reconnect notification error: $error');
        });
  }

  // ------------------------------------------------------------
  // QUEUE
  // ------------------------------------------------------------

  static void _queueEvaluation(SensorData snapshot) {
    _evaluationQueue = _evaluationQueue
        .then((_) => _evaluate(snapshot))
        .catchError((Object error) {
          debugPrint('SensorMonitorService evaluation error: $error');
        });
  }

  static void _queueStreamError(Object error) {
    _evaluationQueue = _evaluationQueue
        .then((_) => _handleStreamError(error))
        .catchError((Object error) {
          debugPrint(
            'SensorMonitorService stream error handler failed: $error',
          );
        });
  }

  // ------------------------------------------------------------
  // COOLDOWN
  // ------------------------------------------------------------

  static bool _isOffCooldown(String key) {
    final inMemory = _lastFired[key];
    final persisted = AlertStore.lastTimestampFor(key);

    DateTime? latestTimestamp;

    if (inMemory != null && persisted != null) {
      latestTimestamp = inMemory.isAfter(persisted) ? inMemory : persisted;
    } else {
      latestTimestamp = inMemory ?? persisted;
    }

    if (latestTimestamp == null) {
      return true;
    }

    return DateTime.now().difference(latestTimestamp) >= _cooldown;
  }

  // ------------------------------------------------------------
  // ALERT HELPERS
  // ------------------------------------------------------------

  static Future<void> _storeAndNotify({
    required String key,
    required String title,
    required String subtitle,
    required String iconKey,
    required int colorValue,
    AlertSeverity severity = AlertSeverity.warning,
    bool useCooldown = true,
  }) async {
    if (useCooldown && !_isOffCooldown(key)) {
      return;
    }

    _lastFired[key] = DateTime.now();

    await AlertStore.add(
      title: title,
      subtitle: subtitle,
      iconKey: iconKey,
      colorValue: colorValue,
      conditionKey: key,
      severity: severity,
    );

    await PushNotificationService.show(title: title, body: subtitle);
  }

  /// Activates a condition once.
  ///
  /// Repeated RTDB updates while the condition remains active will
  /// NOT create another notification.
  static Future<void> _activateCondition({
    required String key,
    required String title,
    required String subtitle,
    required String iconKey,
    required int colorValue,
    AlertSeverity severity = AlertSeverity.warning,
    bool useCooldown = true,
  }) async {
    if (_activeConditions.contains(key)) {
      return;
    }

    _activeConditions.add(key);

    await _storeAndNotify(
      key: key,
      title: title,
      subtitle: subtitle,
      iconKey: iconKey,
      colorValue: colorValue,
      severity: severity,
      useCooldown: useCooldown,
    );
  }

  static void _clearCondition(String key) {
    _activeConditions.remove(key);
  }

  /// Events such as "Device Reconnected" don't remain active.
  static Future<void> _raiseEvent({
    required String key,
    required String title,
    required String subtitle,
    required String iconKey,
    required int colorValue,
    AlertSeverity severity = AlertSeverity.info,
    bool useCooldown = true,
  }) {
    return _storeAndNotify(
      key: key,
      title: title,
      subtitle: subtitle,
      iconKey: iconKey,
      colorValue: colorValue,
      severity: severity,
      useCooldown: useCooldown,
    );
  }

  // ------------------------------------------------------------
  // RTDB STREAM ERROR
  // ------------------------------------------------------------

  static Future<void> _handleStreamError(Object error) async {
    await _activateCondition(
      key: 'rtdb_stream_error',
      title: 'Live Data Connection Error',
      subtitle:
          'Smart-Grow could not receive live data from Firebase. '
          'Check the internet connection and try again.',
      iconKey: 'wifi_off',
      colorValue: 0xFFB56576,
      severity: AlertSeverity.critical,
    );

    debugPrint('SensorService RTDB error: $error');
  }

  // ------------------------------------------------------------
  // MAIN EVALUATION
  // ------------------------------------------------------------

  static Future<void> _evaluate(SensorData data) async {
    final now = DateTime.now();

    // If we successfully received another RTDB event after an RTDB
    // stream problem, clear the connection-error state.
    final streamWasBroken = _activeConditions.contains('rtdb_stream_error');

    _clearCondition('rtdb_stream_error');

    if (streamWasBroken) {
      await _raiseEvent(
        key: 'rtdb_stream_restored',
        title: 'Live Data Restored',
        subtitle:
            'The app resumed receiving Smart-Grow live data from Firebase.',
        iconKey: 'wifi',
        colorValue: 0xFF2A9D8F,
      );
    }

    // Do not evaluate environmental values while the shared,
    // stabilized ESP32 connection state is Offline.
    if (!Esp32Service.instance.isOnline.value) {
      return;
    }

    await _evaluateSensorHealth(data, now);

    await _evaluateTemperature(data, now);

    await _evaluateHumidity(data, now);

    await _evaluateWaterLevel(data, now);

    await _evaluateComponentFaults(data);
  }

  // ------------------------------------------------------------
  // SENSOR HEALTH
  // ------------------------------------------------------------

  static bool _readingHealthy(
    SensorReadingStatus status,
    double? value,
    DateTime now,
  ) {
    return value != null && status.isFresh(now);
  }

  static Future<void> _evaluateSensorHealth(
    SensorData data,
    DateTime now,
  ) async {
    final environmentHealthy =
        _readingHealthy(
          data.environmentTempStatus,
          data.environmentTemperature,
          now,
        ) &&
        _readingHealthy(data.humidityStatus, data.humidity, now) &&
        _readingHealthy(data.co2Status, data.co2, now);

    if (!environmentHealthy) {
      await _activateCondition(
        key: 'environment_sensor_issue',
        title: 'Environmental Sensor Issue',
        subtitle:
            'One or more environmental sensor readings are missing, invalid, or stale.',
        iconKey: 'sensors_off',
        colorValue: 0xFF6D597A,
        severity: AlertSeverity.critical,
      );
    } else {
      final wasFaulted = _activeConditions.contains('environment_sensor_issue');

      _clearCondition('environment_sensor_issue');

      if (wasFaulted) {
        await _raiseEvent(
          key: 'environment_sensor_restored',
          title: 'Environmental Sensor Restored',
          subtitle:
              'Temperature, humidity, and CO2 readings are reporting normally again.',
          iconKey: 'sensors',
          colorValue: 0xFF2A9D8F,
        );
      }
    }

    final waterHealthy = _readingHealthy(
      data.waterLevelStatus,
      data.waterLevel,
      now,
    );

    if (!waterHealthy) {
      await _activateCondition(
        key: 'water_sensor_issue',
        title: 'Water Level Sensor Issue',
        subtitle: 'The water level reading is missing, invalid, or stale.',
        iconKey: 'sensors_off',
        colorValue: 0xFF6D597A,
        severity: AlertSeverity.warning,
      );
    } else {
      _clearCondition('water_sensor_issue');
    }
  }

  // ------------------------------------------------------------
  // TEMPERATURE
  // ------------------------------------------------------------

  static Future<void> _evaluateTemperature(
    SensorData data,
    DateTime now,
  ) async {
    final temp = data.environmentTemperature;

    final healthy = _readingHealthy(data.environmentTempStatus, temp, now);

    if (!healthy || temp == null) {
      _clearCondition('temperature_low');
      _clearCondition('temperature_high');
      return;
    }

    if (temp < tempLowC) {
      _clearCondition('temperature_high');

      await _activateCondition(
        key: 'temperature_low',
        title: 'Temperature Too Low',
        subtitle:
            'Grow room temperature dropped to '
            '${temp.toStringAsFixed(1)}°C. '
            'Recommended range is 25–28°C.',
        iconKey: 'thermostat',
        colorValue: 0xFF457B9D,
        severity: AlertSeverity.warning,
      );
    } else if (temp > tempHighC) {
      _clearCondition('temperature_low');

      await _activateCondition(
        key: 'temperature_high',
        title: 'Temperature Too High',
        subtitle:
            'Grow room temperature reached '
            '${temp.toStringAsFixed(1)}°C. '
            'Recommended range is 25–28°C.',
        iconKey: 'thermostat',
        colorValue: 0xFFE76F51,
        severity: AlertSeverity.warning,
      );
    } else {
      _clearCondition('temperature_low');

      _clearCondition('temperature_high');
    }
  }

  // ------------------------------------------------------------
  // HUMIDITY
  // ------------------------------------------------------------

  static Future<void> _evaluateHumidity(SensorData data, DateTime now) async {
    final humidity = data.humidity;

    final healthy = _readingHealthy(data.humidityStatus, humidity, now);

    if (!healthy || humidity == null) {
      _clearCondition('humidity_low');
      _clearCondition('humidity_high');
      return;
    }

    if (humidity < humidityLowPct) {
      _clearCondition('humidity_high');

      await _activateCondition(
        key: 'humidity_low',
        title: 'Humidity Too Low',
        subtitle:
            'Relative humidity dropped to '
            '${humidity.toStringAsFixed(0)}%. '
            'Recommended range is 75–90%.',
        iconKey: 'water_drop',
        colorValue: 0xFF457B9D,
        severity: AlertSeverity.warning,
      );
    } else if (humidity > humidityHighPct) {
      _clearCondition('humidity_low');

      await _activateCondition(
        key: 'humidity_high',
        title: 'Humidity Too High',
        subtitle:
            'Relative humidity reached '
            '${humidity.toStringAsFixed(0)}%. '
            'Recommended range is 75–90%.',
        iconKey: 'water_drop',
        colorValue: 0xFFE76F51,
        severity: AlertSeverity.warning,
      );
    } else {
      _clearCondition('humidity_low');

      _clearCondition('humidity_high');
    }
  }

  // ------------------------------------------------------------
  // WATER LEVEL
  // ------------------------------------------------------------

  static Future<void> _evaluateWaterLevel(SensorData data, DateTime now) async {
    final threshold = waterLowPct;

    // Numeric low-water alert remains disabled until this threshold
    // matches the ESP32 refill-control threshold.
    if (threshold == null) {
      _clearCondition('water_low');
      return;
    }

    final level = data.waterLevel;

    final healthy = _readingHealthy(data.waterLevelStatus, level, now);

    if (!healthy || level == null) {
      _clearCondition('water_low');
      return;
    }

    if (level < threshold) {
      await _activateCondition(
        key: 'water_low',
        title: 'Low Water Level',
        subtitle:
            'Water level dropped to '
            '${level.toStringAsFixed(0)}%. '
            'Check the tank and refill system.',
        iconKey: 'opacity',
        colorValue: 0xFF264653,
        severity: AlertSeverity.warning,
      );
    } else {
      _clearCondition('water_low');
    }
  }

  // ------------------------------------------------------------
  // COMPONENT FAULTS
  // ------------------------------------------------------------

  static Future<void> _evaluateComponentFaults(SensorData data) async {
    const components = <String, String>{
      'humidifier': 'Humidifier',
      'uvLight': 'UV Light',
      'ventFan': 'Ventilation Fan',
      'baseFan': 'Base Fan',
      'loopPump': 'Loop Pump',
    };

    for (final entry in components.entries) {
      final componentKey = entry.key;
      final displayName = entry.value;

      final status = data.statusFor(componentKey);

      final fault = status.fault?.trim();

      final conditionKey = 'component_fault_$componentKey';

      if (fault != null && fault.isNotEmpty) {
        await _activateCondition(
          key: conditionKey,
          title: '$displayName Fault',
          subtitle: fault,
          iconKey: 'fault',
          colorValue: 0xFFB56576,
          severity: AlertSeverity.critical,
        );
      } else {
        _clearCondition(conditionKey);
      }
    }

    // Refill pump stores its fault inside its own state object.
    final refillFault = data.refillPump.fault?.trim();

    if (refillFault != null && refillFault.isNotEmpty) {
      await _activateCondition(
        key: 'component_fault_refillPump',
        title: 'Refill Pump Fault',
        subtitle: refillFault,
        iconKey: 'refillPump',
        colorValue: 0xFFB56576,
        severity: AlertSeverity.critical,
      );
    } else {
      _clearCondition('component_fault_refillPump');
    }
  }
}
