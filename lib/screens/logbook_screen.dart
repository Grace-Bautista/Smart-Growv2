import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:smart_grow_code/custom_header_button.dart';
import 'package:smart_grow_code/harvestlogs_screen.dart';
import 'package:smart_grow_code/logs/models/sensor_history_record.dart';
import 'package:smart_grow_code/logs/models/system_event_log.dart';
import 'package:smart_grow_code/logs/repositories/logbook_repository.dart';
import 'package:smart_grow_code/logs/repositories/firestore_logbook_repository.dart';
import 'package:smart_grow_code/logs/widgets/analytics_section.dart';
import 'package:smart_grow_code/logs/widgets/history_section.dart';
import 'package:smart_grow_code/logs/widgets/overview_section.dart';

class LogBookScreen extends StatefulWidget {
  const LogBookScreen({super.key, this.repository});

  final LogBookRepository? repository;

  @override
  State<LogBookScreen> createState() => _LogBookScreenState();
}

class _LogBookScreenState extends State<LogBookScreen> {
  static const _labels = ['Overview', 'History', 'Analytics', 'Harvest'];

  static const _icons = [
    Icons.dashboard_outlined,
    Icons.history_rounded,
    Icons.insights_outlined,
    Icons.agriculture_outlined,
  ];

  late final LogBookRepository _repository;
  late Future<_LogData> _logData;

  int _selectedSection = 0;
  String _selectedRange = '7 Days';
  DateTimeRange? _customRange;

  DateTime get _endDate {
    final now = DateTime.now();

    return DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  DateTime get _startDate {
    switch (_selectedRange) {
      case 'Today':
        final end = _endDate;
        return DateTime(end.year, end.month, end.day);

      case '7 Days':
        return _endDate.subtract(const Duration(days: 6));

      case '30 Days':
        return _endDate.subtract(const Duration(days: 29));

      case 'Custom':
        return _customRange?.start ?? _endDate;

      default:
        return _endDate;
    }
  }

  Future<void> _pickCustomRange() async {
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customRange,
    );

    if (result == null) return;

    setState(() {
      _customRange = result;
      _selectedRange = 'Custom';
      _logData = _loadLogData();
    });
  }

  @override
  void initState() {
    super.initState();

    _repository = widget.repository ?? FirestoreLogBookRepository();
    _logData = _loadLogData();
  }

