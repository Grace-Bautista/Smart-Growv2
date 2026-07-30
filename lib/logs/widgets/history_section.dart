import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/sensor_history_record.dart';
import '../models/system_event_log.dart';

enum HistoryCategory { all, environment, events }

class HistorySection extends StatefulWidget {
  const HistorySection({
    super.key,
    required this.sensors,
    required this.events,
    required this.startDate,
    required this.endDate,
  });

  final List<SensorHistoryRecord> sensors;
  final List<SystemEventLog> events;
  final DateTime startDate;
  final DateTime endDate;
  @override
  State<HistorySection> createState() => _HistorySectionState();
}

class _HistorySectionState extends State<HistorySection> {
  HistoryCategory category = HistoryCategory.all;

  @override
  Widget build(BuildContext context) {
    final rows = <_Row>[];
    if (category != HistoryCategory.events) {
      rows.addAll(
        widget.sensors
            .where(
              (x) =>
                  !x.timestamp.isBefore(widget.startDate) &&
                  !x.timestamp.isAfter(widget.endDate),
            )
            .map(_Row.sensor),
      );
    }
    if (category != HistoryCategory.environment) {
      rows.addAll(
        widget.events
            .where(
              (x) =>
                  !x.timestamp.isBefore(widget.startDate) &&
                  !x.timestamp.isAfter(widget.endDate),
            )
            .map(_Row.event),
      );
    }
    rows.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final groups = <DateTime, List<_Row>>{};
    for (final row in rows) {
      final d = DateTime(
        row.timestamp.year,
        row.timestamp.month,
        row.timestamp.day,
      );
      groups.putIfAbsent(d, () => []).add(row);
    }
    return SingleChildScrollView(
      key: const ValueKey('history'),
      child: Column(
        children: [
          Text(
            'History Logs',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),

          const SizedBox(height: 10),
          _HistoryCategorySelector(
            selected: category,
            onChanged: (value) {
              setState(() => category = value);
            },
          ),
          const SizedBox(height: 20),
          if (rows.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No logs in this date range.'),
              ),
            )
          else
            ...groups.entries.map(
              (group) => _DateGroup(date: group.key, rows: group.value),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _HistoryCategorySelector extends StatelessWidget {
  const _HistoryCategorySelector({
    required this.selected,
    required this.onChanged,
  });

  final HistoryCategory selected;
  final ValueChanged<HistoryCategory> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 42,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EFEB),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFE5DED7)),
      ),
      child: Row(
        children: [
          _HistoryCategoryButton(
            label: 'All',
            selected: selected == HistoryCategory.all,
            onTap: () => onChanged(HistoryCategory.all),
          ),

          _HistoryCategoryButton(
            label: 'Environment',
            selected: selected == HistoryCategory.environment,
            onTap: () => onChanged(HistoryCategory.environment),
          ),

          _HistoryCategoryButton(
            label: 'System Events',
            selected: selected == HistoryCategory.events,
            onTap: () => onChanged(HistoryCategory.events),
          ),
        ],
      ),
    );
  }
}

class _HistoryCategoryButton extends StatelessWidget {
  const _HistoryCategoryButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFC47A45) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? Colors.white : const Color(0xFF6F6861),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Row {
  _Row.sensor(SensorHistoryRecord x)
    : timestamp = x.timestamp,
      sensor = x,
      event = null;
  _Row.event(SystemEventLog x)
    : timestamp = x.timestamp,
      event = x,
      sensor = null;
  final DateTime timestamp;
  final SensorHistoryRecord? sensor;
  final SystemEventLog? event;
}

class _DateGroup extends StatelessWidget {
  const _DateGroup({required this.date, required this.rows});
  final DateTime date;
  final List<_Row> rows;
  @override
  Widget build(BuildContext c) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFE5EFE4),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          DateFormat('MMMM d, y').format(date),
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF355C36),
          ),
        ),
      ),
      const SizedBox(height: 8),
      ...rows.map((row) => _Entry(row: row)),
      const SizedBox(height: 18),
    ],
  );
}

class _Entry extends StatelessWidget {
  const _Entry({required this.row});
  final _Row row;
  IconData get _icon => row.sensor != null
      ? Icons.thermostat_outlined
      : (row.event!.packetCommunicationError
            ? Icons.error_outline
            : Icons.bolt_outlined);
  @override
  Widget build(BuildContext c) {
    final sensor = row.sensor;
    final event = row.event;
    return Container(
      margin: const EdgeInsets.only(left: 8, bottom: 8),
      padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: sensor != null
                ? const Color(0xFF2B8CBE)
                : const Color(0xFF537D42),
            width: 3,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _icon,
            color: sensor != null
                ? const Color(0xFF2B8CBE)
                : const Color(0xFF537D42),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: sensor != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('h:mm a').format(row.timestamp),
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const Text(
                        'Environment Reading',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${sensor.temperature.toStringAsFixed(1)}°C  ·  ${sensor.humidity.toStringAsFixed(0)}%  ·  ${sensor.co2.toStringAsFixed(0)} ppm',
                      ),
                    ],
                  )
                : ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: EdgeInsets.zero,
                    title: Text(
                      event!.description,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${DateFormat('h:mm a').format(row.timestamp)}${event.trigger == null ? '' : ' · ${event.trigger}'}',
                    ),
                    children: [_EventDetails(event: event)],
                  ),
          ),
        ],
      ),
    );
  }
}

class _EventDetails extends StatelessWidget {
  const _EventDetails({required this.event});
  final SystemEventLog event;
  @override
  Widget build(BuildContext c) {
    final details = <String>[
      if (event.expectedState != null) 'Expected: ${event.expectedState}',
      if (event.actualState != null) 'Actual: ${event.actualState}',
      if (event.latencySeconds != null) 'Latency: ${event.latencySeconds} sec',
      if (event.recoveryTimeMinutes != null)
        'Recovery: ${event.recoveryTimeMinutes} min',
      if (event.delaySeconds != null) 'Delay: ${event.delaySeconds} sec',
      if (event.errorCode != null) 'Error code: ${event.errorCode}',
    ];
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        details.join(' · '),
        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
      ),
    );
  }
}
