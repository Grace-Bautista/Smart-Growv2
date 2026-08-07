import 'package:cloud_firestore/cloud_firestore.dart';
import 'sensor_history_record.dart';

enum SystemEventType {
  stateChanged,
  modeChanged,
  commandApplied,
  commandFailed,
  deviceOnline,
  deviceOffline,
  sensorInvalid,
  sensorRecovered,
  faultStarted,
  faultCleared,
  refillStarted,
  refillStopped,
  unknown,
}

class SystemEventLog {
  const SystemEventLog({
    required this.id,
    required this.deviceId,
    required this.timestamp,
    required this.eventType,
    required this.category,
    required this.message,
    this.component,
    this.previousValue,
    this.newValue,
    this.source,
    this.reason,
    this.commandId,
    this.requestedBy,
    this.bootId,
    this.severity = 'info',
    this.issuedAt,
    this.acknowledgedAt,
    this.isMock = false,
    this.seedBatchId,
  });
  final String id, deviceId, category, message, severity;
  final DateTime timestamp;
  final SystemEventType eventType;
  final String? component,
      source,
      reason,
      commandId,
      requestedBy,
      bootId,
      seedBatchId;
  final Object? previousValue, newValue;
  final DateTime? issuedAt, acknowledgedAt;
  final bool isMock;

  String get description => message;
  String? get trigger => reason;
  String? get expectedState => newValue?.toString();
  String? get actualState => newValue?.toString();
  int? get latencySeconds => issuedAt == null || acknowledgedAt == null
      ? null
      : acknowledgedAt!.difference(issuedAt!).inSeconds;
  int? get recoveryTimeMinutes => null;
  bool get packetCommunicationError => category == 'error';
  int? get delaySeconds => latencySeconds;
  String? get errorCode => reason;

  factory SystemEventLog.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) => SystemEventLog.fromMap(document.data() ?? const {}, id: document.id);
  factory SystemEventLog.fromMap(Map<String, dynamic> map, {String id = ''}) =>
      SystemEventLog(
        id: id,
        deviceId: _string(map, 'deviceId', required: true),
        timestamp: parseHistoryTimestamp(map['timestamp']),
        category: _string(map, 'category', required: true),
        eventType: _eventType(map['eventType']),
        message: _string(map, 'message', required: true),
        component: map['component']?.toString(),
        previousValue: _primitive(map['previousValue']),
        newValue: _primitive(map['newValue']),
        source: map['source']?.toString(),
        reason: map['reason']?.toString(),
        commandId: map['commandId']?.toString(),
        requestedBy: map['requestedBy']?.toString(),
        bootId: map['bootId']?.toString(),
        severity: map['severity']?.toString() ?? 'info',
        issuedAt: _optionalTime(map['issuedAt']),
        acknowledgedAt: _optionalTime(map['acknowledgedAt']),
        isMock: map['isMock'] == true,
        seedBatchId: map['seedBatchId']?.toString(),
      );
  Map<String, dynamic> toMap() => {
    'deviceId': deviceId,
    'timestamp': Timestamp.fromDate(timestamp),
    'category': category,
    'eventType': eventType.firestoreName,
    'message': message,
    'severity': severity,
    if (component != null) 'component': component,
    if (previousValue != null) 'previousValue': previousValue,
    if (newValue != null) 'newValue': newValue,
    if (source != null) 'source': source,
    if (reason != null) 'reason': reason,
    if (commandId != null) 'commandId': commandId,
    if (requestedBy != null) 'requestedBy': requestedBy,
    if (bootId != null) 'bootId': bootId,
    if (issuedAt != null) 'issuedAt': Timestamp.fromDate(issuedAt!),
    if (acknowledgedAt != null)
      'acknowledgedAt': Timestamp.fromDate(acknowledgedAt!),
    if (isMock) 'isMock': true,
    if (seedBatchId != null) 'seedBatchId': seedBatchId,
  };
}

String _string(Map<String, dynamic> map, String key, {bool required = false}) {
  final value = map[key];
  if (value is String && value.isNotEmpty) return value;
  if (required) throw FormatException('$key is required.');
  return '';
}

Object? _primitive(Object? value) =>
    value is String || value is bool || value is num ? value : null;
DateTime? _optionalTime(Object? value) {
  if (value == null) return null;
  try {
    return parseHistoryTimestamp(value);
  } on FormatException {
    return null;
  }
}

SystemEventType _eventType(Object? value) => SystemEventType.values.firstWhere(
  (e) => e.firestoreName == value,
  orElse: () => SystemEventType.unknown,
);

extension SystemEventTypeName on SystemEventType {
  String get firestoreName {
    final n = name;
    return n.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (m) => '_${m[0]!.toLowerCase()}',
    );
  }
}
