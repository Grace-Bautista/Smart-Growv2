enum AutomationMode { automatic, manual, unknown }

enum CommandStatus { pending, applied, failed, unknown }

class SensorReadingStatus {
  const SensorReadingStatus({this.valid, this.updatedAt});

  final bool? valid;
  final DateTime? updatedAt;

  bool isFresh(DateTime now, {Duration maxAge = const Duration(seconds: 45)}) {
    final timestamp = updatedAt;
    return valid == true && timestamp != null && now.difference(timestamp) <= maxAge;
  }
}

/// Typed RTDB state for `liveData/smartGrow01`.
class SensorData {
  const SensorData({
    this.environmentTemperature,
    this.humidity,
    this.co2,
    this.waterLevel,
    this.humidifierTemperature,
    this.environmentTempStatus = const SensorReadingStatus(),
    this.humidityStatus = const SensorReadingStatus(),
    this.co2Status = const SensorReadingStatus(),
    this.waterLevelStatus = const SensorReadingStatus(),
    this.humidifierTempStatus = const SensorReadingStatus(),
    this.humidifierOn,
    this.ventFanOn,
    this.baseFanOn,
    this.refillPumpOn,
    this.loopPumpOn,
    this.uvLightOn,
    this.automationMode = AutomationMode.unknown,
    this.refillPumpMode = AutomationMode.unknown,
    this.deviceOnline,
    this.lastHeartbeat,
    this.bootId,
  });

  final double? environmentTemperature;
  final double? humidity;
  final double? co2;
  final double? waterLevel;
  final double? humidifierTemperature;
  final SensorReadingStatus environmentTempStatus;
  final SensorReadingStatus humidityStatus;
  final SensorReadingStatus co2Status;
  final SensorReadingStatus waterLevelStatus;
  final SensorReadingStatus humidifierTempStatus;
  final bool? humidifierOn;
  final bool? ventFanOn;
  final bool? baseFanOn;
  final bool? refillPumpOn;
  final bool? loopPumpOn;
  final bool? uvLightOn;
  final AutomationMode automationMode;
  final AutomationMode refillPumpMode;
  final bool? deviceOnline;
  final DateTime? lastHeartbeat;
  final String? bootId;

  bool isDeviceAvailable(DateTime now) {
    final heartbeat = lastHeartbeat;
    return heartbeat != null && now.difference(heartbeat) <= const Duration(seconds: 45);
  }

  factory SensorData.fromRealtimeValue(Object? value) {
    final root = _asMap(value);
    final sensors = _asMap(root['sensors']);
    final statuses = _asMap(root['sensorStatus']);
    final components = _asMap(root['components']);
    final automation = _asMap(root['automation']);
    final device = _asMap(root['device']);
    return SensorData(
      environmentTemperature: _asDouble(sensors['environmentTemp']),
      humidity: _asDouble(sensors['humidity']),
      co2: _asDouble(sensors['co2']),
      waterLevel: _asDouble(sensors['waterLevel']),
      humidifierTemperature: _asDouble(sensors['humidifierTemp']),
      environmentTempStatus: _status(statuses['environmentTemp']),
      humidityStatus: _status(statuses['humidity']),
      co2Status: _status(statuses['co2']),
      waterLevelStatus: _status(statuses['waterLevel']),
      humidifierTempStatus: _status(statuses['humidifierTemp']),
      humidifierOn: _asBool(components['humidifier']),
      ventFanOn: _asBool(components['ventFan']),
      baseFanOn: _asBool(components['baseFan']),
      refillPumpOn: _asBool(components['refillPump']),
      loopPumpOn: _asBool(components['loopPump']),
      uvLightOn: _asBool(components['uvLight']),
      automationMode: _automationMode(automation['mode']),
      refillPumpMode: _automationMode(automation['refillPumpMode']),
      deviceOnline: _asBool(device['online']),
      lastHeartbeat: _asDateTime(device['lastHeartbeat']),
      bootId: device['bootId']?.toString(),
    );
  }

  static SensorReadingStatus _status(Object? value) {
    final status = _asMap(value);
    return SensorReadingStatus(valid: _asBool(status['valid']), updatedAt: _asDateTime(status['updatedAt']));
  }

  static Map<Object?, Object?> _asMap(Object? value) => value is Map ? Map<Object?, Object?>.from(value) : const {};
  static double? _asDouble(Object? value) => value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '');
  static bool? _asBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    switch (value?.toString().toLowerCase()) {
      case 'true': case '1': return true;
      case 'false': case '0': return false;
      default: return null;
    }
  }
  static DateTime? _asDateTime(Object? value) => value is num ? DateTime.fromMillisecondsSinceEpoch(value.toInt()) : null;
  static AutomationMode _automationMode(Object? value) => switch (value?.toString().toLowerCase()) {
    'automatic' => AutomationMode.automatic,
    'manual' => AutomationMode.manual,
    _ => AutomationMode.unknown,
  };
}
