import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class SummaryWidget extends StatelessWidget {
  const SummaryWidget({super.key});

  /// Generate last 7 days
  List<DateTime> getLast7Days() {
    final now = DateTime.now();
    return List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          /// Latest Reading
          buildCard(
            title: "Latest Reading",
            content:
                "Time: 10:50 AM\nTemp: 50°C\nHumidity: 65%\nCO₂: 420 ppm\n",
          ),

          /// AVERAGE CARD
          buildAverageCard(),

          /// Temperature Graph
          buildGraphCard(
            title: "Temperature (7 Days)",
            spots: const [
              FlSpot(1, 27),
              FlSpot(2, 28),
              FlSpot(3, 26),
              FlSpot(4, 27),
              FlSpot(5, 29),
              FlSpot(6, 30),
              FlSpot(7, 25),
            ],
            minY: 25,
            maxY: 30,
          ),

          /// Humidity Graph
          buildGraphCard(
            title: "Humidity (7 Days)",
            spots: const [
              FlSpot(1, 60),
              FlSpot(2, 65),
              FlSpot(3, 62),
              FlSpot(4, 64),
              FlSpot(5, 66),
              FlSpot(6, 63),
              FlSpot(7, 65),
            ],
            minY: 60,
            maxY: 100,
          ),

          /// CO2 Graph
          buildGraphCard(
            title: "CO₂ (7 Days)",
            spots: const [
              FlSpot(1, 400),
              FlSpot(2, 420),
              FlSpot(3, 410),
              FlSpot(4, 415),
              FlSpot(5, 430),
              FlSpot(6, 425),
              FlSpot(7, 418),
            ],
            minY: 0,
            maxY: 2000,
          ),
        ],
      ),
    );
  }

  ///  GRAPH CARD
  Widget buildGraphCard({
    required String title,
    required List<FlSpot> spots,
    required double minY,
    required double maxY,
  }) {
    final days = getLast7Days();

    return Container(
      height: 260,
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.brown.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.brown,
            ),
          ),
          const SizedBox(height: 10),

          Expanded(
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(show: true),

                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value % 1 != 0) return const SizedBox();

                        final index = value.toInt();
                        if (index < 1 || index > 7) {
                          return const SizedBox();
                        }

                        final date = days[index - 1];

                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            DateFormat('MMM d').format(date),
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),

                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                  ),

                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),

                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),

                borderData: FlBorderData(show: true),

                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  ///  AVERAGE CARD
  Widget buildAverageCard() {
    final days = getLast7Days();

    final temp = [27, 28, 26, 27, 29, 30, 28];
    final humidity = [60, 65, 62, 64, 66, 63, 65];
    final co2 = [400, 420, 410, 415, 430, 425, 418];

    double avg(List<int> list) => list.reduce((a, b) => a + b) / list.length;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.brown.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Average (7 Days)",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.brown,
            ),
          ),

          const SizedBox(height: 10),

          /// TABLE
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text("Day")),
                DataColumn(label: Text("Temp")),
                DataColumn(label: Text("Humidity")),
                DataColumn(label: Text("CO₂")),
              ],
              rows: List.generate(7, (i) {
                return DataRow(
                  cells: [
                    DataCell(Text(DateFormat('MMM d').format(days[i]))),
                    DataCell(Text("${temp[i]}°C")),
                    DataCell(Text("${humidity[i]}%")),
                    DataCell(Text("${co2[i]} ppm")),
                  ],
                );
              }),
            ),
          ),

          const SizedBox(height: 12),

          /// WEEKLY AVERAGE
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.brown.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "Weekly Average\n"
              "Temp: ${avg(temp).toStringAsFixed(1)}°C   |   "
              "Humidity: ${avg(humidity).toStringAsFixed(1)}%   |   "
              "CO₂: ${avg(co2).toStringAsFixed(0)} ppm",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  /// TEXT CARD
  Widget buildCard({required String title, required String content}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.brown.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.brown,
            ),
          ),
          const SizedBox(height: 10),
          Text(content, style: const TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}
