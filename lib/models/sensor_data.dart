const Duration deviceHeartbeatTimeout = Duration(seconds: 45);

class SensorReadingStatus {
  const SensorReadingStatus({this.valid, this.updatedAt});
  final bool? valid;
  final DateTime? updatedAt;

  bool isFresh(DateTime now, {Duration maxAge = const Duration(seconds: 45)}) {
    // Status metadata is optional in the final contract. A missing status does
    // not hide an otherwise valid live reading.
    if (valid == null && updatedAt == null) return true;
    return valid == true &&
        updatedAt != null &&
        now.difference(updatedAt!) <= maxAge;
  }
}

class ComponentStatus {
  const ComponentStatus({this.updatedAt, this.fault});
  final DateTime? updatedAt;
  final String? fault;
}

class RefillPumpState {
  const RefillPumpState({
    this.mode,
    this.running,
    this.reason,
    this.startedAt,
    this.lastChangedAt,
    this.fault,
  });
  final String? mode;
  final bool? running;
  final String? reason;
  final DateTime? startedAt;
  final DateTime? lastChangedAt;
  final String? fault;
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
    this.loopPumpOn,
    this.uvLightOn,
    this.refillPump = const RefillPumpState(),
    this.componentStatuses = const {},
    this.deviceOnline,
    this.lastHeartbeat,
    this.bootId,
    this.firmwareVersion,
  });

  final double? environmentTemperature, humidity, co2, waterLevel;
  final double? humidifierTemperature;
  final SensorReadingStatus environmentTempStatus, humidityStatus, co2Status;
  final SensorReadingStatus waterLevelStatus, humidifierTempStatus;
  final bool? humidifierOn, ventFanOn, baseFanOn, loopPumpOn, uvLightOn;
  final RefillPumpState refillPump;
  final Map<String, ComponentStatus> componentStatuses;
  final bool? deviceOnline;
  final DateTime? lastHeartbeat;
  final String? bootId, firmwareVersion;

  // Compatibility for existing diagnostics/settings screens.
  bool? get refillPumpOn => refillPump.running;
  String get refillPumpMode => refillPump.mode ?? 'unknown';

  ComponentStatus statusFor(String component) =>
      componentStatuses[component] ?? const ComponentStatus();

  bool isDeviceAvailable(DateTime now) {
    final heartbeat = lastHeartbeat;
    if (deviceOnline != true || heartbeat == null) return false;
    final age = now.difference(heartbeat);
    return !age.isNegative && age <= deviceHeartbeatTimeout;
  }

  factory SensorData.fromRealtimeValue(Object? value) {
    final root = _asMap(value);
    final sensors = _asMap(root['sensors']);
    final statuses = _asMap(root['sensorStatus']);
    final components = _asMap(root['components']);
    final componentStatus = _asMap(root['componentStatus']);
    final device = _asMap(root['device']);
    final refill = _asMap(components['refillPump']);
    final parsedStatuses = <String, ComponentStatus>{};
    for (final name in ['humidifier', 'uvLight', 'ventFan', 'baseFan', 'loopPump']) {
      final status = _asMap(componentStatus[name]);
      parsedStatuses[name] = ComponentStatus(
        updatedAt: _asDateTime(status['updatedAt']),
        fault: _nullableString(status['fault']),
      );
    }
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
      loopPumpOn: _asBool(components['loopPump']),
      uvLightOn: _asBool(components['uvLight']),
      refillPump: RefillPumpState(
        mode: _nullableString(refill['mode']),
        running: _asBool(refill['running']),
        reason: _nullableString(refill['reason']),
        startedAt: _asDateTime(refill['startedAt']),
        lastChangedAt: _asDateTime(refill['lastChangedAt']),
        fault: _nullableString(refill['fault']),
      ),
      componentStatuses: parsedStatuses,
      deviceOnline: _asBool(device['online']),
      lastHeartbeat: _asDateTime(device['lastHeartbeat']),
      bootId: _nullableString(device['bootId']),
      firmwareVersion: _nullableString(device['firmwareVersion']),
    );
  }

  static SensorReadingStatus _status(Object? value) {
    final status = _asMap(value);
    return SensorReadingStatus(
      valid: _asBool(status['valid']),
      updatedAt: _asDateTime(status['updatedAt']),
    );
  }
  static Map<Object?, Object?> _asMap(Object? value) =>
      value is Map ? Map<Object?, Object?>.from(value) : const {};
  static double? _asDouble(Object? value) =>
      value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '');
  static bool? _asBool(Object? value) => value is bool ? value : null;
  static DateTime? _asDateTime(Object? value) => value is num
      ? DateTime.fromMillisecondsSinceEpoch(value.toInt())
      : null;
  static String? _nullableString(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}
