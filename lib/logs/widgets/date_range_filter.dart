import 'package:flutter/material.dart';

enum LogDateRange { today, sevenDays, thirtyDays, custom }

class DateRangeFilter extends StatelessWidget {
  const DateRangeFilter({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.onCustomRange,
  });

  final LogDateRange selected;
  final ValueChanged<LogDateRange> onChanged;
  final VoidCallback onCustomRange;

  @override
  Widget build(BuildContext context) {
    const labels = {
      LogDateRange.today: 'Today',
      LogDateRange.sevenDays: '7 Days',
      LogDateRange.thirtyDays: '30 Days',
      LogDateRange.custom: 'Custom',
    };
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: LogDateRange.values.map((range) {
        return ChoiceChip(
          label: Text(labels[range]!),
          selected: selected == range,
          selectedColor: const Color(0xFFDCEBD7),
          onSelected: (_) {
            if (range == LogDateRange.custom) {
              onCustomRange();
            } else {
              onChanged(range);
            }
          },
        );
      }).toList(),
    );
  }
}

DateTimeRange logRangeFor(LogDateRange range, {DateTimeRange? customRange}) {
  if (range == LogDateRange.custom && customRange != null) return customRange;
  final now = DateTime.now();
  final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
  final days = switch (range) {
    LogDateRange.today => 0,
    LogDateRange.sevenDays => 6,
    LogDateRange.thirtyDays => 29,
    LogDateRange.custom => 0,
  };
  return DateTimeRange(
    start: DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: days)),
    end: end,
  );
}
