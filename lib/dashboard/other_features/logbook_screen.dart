import 'package:flutter/material.dart';
import 'package:smart_grow_code/harvestlogs_screen.dart';
import 'package:smart_grow_code/summarylogs_screen.dart';
import 'package:smart_grow_code/todayslog_screen.dart';
import 'package:smart_grow_code/custom_header_button.dart';

class LogBookScreen extends StatefulWidget {
  const LogBookScreen({super.key});

  @override
  State<LogBookScreen> createState() => _LogBookScreenState();
}

class _LogBookScreenState extends State<LogBookScreen> {
  String selectedOption = "Summary";

  final List<String> options = [
    "Summary",
    "Today's Log",
    "Harvest Log",
  ];

 @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFFF1F5F2),
    body: SafeArea(
      child: Column(
        children: [

          /// ✅ YOUR CUSTOM HEADER HERE
          const CustomHeaderButton(
            title: "Log Book",
          ),

          /// 🔽 CONTENT
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [

                  /// DROPDOWN
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFB68C63),
                        width: 1.5,
                      ),
                    ),
                    child: DropdownButton<String>(
                      value: selectedOption,
                      isExpanded: true,
                      underline: const SizedBox(),
                      style: const TextStyle(
                          fontSize: 18, color: Colors.black),
                      items: options.map((String value) {
                        return DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedOption = value!;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 25),

                  /// DYNAMIC CONTENT
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: getContentWidget(selectedOption),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  /// SWITCH CONTENT
  Widget getContentWidget(String option) {
    switch (option) {
      case "Today's Log":
        return const TodaysLogWidget();

      case "Harvest Log":
        return const HarvestLogWidget();

      default:
        return const SummaryWidget();
    }
  }
}

