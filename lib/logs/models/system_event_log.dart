enum SystemEventType {
  humidifierOn,
  humidifierOff,
  fanOn,
  fanOff,
  uvOn,
  uvOff,
  rhTriggerDetected,
  rhReachedSetpoint,
  refillEvent,
  communicationError,
  systemError,
}

class SystemEventLog {
  const SystemEventLog({
    required this.id,
    required this.timestamp,
    required this.eventType,
    required this.description,
    this.trigger,
    this.expectedState,
    this.actualState,
    this.latencySeconds,
    this.recoveryTimeMinutes,
    this.packetCommunicationError = false,
    this.delaySeconds,
    this.errorCode,
  });

  final String id;
  final DateTime timestamp;
  final SystemEventType eventType;
  final String description;
  final String? trigger;
  final String? expectedState;
  final String? actualState;
  final int? latencySeconds;
  final int? recoveryTimeMinutes;
  final bool packetCommunicationError;
  final int? delaySeconds;
  final String? errorCode;
}
