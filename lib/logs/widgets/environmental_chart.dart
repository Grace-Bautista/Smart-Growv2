import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/sensor_history_record.dart';

enum EnvironmentalMetric { temperature, humidity, co2 }

class EnvironmentalChart extends StatelessWidget {
  const EnvironmentalChart({
    super.key,
    required this.records,
    required this.metric,
    required this.onMetricChanged,
  });
  final List<SensorHistoryRecord> records;
  final EnvironmentalMetric metric;
  final ValueChanged<EnvironmentalMetric> onMetricChanged;

  double _value(SensorHistoryRecord record) => switch (metric) {
    EnvironmentalMetric.temperature => record.temperature,
    EnvironmentalMetric.humidity => record.humidity,
    EnvironmentalMetric.co2 => record.co2,
  };
  String get _label => switch (metric) {
    EnvironmentalMetric.temperature => 'Temperature (°C)',
    EnvironmentalMetric.humidity => 'Humidity (%)',
    EnvironmentalMetric.co2 => 'CO₂ (ppm)',
  };
  Color get _color => switch (metric) {
    EnvironmentalMetric.temperature => const Color(0xFFE07A3F),
    EnvironmentalMetric.humidity => const Color(0xFF2B8CBE),
    EnvironmentalMetric.co2 => const Color(0xFF537D42),
  };

  @override
  Widget build(BuildContext context) {
    final chronological = [...records]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final visible = chronological.length > 36
        ? chronological.sublist(chronological.length - 36)
        : chronological;
    final values = visible.map(_value).toList();
    final min = values.isEmpty ? 0.0 : values.reduce((a, b) => a < b ? a : b);
    final max = values.isEmpty ? 100.0 : values.reduce((a, b) => a > b ? a : b);
    final padding = (max - min).abs() < 1 ? 2.0 : (max - min) * .25;
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Environmental Trend',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              SegmentedButton<EnvironmentalMetric>(
                segments: const [
                  ButtonSegment(
                    value: EnvironmentalMetric.temperature,
                    label: Text('Temperature'),
                  ),
                  ButtonSegment(
                    value: EnvironmentalMetric.humidity,
                    label: Text('Humidity'),
                  ),
                  ButtonSegment(
                    value: EnvironmentalMetric.co2,
                    label: Text('CO₂'),
                  ),
                ],
                selected: {metric},
                onSelectionChanged: (value) => onMetricChanged(value.first),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('$_label', style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 18),
          SizedBox(
            height: 220,
            child: values.isEmpty
                ? const Center(child: Text('No readings in this period'))
                : LineChart(
                    LineChartData(
                      minY: min - padding,
                      maxY: max + padding,
                      gridData: FlGridData(
                        drawVerticalLine: false,
                        horizontalInterval: (max - min + padding * 2) / 4,
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(),
                        rightTitles: const AxisTitles(),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 42,
                            getTitlesWidget: (v, _) => Text(
                              v.toStringAsFixed(
                                metric == EnvironmentalMetric.co2 ? 0 : 1,
                              ),
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: (visible.length / 4).ceilToDouble(),
                            getTitlesWidget: (v, _) {
                              final i = v.toInt();
                              return i >= 0 && i < visible.length
                                  ? Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        DateFormat(
                                          'HH:mm',
                                        ).format(visible[i].timestamp),
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    )
                                  : const SizedBox();
                            },
                          ),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(
                            visible.length,
                            (i) => FlSpot(i.toDouble(), _value(visible[i])),
                          ),
                          isCurved: true,
                          color: _color,
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: _color.withValues(alpha: .12),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
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
      boxShadow: const [
        BoxShadow(
          color: Color(0x10000000),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );
}
