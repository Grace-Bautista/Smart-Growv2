/// A typed representation of the current state at
/// `liveData/smartGrow01` in Firebase Realtime Database.
enum RefillPumpMode { on, off, auto, unknown }

class SensorData {
  const SensorData({
    this.environmentTemperature,
    this.humidity,
    this.co2,
    this.waterLevel,
    this.humidifierTemperature,
    this.humidifierOn,
    this.ventFanOn,
    this.baseFanOn,
    this.refillPumpMode,
    this.loopPumpOn,
    this.uvLightOn,
    this.automationMode,
    this.deviceOnline,
    this.lastHeartbeat,
  });

  final double? environmentTemperature;
  final double? humidity;
  final double? co2;
  final double? waterLevel;
  final double? humidifierTemperature;
  final bool? humidifierOn;
  final bool? ventFanOn;
  final bool? baseFanOn;
  final RefillPumpMode? refillPumpMode;
  final bool? loopPumpOn;
  final bool? uvLightOn;
  final String? automationMode;
  final bool? deviceOnline;
  final DateTime? lastHeartbeat;

  /// Converts the untyped value supplied by Realtime Database into [SensorData].
  factory SensorData.fromRealtimeValue(Object? value) {
    final root = _asMap(value);
    final sensors = _asMap(root['sensors']);
    final components = _asMap(root['components']);
    final automation = _asMap(root['automation']);
    final device = _asMap(root['device']);

    return SensorData(
      environmentTemperature: _asDouble(sensors['environmentTemp']),
      humidity: _asDouble(sensors['humidity']),
      co2: _asDouble(sensors['co2']),
      waterLevel: _asDouble(sensors['waterLevel']),
      humidifierTemperature: _asDouble(sensors['humidifierTemp']),
      humidifierOn: _asBool(components['humidifier']),
      ventFanOn: _asBool(components['ventFan']),
      baseFanOn: _asBool(components['baseFan']),
      refillPumpMode: _asRefillPumpMode(components['refillPump']),
      loopPumpOn: _asBool(components['loopPump']),
      uvLightOn: _asBool(components['uvLight']),
      automationMode: automation['mode']?.toString(),
      deviceOnline: _asBool(device['online']),
      lastHeartbeat: _asDateTime(device['lastHeartbeat']),
    );
  }

  static Map<Object?, Object?> _asMap(Object? value) {
    if (value is Map) {
      return Map<Object?, Object?>.from(value);
    }
    return const {};
  }

  static double? _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static bool? _asBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.toLowerCase();
      if (normalized == 'true' || normalized == '1' || normalized == 'on') {
        return true;
      }
      if (normalized == 'false' || normalized == '0' || normalized == 'off') {
        return false;
      }
    }
    return null;
  }

  static RefillPumpMode? _asRefillPumpMode(Object? value) {
    if (value == null) return null;

    return switch (value.toString().toLowerCase()) {
      'on' => RefillPumpMode.on,
      'off' => RefillPumpMode.off,
      'auto' => RefillPumpMode.auto,
      _ => RefillPumpMode.unknown,
    };
  }

  static DateTime? _asDateTime(Object? value) {
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    return null;
  }
}
