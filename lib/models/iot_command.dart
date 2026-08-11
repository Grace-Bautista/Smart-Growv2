enum IotCommandTarget { humidifier, uvLight, ventFan, refillPump }

extension IotCommandTargetPath on IotCommandTarget {
  String get path => name;
  bool get acceptsBoolean => this != IotCommandTarget.refillPump;
}

enum CommandStatus { pending, ack, applied, expired, rejected, unknown }

class IotCommandState {
  const IotCommandState({
    this.commandId,
    this.status = CommandStatus.unknown,
    this.issuedAt,
    this.ttlMs,
    this.lastError,
  });

  final String? commandId;
  final CommandStatus status;
  final DateTime? issuedAt;
  final int? ttlMs;
  final String? lastError;

  bool get isInProgress =>
      status == CommandStatus.pending || status == CommandStatus.ack;
  bool get isFailure =>
      status == CommandStatus.rejected || status == CommandStatus.expired;

  factory IotCommandState.fromRealtimeValue(Object? value) {
    final map = value is Map
        ? Map<Object?, Object?>.from(value)
        : const <Object?, Object?>{};
    final status = switch (map['status']?.toString().toLowerCase()) {
      'pending' => CommandStatus.pending,
      'ack' => CommandStatus.ack,
      'applied' => CommandStatus.applied,
      'expired' => CommandStatus.expired,
      'rejected' => CommandStatus.rejected,
      _ => CommandStatus.unknown,
    };
    final issuedAt = map['issuedAt'];
    return IotCommandState(
      commandId: map['commandId']?.toString(),
      status: status,
      issuedAt: issuedAt is num
          ? DateTime.fromMillisecondsSinceEpoch(issuedAt.toInt())
          : null,
      ttlMs: map['ttlMs'] is num ? (map['ttlMs'] as num).toInt() : null,
      lastError: (map['lastError'] ?? map['errorCode'])?.toString(),
    );
  }

  bool isObjectivelyExpired(DateTime now) {
    if (!isInProgress || issuedAt == null || ttlMs == null) return false;
    return now.isAfter(
      issuedAt!.add(Duration(milliseconds: ttlMs! + 2000)),
    );
  }
}
