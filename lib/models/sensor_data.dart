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
    this.dht11Temperature,
    this.dht11Humidity,
    this.sht30Temperature,
    this.sht30Humidity,
    this.scd40Co2,
    this.waterLevel,
    //sensor statuses
this.dht11TemperatureStatus = const SensorReadingStatus(),
this.dht11HumidityStatus = const SensorReadingStatus(),
this.sht30TemperatureStatus = const SensorReadingStatus(),
this.sht30HumidityStatus = const SensorReadingStatus(),
this.scd40Co2Status = const SensorReadingStatus(),
this.waterLevelStatus = const SensorReadingStatus(),
    // this.humidifierTempStatus = const SensorReadingStatus(),
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

  //sensor readings
final double?
    dht11Temperature,
    dht11Humidity,
    sht30Temperature,
    sht30Humidity,
    scd40Co2,
    waterLevel;
// sensor statuses
final SensorReadingStatus
    dht11TemperatureStatus,
    dht11HumidityStatus,
    sht30TemperatureStatus,
    sht30HumidityStatus,
    scd40Co2Status,
    waterLevelStatus; 
// components Status;
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
    for (final name in [
      'humidifier',
      'uvLight',
      'ventFan',
      'baseFan',
      'loopPump',
    ]) {
      final status = _asMap(componentStatus[name]);
      parsedStatuses[name] = ComponentStatus(
        updatedAt: _asDateTime(status['updatedAt']),
        fault: _nullableString(status['fault']),
      );
    }
    return SensorData(
      dht11Temperature: _asDouble(_asMap(sensors['dht11'])['temperature']),
      dht11Humidity: _asDouble(_asMap(sensors['dht11'])['humidity']),
      sht30Temperature: _asDouble(_asMap(sensors['sht30'])['temperature']),
      sht30Humidity: _asDouble(_asMap(sensors['sht30'])['humidity']),
      scd40Co2: _asDouble(_asMap(sensors['scd40'])['co2']),
      waterLevel: _asDouble(sensors['waterLevel']),
      dht11TemperatureStatus: _status( _asMap(statuses['dht11'])['temperature'], ), dht11HumidityStatus: _status( _asMap(statuses['dht11'])['humidity'], ), sht30TemperatureStatus: _status( _asMap(statuses['sht30'])['temperature'], ), sht30HumidityStatus: _status( _asMap(statuses['sht30'])['humidity'], ), scd40Co2Status: _status( _asMap(statuses['scd40'])['co2'], ),
      waterLevelStatus: _status(statuses['waterLevel']),
      //humidifierTempStatus: _status(statuses['humidifierTemp']),
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
  static double? _asDouble(Object? value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '');
  static bool? _asBool(Object? value) => value is bool ? value : null;
  static DateTime? _asDateTime(Object? value) =>
      value is num ? DateTime.fromMillisecondsSinceEpoch(value.toInt()) : null;
  static String? _nullableString(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}
