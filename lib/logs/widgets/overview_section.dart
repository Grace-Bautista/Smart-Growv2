import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/sensor_history_record.dart';
import '../repositories/logbook_repository.dart';
import 'environmental_chart.dart';

class OverviewSection extends StatefulWidget {
  const OverviewSection({
    super.key,
    required this.repository,
    required this.startDate,
    required this.endDate,
  });

  final LogBookRepository repository;
  final DateTime startDate;
  final DateTime endDate;
  @override
  State<OverviewSection> createState() => _OverviewSectionState();
}

class _OverviewSectionState extends State<OverviewSection> {
  EnvironmentalMetric _metric = EnvironmentalMetric.temperature;

  @override
  Widget build(
    BuildContext context,
  ) => FutureBuilder<List<SensorHistoryRecord>>(
    future: widget.repository.getSensorHistory(
      start: widget.startDate,
      end: widget.endDate,
    ),
    builder: (context, snapshot) {
      final records = snapshot.data ?? const <SensorHistoryRecord>[];
      final latest = records.isEmpty ? null : records.first;
      return SingleChildScrollView(
        key: const ValueKey('overview'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overview',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 18),
            _Panel(
              child: latest == null
                  ? const Text('No recorded data in this period.')
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Latest Recorded Data',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${DateFormat('MMMM d, y h:mm a').format(latest.timestamp)}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 28,
                          runSpacing: 10,
                          children: [
                            _Metric(
                              'Temperature',
                              '${latest.temperature.toStringAsFixed(1)}°C',
                            ),
                            _Metric(
                              'Humidity',
                              '${latest.humidity.toStringAsFixed(0)}%',
                            ),
                            _Metric(
                              'CO₂',
                              '${latest.co2.toStringAsFixed(0)} ppm',
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, box) {
                final width = box.maxWidth > 700
                    ? (box.maxWidth - 36) / 4
                    : box.maxWidth > 400
                    ? (box.maxWidth - 12) / 2
                    : box.maxWidth;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _Stat(
                      'Sensor Readings',
                      '${records.length}',
                      Icons.sensors,
                    ),
                    const _Stat(
                      'Humidifier Runtime',
                      '4h 20m',
                      Icons.water_drop_outlined,
                    ),
                    const _Stat('Water Used', '12.4 L', Icons.opacity),
                    const _Stat('System Events', '7', Icons.bolt_outlined),
                  ].map((item) => SizedBox(width: width, child: item)).toList(),
                );
              },
            ),
            const SizedBox(height: 14),
            EnvironmentalChart(
              records: records,
              metric: _metric,
              onMetricChanged: (value) => setState(() => _metric = value),
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
    },
  );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE0E8E1)),
    ),
    child: child,
  );
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext c) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(color: Colors.grey.shade600)),
      Text(
        value,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    ],
  );
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.icon);
  final String label, value;
  final IconData icon;
  @override
  Widget build(BuildContext c) => _Panel(
    child: Row(
      children: [
        Icon(icon, color: const Color.fromARGB(255, 127, 71, 34)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(label, style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ],
    ),
  );
}
