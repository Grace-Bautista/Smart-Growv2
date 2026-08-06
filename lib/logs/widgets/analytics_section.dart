import 'package:flutter/material.dart';
import '../models/sensor_history_record.dart';
import '../models/system_event_log.dart';
import 'environmental_chart.dart';

class AnalyticsSection extends StatefulWidget {
  const AnalyticsSection({
    super.key,
    required this.sensors,
    required this.events,
    required this.startDate,
    required this.endDate,
  });
  final List<SensorHistoryRecord> sensors;
  final List<SystemEventLog> events;
  final DateTime startDate, endDate;
  @override
  State<AnalyticsSection> createState() => _AnalyticsSectionState();
}

class _AnalyticsSectionState extends State<AnalyticsSection> {
  EnvironmentalMetric metric = EnvironmentalMetric.temperature;
  double? _average(
    double Function(SensorHistoryRecord) value,
    String validityKey,
  ) {
    final valid = widget.sensors
        .where((r) => r.validity[validityKey] != false)
        .toList();
    return valid.isEmpty
        ? null
        : valid.fold<double>(0, (sum, r) => sum + value(r)) / valid.length;
  }

  int _count(SystemEventType type) =>
      widget.events.where((e) => e.eventType == type).length;
  int get _activations => widget.events
      .where(
        (e) =>
            (e.eventType == SystemEventType.stateChanged ||
                e.eventType == SystemEventType.refillStarted) &&
            e.newValue == true,
      )
      .length;
  String _value(double? value, String suffix, [int decimals = 1]) =>
      value == null
      ? 'Unavailable'
      : '${value.toStringAsFixed(decimals)}$suffix';

  @override
  Widget build(BuildContext context) {
    final manual = widget.events
        .where((e) => e.source == 'manual_command')
        .length;
    final refill = _count(SystemEventType.refillStarted);
    final autoRefill = widget.events
        .where(
          (e) =>
              e.eventType == SystemEventType.refillStarted &&
              e.source == 'automatic_refill',
        )
        .length;
    final failed = _count(SystemEventType.commandFailed);
    return SingleChildScrollView(
      key: const ValueKey('analytics'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analytics',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF263A2A),
            ),
          ),
          const SizedBox(height: 16),
          _Grid(
            items: [
              _Metric(
                'Average Temperature',
                _value(
                  _average((r) => r.environmentTemp, 'environmentTemp'),
                  '°C',
                ),
                Icons.thermostat_outlined,
              ),
              _Metric(
                'Average Humidity',
                _value(_average((r) => r.humidity, 'humidity'), '%'),
                Icons.water_drop_outlined,
              ),
              _Metric(
                'Average CO₂',
                _value(_average((r) => r.co2, 'co2'), ' ppm', 0),
                Icons.air,
              ),
              _Metric('Manual Actions', '$manual', Icons.touch_app_outlined),
              _Metric(
                'Confirmed Commands',
                '${_count(SystemEventType.commandApplied)}',
                Icons.check_circle_outline,
              ),
              _Metric('Failed Commands', '$failed', Icons.error_outline),
              _Metric(
                'Component Activations',
                '$_activations',
                Icons.power_settings_new,
              ),
              _Metric(
                'Refill Activations',
                '$refill',
                Icons.local_drink_outlined,
              ),
              _Metric('Automatic Refills', '$autoRefill', Icons.autorenew),
              _Metric(
                'Sensor Invalid',
                '${_count(SystemEventType.sensorInvalid)}',
                Icons.sensors_off_outlined,
              ),
              _Metric(
                'Device Errors',
                '${widget.events.where((e) => e.severity == 'error').length}',
                Icons.warning_amber,
              ),
              const _Metric(
                'Average Refill Duration',
                'Unavailable',
                Icons.timer_outlined,
              ),
            ],
          ),
          const SizedBox(height: 20),
          EnvironmentalChart(
            records: widget.sensors,
            metric: metric,
            onMetricChanged: (v) => setState(() => metric = v),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _Metric {
  const _Metric(this.label, this.value, this.icon);
  final String label, value;
  final IconData icon;
}

class _Grid extends StatelessWidget {
  const _Grid({required this.items});

  final List<_Metric> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 600
            ? 2
            : 1;

        final width = (constraints.maxWidth - 10 * (columns - 1)) / columns;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items.map((item) {
            return SizedBox(
              width: width,
              child: Container(
                constraints: const BoxConstraints(minHeight: 88),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE0E8E1)),
                ),
                child: Row(
                  children: [
                    Icon(item.icon, color: const Color(0xFF537D42)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.value,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
