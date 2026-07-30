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
    required this.startDate,
    required this.endDate,
  });

  final List<SensorHistoryRecord> sensors;
  final List<SystemEventLog> events;
  final DateTime startDate;
  final DateTime endDate;
  @override
  State<AnalyticsSection> createState() => _AnalyticsSectionState();
}

class _AnalyticsSectionState extends State<AnalyticsSection> {
  EnvironmentalMetric metric = EnvironmentalMetric.temperature;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('analytics'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ------------------------------------------------------------
          // HEADER
          // ------------------------------------------------------------
          Text(
            'Analytics',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF263A2A),
            ),
          ),

          const SizedBox(height: 10),

          // ------------------------------------------------------------
          // ENVIRONMENTAL PERFORMANCE
          // ------------------------------------------------------------
          const _SectionTitle(
            title: 'Environmental Performance',
            subtitle: 'Average environmental conditions',
          ),

          const SizedBox(height: 10),

          _MetricGrid(
            items: const [
              _MetricData(
                label: 'Average Temperature',
                value: '27.4°C',
                icon: Icons.thermostat_outlined,
                color: Color(0xFFE07A3F),
              ),
              _MetricData(
                label: 'Average Humidity',
                value: '78%',
                icon: Icons.water_drop_outlined,
                color: Color(0xFF2B8CBE),
              ),
              _MetricData(
                label: 'Average CO₂',
                value: '424 ppm',
                icon: Icons.air_outlined,
                color: Color(0xFF537D42),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ------------------------------------------------------------
          // AUTOMATION PERFORMANCE
          // ------------------------------------------------------------
          const _SectionTitle(
            title: 'Automation Performance',
            subtitle: 'How reliably the system responds to triggers',
          ),

          const SizedBox(height: 10),

          _MetricGrid(
            items: const [
              _MetricData(
                label: 'Trigger Success Rate',
                value: '96%',
                icon: Icons.check_circle_outline,
                color: Color(0xFF4E8D52),
              ),
              _MetricData(
                label: 'Average Latency',
                value: '2.1 sec',
                icon: Icons.speed_outlined,
                color: Color(0xFF537D42),
              ),
              _MetricData(
                label: 'Average Recovery',
                value: '4.8 min',
                icon: Icons.restore_outlined,
                color: Color(0xFFD28A32),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ------------------------------------------------------------
          // WATER USAGE
          // ------------------------------------------------------------
          const _SectionTitle(
            title: 'Water Usage',
            subtitle: 'Water consumption and refill activity',
          ),

          const SizedBox(height: 10),

          _MetricGrid(
            items: const [
              _MetricData(
                label: 'Total Water Used',
                value: '34.6 L',
                icon: Icons.water_outlined,
                color: Color(0xFF2B8CBE),
              ),
              _MetricData(
                label: 'Average Daily Usage',
                value: '11.5 L',
                icon: Icons.calendar_today_outlined,
                color: Color(0xFF537D42),
              ),
              _MetricData(
                label: 'Refill Count',
                value: '1',
                icon: Icons.local_drink_outlined,
                color: Color(0xFFD28A32),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ------------------------------------------------------------
          // ENVIRONMENTAL TREND
          // ------------------------------------------------------------
          const _SectionTitle(
            title: 'Environmental Trend',
            subtitle: 'Sensor readings over the selected period',
          ),

          const SizedBox(height: 10),

          EnvironmentalChart(
            records: widget.sensors,
            metric: metric,
            onMetricChanged: (value) {
              setState(() {
                metric = value;
              });
            },
          ),

          const SizedBox(height: 24),

          // ------------------------------------------------------------
          // SYSTEM ACTIVITY
          // ------------------------------------------------------------
          const _SectionTitle(
            title: 'System Activity',
            subtitle: 'Number of system activations',
          ),

          const SizedBox(height: 10),

          _ChartCard(
            title: 'Daily Activity',
            subtitle: 'Humidifier and system activations',
            height: 220,
            child: BarChart(
              BarChartData(
                minY: 0,
                maxY: 20,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: const Color(0xFFE8EDE8),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 5,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        const labels = ['Jul 26', 'Jul 27', 'Jul 28'];

                        final index = value.toInt();

                        if (index < 0 || index >= labels.length) {
                          return const SizedBox();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            labels[index],
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(3, (index) {
                  const values = [9, 14, 11];

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: values[index].toDouble(),
                        width: 26,
                        borderRadius: BorderRadius.circular(6),
                        color: const Color(0xFF537D42),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ------------------------------------------------------------
          // RELIABILITY
          // ------------------------------------------------------------
          const _SectionTitle(
            title: 'System Reliability',
            subtitle: 'Communication and event outcomes',
          ),

          const SizedBox(height: 10),

          _ReliabilityCard(),

          const SizedBox(height: 24),

          // ------------------------------------------------------------
          // RELIABILITY METRICS
          // ------------------------------------------------------------
          const _SectionTitle(
            title: 'Reliability Details',
            subtitle: 'Additional system event statistics',
          ),

          const SizedBox(height: 10),

          _MetricGrid(
            items: const [
              _MetricData(
                label: 'Successful Events',
                value: '46',
                icon: Icons.check_circle_outline,
                color: Color(0xFF4E8D52),
              ),
              _MetricData(
                label: 'Communication Errors',
                value: '1',
                icon: Icons.error_outline,
                color: Color(0xFFC6534D),
              ),
              _MetricData(
                label: 'Delayed Events',
                value: '2',
                icon: Icons.schedule_outlined,
                color: Color(0xFFD28A32),
              ),
            ],
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ============================================================================
// SECTION TITLE
// ============================================================================

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF263A2A),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

// ============================================================================
// METRIC DATA
// ============================================================================

class _MetricData {
  const _MetricData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

// ============================================================================
// METRIC GRID
// ============================================================================

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.items});

  final List<_MetricData> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        int columns;

        if (width >= 900) {
          columns = 3;
        } else if (width >= 600) {
          columns = 2;
        } else {
          columns = 1;
        }

        final spacing = 10.0;
        final cardWidth = (width - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items.map((item) {
            return SizedBox(
              width: cardWidth,
              child: _MetricCard(item: item),
            );
          }).toList(),
        );
      },
    );
  }
}

// ============================================================================
// METRIC CARD
// ============================================================================

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.item});

  final _MetricData item;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 88),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E8E1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: .11),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(item.icon, size: 20, color: item.color),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF263A2A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// CHART CARD
// ============================================================================

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.height = 200,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0E8E1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF263A2A),
            ),
          ),

          const SizedBox(height: 2),

          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),

          const SizedBox(height: 16),

          SizedBox(height: height, child: child),
        ],
      ),
    );
  }
}

