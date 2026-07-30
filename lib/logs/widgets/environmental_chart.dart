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

    // Keep the most recent 36 readings.
    //
    // At one reading every 5 minutes:
    // 36 readings = 3 hours of sensor history.
    final visible = chronological.length > 36
        ? chronological.sublist(chronological.length - 36)
        : chronological;

    final values = visible.map(_value).toList();

    final min = values.isEmpty ? 0.0 : values.reduce((a, b) => a < b ? a : b);

    final max = values.isEmpty ? 100.0 : values.reduce((a, b) => a > b ? a : b);

    final range = max - min;

    final padding = range.abs() < 1 ? 2.0 : range * .20;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==========================================================
          // TITLE
          // ==========================================================
          const Text(
            'Environmental Trend',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4A4540),
            ),
          ),

          const SizedBox(height: 12),

          // ==========================================================
          // METRIC SELECTOR
          // ==========================================================
          _MetricSelector(selected: metric, onChanged: onMetricChanged),

          const SizedBox(height: 10),

          // Currently selected metric
          Text(
            _label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF8A8179),
            ),
          ),

          const SizedBox(height: 16),

          // ==========================================================
          // CHART
          // ==========================================================
          SizedBox(
            height: 210,
            child: values.isEmpty
                ? _EmptyChartState()
                : LineChart(
                    LineChartData(
                      minY: min - padding,
                      maxY: max + padding,

                      // ------------------------------------------------
                      // GRID
                      // ------------------------------------------------
                      gridData: FlGridData(
                        drawVerticalLine: false,
                        horizontalInterval: (range + padding * 2) / 4,
                        getDrawingHorizontalLine: (value) {
                          return const FlLine(
                            color: Color(0xFFEAE5E0),
                            strokeWidth: 1,
                          );
                        },
                      ),

                      borderData: FlBorderData(show: false),

                      // ------------------------------------------------
                      // AXIS TITLES
                      // ------------------------------------------------
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(),
                        rightTitles: const AxisTitles(),

                        // Y AXIS
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 38,
                            interval: (range + padding * 2) / 4,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toStringAsFixed(
                                  metric == EnvironmentalMetric.co2 ? 0 : 1,
                                ),
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Color(0xFF817A73),
                                ),
                              );
                            },
                          ),
                        ),

                        // X AXIS
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,

                            // We still plot every reading,
                            // but only show a few labels.
                            interval: visible.length <= 1
                                ? 1
                                : (visible.length / 4).ceilToDouble(),

                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();

                              if (index < 0 || index >= visible.length) {
                                return const SizedBox();
                              }

                              return Padding(
                                padding: const EdgeInsets.only(top: 7),
                                child: Text(
                                  DateFormat(
                                    'HH:mm',
                                  ).format(visible[index].timestamp),
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Color(0xFF817A73),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      // ==================================================
                      // LINE
                      // ==================================================
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(visible.length, (index) {
                            return FlSpot(
                              index.toDouble(),
                              _value(visible[index]),
                            );
                          }),

                          isCurved: true,

                          color: _color,

                          barWidth: 2.5,

                          isStrokeCapRound: true,
                          isStrokeJoinRound: true,

                          dotData: const FlDotData(show: false),

                          // Subtle graph fill
                          belowBarData: BarAreaData(
                            show: true,
                            color: _color.withValues(alpha: 0.10),
                          ),
                        ),
                      ],

                      clipData: const FlClipData.all(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ======================================================================
// METRIC SELECTOR
// ======================================================================

class _MetricSelector extends StatelessWidget {
  const _MetricSelector({required this.selected, required this.onChanged});

  final EnvironmentalMetric selected;
  final ValueChanged<EnvironmentalMetric> onChanged;

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
          _MetricButton(
            label: 'Temperature',
            selected: selected == EnvironmentalMetric.temperature,
            onTap: () {
              onChanged(EnvironmentalMetric.temperature);
            },
          ),

          _MetricButton(
            label: 'Humidity',
            selected: selected == EnvironmentalMetric.humidity,
            onTap: () {
              onChanged(EnvironmentalMetric.humidity);
            },
          ),

          _MetricButton(
            label: 'CO₂',
            selected: selected == EnvironmentalMetric.co2,
            onTap: () {
              onChanged(EnvironmentalMetric.co2);
            },
          ),
        ],
      ),
    );
  }
}

// ======================================================================
// INDIVIDUAL METRIC BUTTON
// ======================================================================

class _MetricButton extends StatelessWidget {
  const _MetricButton({
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

// ======================================================================
// EMPTY CHART STATE
// ======================================================================

class _EmptyChartState extends StatelessWidget {
  const _EmptyChartState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: const BoxDecoration(
              color: Color(0xFFF3EFEB),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.show_chart_rounded,
              size: 22,
              color: Color(0xFFC47A45),
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            'No readings in this period',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF817A73),
            ),
          ),
        ],
      ),
    );
  }
}

// ======================================================================
// PANEL
// ======================================================================

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: const Color(0xFFE5DED7)),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
