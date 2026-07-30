import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/sensor_history_record.dart';
import '../models/system_event_log.dart';

class HistoryEntryCard extends StatelessWidget {
  const HistoryEntryCard.sensor({super.key, required this.record}) : event = null;
  const HistoryEntryCard.event({super.key, required this.event}) : record = null;

  final SensorHistoryRecord? record;
  final SystemEventLog? event;

  @override
  Widget build(BuildContext context) {
    final isSensor = record != null;
    final timestamp = isSensor ? record!.timestamp : event!.timestamp;
    final accent = isSensor ? const Color(0xFF2B8CBE) : const Color(0xFF537D42);
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 74, child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Text(DateFormat('h:mm a').format(timestamp), style: const TextStyle(fontWeight: FontWeight.w700)),
      )),
      Container(width: 2, height: isSensor ? 88 : 112, color: accent.withValues(alpha: .45)),
      const SizedBox(width: 12),
      Expanded(
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE0E8E1)),
          ),
          child: isSensor ? _sensorBody(record!) : _eventBody(event!, accent),
        ),
      ),
    ]);
  }

  Widget _sensorBody(SensorHistoryRecord item) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Row(children: [Icon(Icons.thermostat_outlined, size: 18), SizedBox(width: 7), Text('Environment Reading', style: TextStyle(fontWeight: FontWeight.w700))]),
    const SizedBox(height: 8),
    Text('${item.temperature.toStringAsFixed(1)}°C  ·  ${item.humidity.toStringAsFixed(0)}%  ·  ${item.co2.toStringAsFixed(0)} ppm'),
  ]);

  Widget _eventBody(SystemEventLog item, Color accent) => ExpansionTile(
    tilePadding: EdgeInsets.zero,
    childrenPadding: const EdgeInsets.only(top: 8),
    leading: Icon(_eventIcon(item.eventType), color: accent),
    title: Text(_eventLabel(item.eventType), style: const TextStyle(fontWeight: FontWeight.w700)),
    subtitle: Text(item.description),
    children: [_eventDetails(item)],
  );

  Widget _eventDetails(SystemEventLog item) {
    final details = <String>[
      if (item.trigger != null) 'Trigger: ${item.trigger}',
      if (item.expectedState != null) 'Expected: ${item.expectedState}',
      if (item.actualState != null) 'Actual: ${item.actualState}',
      if (item.latencySeconds != null) 'Latency: ${item.latencySeconds} sec',
      if (item.recoveryTimeMinutes != null) 'Recovery time: ${item.recoveryTimeMinutes} min',
      if (item.delaySeconds != null) 'Delay: ${item.delaySeconds} sec',
      if (item.errorCode != null) 'Error code: ${item.errorCode}',
    ];
    return Align(alignment: Alignment.centerLeft, child: Text(details.join('\n'), style: TextStyle(color: Colors.grey.shade700)));
  }
}

IconData _eventIcon(SystemEventType type) => switch (type) {
  SystemEventType.humidifierOn || SystemEventType.humidifierOff => Icons.water_drop_outlined,
  SystemEventType.fanOn || SystemEventType.fanOff => Icons.air,
  SystemEventType.uvOn || SystemEventType.uvOff => Icons.light_mode_outlined,
  SystemEventType.communicationError || SystemEventType.systemError => Icons.error_outline,
  _ => Icons.bolt_outlined,
};

String _eventLabel(SystemEventType type) => switch (type) {
  SystemEventType.humidifierOn => 'Humidifier ON', SystemEventType.humidifierOff => 'Humidifier OFF',
  SystemEventType.fanOn => 'Fan ON', SystemEventType.fanOff => 'Fan OFF', SystemEventType.uvOn => 'UV ON', SystemEventType.uvOff => 'UV OFF',
  SystemEventType.rhTriggerDetected => 'RH trigger detected', SystemEventType.rhReachedSetpoint => 'RH reached setpoint',
  SystemEventType.refillEvent => 'Refill event', SystemEventType.communicationError => 'Communication error', SystemEventType.systemError => 'System error',
};
