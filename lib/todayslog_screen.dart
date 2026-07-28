import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TodaysLogWidget extends StatefulWidget {
  const TodaysLogWidget({super.key});

  @override
  State<TodaysLogWidget> createState() => _TodaysLogWidgetState();
}

class _TodaysLogWidgetState extends State<TodaysLogWidget> {
  DateTime selectedDate = DateTime.now();

  ///  SAMPLE DATA (replace later with real database)
  List<Map<String, dynamic>> logs = [
    {
      "time": "10:50 AM",
      "temp": 28,
      "humidity": 65,
      "co2": 420,
      "date": "2026-04-24",
    },
    {
      "time": "09:30 AM",
      "temp": 27,
      "humidity": 63,
      "co2": 410,
      "date": "2026-04-24",
    },
  ];

  ///  FILTER LOGS BY DATE
  List<Map<String, dynamic>> get filteredLogs {
    String selected = DateFormat('yyyy-MM-dd').format(selectedDate);
    return logs.where((log) => log["date"] == selected).toList();
  }

  /// OPEN CALENDAR
  void pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey("today"),
      children: [
        /// DATE SELECTOR BUTTON
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: pickDate,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(14),
              backgroundColor: const Color(0xFFB68C63),
            ),
            child: Text(
              "View Logs: ${DateFormat('MMM dd, yyyy').format(selectedDate)}",
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),

        const SizedBox(height: 15),

        ///  SYSTEM SUMMARY
        buildSummaryCard(),

        const SizedBox(height: 15),

        ///  LOG LIST
        Expanded(
          child: filteredLogs.isEmpty
              ? const Center(
                  child: Text(
                    "No logs for this day",
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : ListView.builder(
                  itemCount: filteredLogs.length,
                  itemBuilder: (context, index) {
                    final log = filteredLogs[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text(
                          log["time"],
                          style: const TextStyle(fontSize: 18),
                        ),
                        subtitle: Text(
                          "Temp: ${log["temp"]}°C | "
                          "Humidity: ${log["humidity"]}% | "
                          "CO₂: ${log["co2"]} ppm",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  /// 📊 SYSTEM SUMMARY CARD
  Widget buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.brown.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "System Summary",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          SizedBox(height: 10),

          Text("Humidifier ON Time: 2 hrs", style: TextStyle(fontSize: 16)),
          Text("Fan Working Time: 5 hrs", style: TextStyle(fontSize: 16)),
          Text("Total Sensor Readings: 120", style: TextStyle(fontSize: 16)),
          Text("Avg Latency: 200 ms", style: TextStyle(fontSize: 16)),
          Text("Avg Recovery Time: 3 sec", style: TextStyle(fontSize: 16)),
          Text("Total System Events: 15", style: TextStyle(fontSize: 16)),
          Text("Errors/Delays: 2", style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
