import 'package:cloud_firestore/cloud_firestore.dart';

class SensorHistoryRecord {
  const SensorHistoryRecord({
    required this.id,
    required this.deviceId,
    required this.timestamp,
    required this.environmentTemp,
    required this.humidity,
    required this.co2,
    required this.waterLevel,
    required this.humidifierTemp,
    required this.validity,
    this.bootId,
    this.isMock = false,
    this.seedBatchId,
  });

  final String id;
  final String deviceId;
  final DateTime timestamp;
  final double environmentTemp, humidity, co2, waterLevel, humidifierTemp;
  final Map<String, bool> validity;
  final String? bootId;
  final bool isMock;
  final String? seedBatchId;

  double get temperature => environmentTemp;

  factory SensorHistoryRecord.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) =>
      SensorHistoryRecord.fromMap(document.data() ?? const {}, id: document.id);

  factory SensorHistoryRecord.fromMap(
    Map<String, dynamic> map, {
    String id = '',
  }) {
    return SensorHistoryRecord(
      id: id,
      deviceId: _requiredString(map, 'deviceId'),
      timestamp: parseHistoryTimestamp(map['timestamp']),
      environmentTemp: _number(map, 'environmentTemp'),
      humidity: _number(map, 'humidity'),
      co2: _number(map, 'co2'),
      waterLevel: _number(map, 'waterLevel'),
      humidifierTemp: _number(map, 'humidifierTemp'),
      validity: _validity(map['validity']),
      bootId: map['bootId']?.toString(),
      isMock: map['isMock'] == true,
      seedBatchId: map['seedBatchId']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'deviceId': deviceId,
    'timestamp': Timestamp.fromDate(timestamp),
    'environmentTemp': environmentTemp,
    'humidity': humidity,
    'co2': co2,
    'waterLevel': waterLevel,
    'humidifierTemp': humidifierTemp,
    'validity': validity,
    if (bootId != null) 'bootId': bootId,
    if (isMock) 'isMock': true,
    if (seedBatchId != null) 'seedBatchId': seedBatchId,
  };
}

DateTime parseHistoryTimestamp(dynamic value) {
  if (value is Timestamp) {
    return value.toDate().toUtc();
  }

  if (value is DateTime) {
    return value.toUtc();
  }

  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
  }

  throw const FormatException('Missing or invalid history timestamp');
}

String _requiredString(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value is String && value.isNotEmpty) return value;
  throw FormatException('$key is required.');
}

double _number(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value is num) return value.toDouble();
  throw FormatException('$key must be numeric.');
}

Map<String, bool> _validity(Object? value) {
  if (value is! Map) return const {};
  return Map<String, bool>.unmodifiable({
    for (final entry in value.entries)
      if (entry.value is bool) entry.key.toString(): entry.value as bool,
  });
}