// ============================================================================
// RELIABILITY CARD
// ============================================================================

class _ReliabilityCard extends StatelessWidget {
  const _ReliabilityCard();

  @override
  Widget build(BuildContext context) {
    const successful = 46;
    const failed = 1;
    const delayed = 2;

    const total = successful + failed + delayed;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0E8E1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 450;

          final chart = SizedBox(
            width: compact ? 150 : 170,
            height: compact ? 150 : 170,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: compact ? 45 : 52,
                    startDegreeOffset: -90,
                    borderData: FlBorderData(show: false),
                    sections: [
                      PieChartSectionData(
                        value: successful.toDouble(),
                        color: const Color(0xFF4E8D52),
                        radius: compact ? 25 : 30,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: failed.toDouble(),
                        color: const Color(0xFFC6534D),
                        radius: compact ? 25 : 30,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: delayed.toDouble(),
                        color: const Color(0xFFD28A32),
                        radius: compact ? 25 : 30,
                        showTitle: false,
                      ),
                    ],
                  ),
                ),

                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$total',
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF263A2A),
                      ),
                    ),
                    Text(
                      'Events',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );

          final legend = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LegendItem(
                color: const Color(0xFF4E8D52),
                label: 'Successful',
                value: '$successful',
              ),
              const SizedBox(height: 12),
              _LegendItem(
                color: const Color(0xFFC6534D),
                label: 'Failed',
                value: '$failed',
              ),
              const SizedBox(height: 12),
              _LegendItem(
                color: const Color(0xFFD28A32),
                label: 'Delayed',
                value: '$delayed',
              ),
            ],
          );

          if (compact) {
            return Column(
              children: [chart, const SizedBox(height: 12), legend],
            );
          }

          return Row(
            children: [
              chart,
              const SizedBox(width: 24),
              Expanded(child: legend),
            ],
          );
        },
      ),
    );
  }
}

// ============================================================================
// LEGEND ITEM
// ============================================================================

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),

        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF263A2A),
          ),
        ),
      ],
    );
  }
}