  Future<_LogData> _loadLogData() async {
    try {
      final sensors = await _repository.getSensorHistory(
        deviceId: 'smartGrow01',
        start: _startDate,
        end: _endDate,
      );

      final events = await _repository.getSystemEvents(
        deviceId: 'smartGrow01',
        start: _startDate,
        end: _endDate,
      );

      return _LogData(sensors: sensors, events: events);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Logbook load failed: $error');
        debugPrintStack(label: 'Logbook stack trace', stackTrace: stackTrace);
      }

      return _LogData(sensors: const [], events: const [], error: error);
    }
  }

  String _safeErrorDetail(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('permission')) return 'Permission denied.';
    if (message.contains('failed-precondition') || message.contains('index')) {
      return 'Required Firestore index missing.';
    }
    if (message.contains('sensorhistory')) {
      return 'Malformed sensorHistory records.';
    }
    if (message.contains('systemevents')) {
      return 'Malformed systemEvents records.';
    }
    return 'Unable to read history records.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F5F3),
      body: SafeArea(
        child: Column(
          children: [
            const CustomHeaderButton(title: 'Log Book'),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  children: [
                    _buildNavigation(),

                    const SizedBox(height: 12),
                    if (_selectedSection != 3) ...[
                      _DateRangeSelector(
                        selectedRange: _selectedRange,
                        onChanged: (value) {
                          if (value == 'Custom') {
                            _pickCustomRange();
                            return;
                          }

                          setState(() {
                            _selectedRange = value;
                            _logData = _loadLogData();
                          });
                        },
                      ),

                      const SizedBox(height: 18),
                    ],

                    Expanded(
                      child: FutureBuilder<_LogData>(
                        future: _logData,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return _buildLoadingState();
                          }

                          final data = snapshot.data!;

                          if (data.error != null) {
                            return _buildErrorState(data.error!);
                          }

                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            child: KeyedSubtree(
                              key: ValueKey(_selectedSection),
                              child: _buildSelectedSection(data),
                            ),
                          );
                        },
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

  // ------------------------------------------------------------
  // NAVIGATION
  // ------------------------------------------------------------

  Widget _buildNavigation() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final navigation = Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E1DC)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              _labels.length,
              (index) => _buildNavigationItem(
                index: index,
                label: _labels[index],
                icon: _icons[index],
              ),
            ),
          ),
        );

        if (constraints.maxWidth < 620) {
          return Align(
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: navigation,
            ),
          );
        }

        return Center(child: navigation);
      },
    );
  }

  Widget _buildNavigationItem({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final bool isSelected = _selectedSection == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (_selectedSection == index) return;

            setState(() {
              _selectedSection = index;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            constraints: const BoxConstraints(minWidth: 125),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFE9F0E9) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: const Color(0xFFD3DFD3))
                  : Border.all(color: Colors.transparent),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  scale: isSelected ? 1.0 : 0.95,
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    icon,
                    size: 19,
                    color: isSelected
                        ? const Color.fromARGB(255, 189, 116, 69)
                        : const Color.fromARGB(255, 127, 71, 34),
                  ),
                ),

                const SizedBox(width: 8),

                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? const Color.fromARGB(255, 82, 88, 84)
                        : const Color(0xFF68645F),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // CONTENT
  // ------------------------------------------------------------

  Widget _buildSelectedSection(_LogData data) {
    switch (_selectedSection) {
      case 0:
        return OverviewSection(
          repository: _repository,
          startDate: _startDate,
          endDate: _endDate,
        );

      case 1:
        return HistorySection(
          sensors: data.sensors,
          events: data.events,
          startDate: _startDate,
          endDate: _endDate,
        );

      case 2:
        return AnalyticsSection(
          sensors: data.sensors,
          events: data.events,
          startDate: _startDate,
          endDate: _endDate,
        );

      case 3:
        return const HarvestLogWidget();

      default:
        return OverviewSection(
          repository: _repository,
          startDate: _startDate,
          endDate: _endDate,
        );
    }
  }

  // ------------------------------------------------------------
  // STATES
  // ------------------------------------------------------------

  Widget _buildLoadingState() {
    return const Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    final debugDetail = _safeErrorDetail(error);
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E1DC)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7ECE8),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 28,
                color: Color(0xFF9A5C4C),
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'Unable to load log data',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF373431),
              ),
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 8),
              Text(
                debugDetail,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Color(0xFF9A5C4C)),
              ),
            ],
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => setState(() => _logData = _loadLogData()),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),

            const SizedBox(height: 8),

            const Text(
              'There was a problem loading the records. '
              'Please try again later.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF77736D),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogData {
  const _LogData({
    required this.sensors,
    required this.events,
    this.error,
  });

  final List<SensorHistoryRecord> sensors;
  final List<SystemEventLog> events;
  final Object? error;
}

class _DateRangeSelector extends StatelessWidget {
  const _DateRangeSelector({
    required this.selectedRange,
    required this.onChanged,
  });

  final String selectedRange;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<String>(
        showSelectedIcon: false,
        style: ButtonStyle(
          visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          ),
          textStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        segments: const [
          ButtonSegment(
            value: 'Today',
            label: SizedBox(
              width: double.infinity,
              child: Center(child: Text('Today')),
            ),
          ),
          ButtonSegment(
            value: '7 Days',
            label: SizedBox(
              width: double.infinity,
              child: Center(child: Text('7 Days')),
            ),
          ),
          ButtonSegment(
            value: '30 Days',
            label: SizedBox(
              width: double.infinity,
              child: Center(child: Text('30 Days')),
            ),
          ),
          ButtonSegment(
            value: 'Custom',
            label: SizedBox(
              width: double.infinity,
              child: Center(child: Text('Custom')),
            ),
          ),
        ],
        selected: {selectedRange},
        onSelectionChanged: (value) {
          if (value.isNotEmpty) {
            onChanged(value.first);
          }
        },
      ),
    );
  }
}
