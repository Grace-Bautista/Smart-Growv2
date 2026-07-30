import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/sensor_history_record.dart';
import '../models/system_event_log.dart';
import 'environmental_chart.dart';

class AnalyticsSection extends StatefulWidget {
  const AnalyticsSection({
    super.key,
    required this.sensors,
    required this.events,
  });
  final List<SensorHistoryRecord> sensors;
  final List<SystemEventLog> events;
  @override
  State<AnalyticsSection> createState() => _AnalyticsSectionState();
}

class _AnalyticsSectionState extends State<AnalyticsSection> {
  EnvironmentalMetric metric = EnvironmentalMetric.temperature;
  String range = '7 Days';
  @override
  Widget build(BuildContext c) {
    return SingleChildScrollView(
      key: const ValueKey('analytics'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analytics',
            style: Theme.of(
              c,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),

          Wrap(
            spacing: 8,
            children: ['Today', '7 Days', '30 Days', 'Custom']
                .map(
                  (x) => ChoiceChip(
                    label: Text(x),
                    selected: range == x,
                    onSelected: (_) => setState(() => range = x),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          _Group('Environmental Performance', [
            ['Average Temperature', '27.4°C'],
            ['Average Humidity', '78%'],
            ['Average CO₂', '424 ppm'],
          ]),
          _Group('Automation Performance', [
            ['Trigger Success Rate', '96%'],
            ['Average Latency', '2.1 sec'],
            ['Average Recovery Time', '4.8 min'],
          ]),
          _Group('Water Usage', [
            ['Total Water Used', '34.6 L'],
            ['Average Daily Usage', '11.5 L'],
            ['Refill Count', '1'],
          ]),
          _Group('Reliability', [
            ['Successful Events', '46'],
            ['Communication Errors', '1'],
            ['Delayed Events', '2'],
          ]),
          const SizedBox(height: 14),
          EnvironmentalChart(
            records: widget.sensors,
            metric: metric,
            onMetricChanged: (x) => setState(() => metric = x),
          ),
          const SizedBox(height: 14),
          _ChartCard(
            title: 'System Activity',
            child: BarChart(
              BarChartData(
                borderData: FlBorderData(show: false),
                barGroups: List.generate(
                  3,
                  (i) => BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: [9, 14, 11][i].toDouble(),
                        color: const Color(0xFF537D42),
                        width: 24,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            caption: 'Humidifier and system activations per day',
          ),
          const SizedBox(height: 14),
          _ChartCard(
            title: 'Reliability',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Reliability('Successful', 46, const Color(0xFF4E8D52)),
                _Reliability('Failed', 1, Colors.red.shade400),
                _Reliability('Delayed', 2, Colors.orange.shade700),
              ],
            ),
            caption: 'Communication and event outcomes',
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group(this.title, this.items);
  final String title;
  final List<List<String>> items;
  @override
  Widget build(BuildContext c) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items
              .map(
                (x) => Container(
                  width: 180,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE0E8E1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        x[1],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      Text(
                        x[0],
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ],
    ),
  );
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.child,
    required this.caption,
  });
  final String title, caption;
  final Widget child;
  @override
  Widget build(BuildContext c) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE0E8E1)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        Text(caption, style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 16),
        SizedBox(height: 160, child: child),
      ],
    ),
  );
}

class _Reliability extends StatelessWidget {
  const _Reliability(this.label, this.value, this.color);
  final String label;
  final int value;
  final Color color;
  @override
  Widget build(BuildContext c) => Column(
    children: [
      CircleAvatar(
        radius: 28,
        backgroundColor: color.withValues(alpha: .14),
        child: Text(
          '$value',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      const SizedBox(height: 7),
      Text(label),
    ],
  );
}
