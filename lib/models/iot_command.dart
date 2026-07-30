import 'package:smart_grow_code/models/sensor_data.dart';

enum IotCommandTarget { humidifier, ventFan, baseFan, refillPump, refillPumpMode, loopPump, uvLight, automationMode }

extension IotCommandTargetPath on IotCommandTarget {
  String get path => name;
  bool get acceptsBoolean => switch (this) {
    IotCommandTarget.refillPumpMode || IotCommandTarget.automationMode => false,
    _ => true,
  };
}

class IotCommandState {
  const IotCommandState({this.commandId, this.status = CommandStatus.unknown, this.issuedAt, this.ttlMs, this.errorCode});
  final String? commandId;
  final CommandStatus status;
  final DateTime? issuedAt;
  final int? ttlMs;
  final String? errorCode;

  factory IotCommandState.fromRealtimeValue(Object? value) {
    final map = value is Map ? Map<Object?, Object?>.from(value) : const <Object?, Object?>{};
    final status = switch (map['status']?.toString()) {
      'pending' => CommandStatus.pending, 'applied' => CommandStatus.applied, 'failed' => CommandStatus.failed, _ => CommandStatus.unknown,
    };
    final issuedAt = map['issuedAt'];
    return IotCommandState(commandId: map['commandId']?.toString(), status: status,
      issuedAt: issuedAt is num ? DateTime.fromMillisecondsSinceEpoch(issuedAt.toInt()) : null,
      ttlMs: map['ttlMs'] is num ? (map['ttlMs'] as num).toInt() : null,
      errorCode: map['errorCode']?.toString());
  }

  bool isObjectivelyExpired(DateTime now) => status == CommandStatus.pending && issuedAt != null && ttlMs != null && now.isAfter(issuedAt!.add(Duration(milliseconds: ttlMs! + 2000)));
}
