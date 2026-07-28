import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';
import 'package:smart_grow_code/custom_header_button.dart';
import 'package:smart_grow_code/services/esp32_service.dart';
import 'package:smart_grow_code/variables/background_template.dart';
import 'package:smart_grow_code/variables/faqs_button_sheet.dart';

class TemperatureScreen extends StatefulWidget {
  const TemperatureScreen({super.key});

  @override
  State<TemperatureScreen> createState() => _TemperatureScreenState();
}

class _TemperatureScreenState extends State<TemperatureScreen> {
  double roomTemp = 0;
  double targetTemp = 25;
  bool hasSensorReading = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _refreshData();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _refreshData());
  }

  Future<void> _refreshData() async {
    final snapshot = await Esp32Service.readSnapshot();
    if (!mounted) return;
    setState(() {
      roomTemp = snapshot.temperature ?? 0;
      hasSensorReading = snapshot.temperature != null;
    });
  }

  void _showFAQ(BuildContext context, double scale) {
    FAQBottomSheet.show(
      context,
      scale: scale,
      title: 'Temperature FAQs',
      faqs: [
        FAQItem(
          question: 'Why monitor temperature?',
          answer: 'Temperature strongly affects mushroom growth rate and contamination risk.',
        ),
        FAQItem(
          question: 'What is the target dial for?',
          answer: 'It lets you compare the live reading against the temperature you want to maintain.',
        ),
      ],
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final base = width * 0.045;
    final scale = width / 400;

    return Scaffold(
      body: Stack(
        children: [
          const BackgroundTemplate(),
          Container(color: Colors.black.withOpacity(0.35)),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 1.2 * base),
                  child: Row(
                    children: [
                      const Expanded(
                        child: CustomHeaderButton(title: 'Temperature'),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.help_outline,
                          color: Colors.white,
                          size: 22 * scale,
                        ),
                        onPressed: () => _showFAQ(context, scale),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 900),
                        child: Padding(
                          padding: EdgeInsets.all(base),
                          child: Column(
                            children: [
                              RoomTempGauge(
                                base: base,
                                temp: roomTemp,
                                hasSensorReading: hasSensorReading,
                              ),
                              SizedBox(height: base * 1.2),
                              Text(
                                hasSensorReading
                                    ? 'Live temperature from SCD40'
                                    : 'Waiting for temperature sensor data...',
                                style: TextStyle(
                                  color: hasSensorReading
                                      ? Colors.white70
                                      : Colors.orangeAccent,
                                ),
                              ),
                              SizedBox(height: base * 1.2),
                              TargetTempCard(
                                base: base,
                                targetTemp: targetTemp,
                                onChanged: (value) {
                                  setState(() => targetTemp = value);
                                },
                              ),
                              SizedBox(height: base * 1.2),
                              TempStateIndicator(
                                roomTemp: roomTemp,
                                targetTemp: targetTemp,
                                base: base,
                                hasSensorReading: hasSensorReading,
                              ),
                              SizedBox(height: base * 1.5),
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: base,
                                runSpacing: base,
                                children: [
                                  RectTempCard(
                                    base: base,
                                    label: 'Current',
                                    temp: roomTemp,
                                    icon: Icons.thermostat,
                                    color: Colors.red,
                                    hasSensorReading: hasSensorReading,
                                  ),
                                  RectTempCard(
                                    base: base,
                                    label: 'Target',
                                    temp: targetTemp,
                                    icon: Icons.track_changes,
                                    color: Colors.blue,
                                    hasSensorReading: true,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RoomTempGauge extends StatelessWidget {
  const RoomTempGauge({
    super.key,
    required this.base,
    required this.temp,
    required this.hasSensorReading,
  });

  final double base;
  final double temp;
  final bool hasSensorReading;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.shortestSide * 0.7;

    return _glassCard(
      child: Stack(
        alignment: Alignment.center,
        children: [
          SleekCircularSlider(
            min: 0,
            max: 60,
            initialValue: hasSensorReading ? temp : 0,
            appearance: CircularSliderAppearance(
              size: size,
              startAngle: 270,
              angleRange: 360,
              animationEnabled: true,
              customWidths: CustomSliderWidths(
                progressBarWidth: base * 0.7,
                trackWidth: base * 0.3,
                shadowWidth: 0,
              ),
              customColors: CustomSliderColors(
                trackColor: Colors.grey.shade400,
                progressBarColors: const [
                  Colors.blue,
                  Colors.cyan,
                  Colors.orange,
                  Colors.red,
                ],
                dotColor: Colors.transparent,
              ),
              infoProperties: InfoProperties(
                mainLabelStyle: TextStyle(
                  fontSize: base * 1.8,
                  fontWeight: FontWeight.bold,
                ),
                modifier: (value) =>
                    hasSensorReading ? '${value.toInt()} C' : '-- C',
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: Icon(Icons.wb_sunny, color: Colors.orange, size: base * 1.5),
          ),
          Positioned(
            bottom: 0,
            child: Icon(Icons.ac_unit, color: Colors.blue, size: base * 1.5),
          ),
        ],
      ),
    );
  }
}

class TargetTempCard extends StatelessWidget {
  const TargetTempCard({
    super.key,
    required this.base,
    required this.targetTemp,
    required this.onChanged,
  });

  final double base;
  final double targetTemp;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return _glassCard(
      child: Column(
        children: [
          Text(
            'TARGET TEMPERATURE',
            style: TextStyle(
              fontSize: base * 0.9,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: base * 0.4),
          Text(
            '${targetTemp.toStringAsFixed(1)} C',
            style: TextStyle(
              fontSize: base * 1.2,
              color: Colors.blueGrey.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
          Slider(
            min: 10,
            max: 35,
            value: targetTemp,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class TempStateIndicator extends StatelessWidget {
  const TempStateIndicator({
    super.key,
    required this.roomTemp,
    required this.targetTemp,
    required this.base,
    required this.hasSensorReading,
  });

  final double roomTemp;
  final double targetTemp;
  final double base;
  final bool hasSensorReading;

  @override
  Widget build(BuildContext context) {
    String label;
    IconData icon;
    Color color;

    if (!hasSensorReading) {
      label = 'No sensor data';
      icon = Icons.sensors_off;
      color = Colors.grey;
    } else if ((roomTemp - targetTemp).abs() < 0.5) {
      label = 'Stable';
      icon = Icons.check_circle;
      color = Colors.green;
    } else if (roomTemp > targetTemp) {
      label = 'Cooling';
      icon = Icons.ac_unit;
      color = Colors.blue;
    } else {
      label = 'Heating';
      icon = Icons.local_fire_department;
      color = Colors.red;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      padding: EdgeInsets.symmetric(horizontal: base, vertical: base * 0.6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: base * 1.3),
          SizedBox(width: base * 0.5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: base * 0.9,
            ),
          ),
        ],
      ),
    );
  }
}

class RectTempCard extends StatelessWidget {
  const RectTempCard({
    super.key,
    required this.base,
    required this.label,
    required this.temp,
    required this.icon,
    required this.color,
    required this.hasSensorReading,
  });

  final double base;
  final String label;
  final double temp;
  final IconData icon;
  final Color color;
  final bool hasSensorReading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.4,
      child: _glassCard(
        child: Column(
          children: [
            Icon(icon, color: color, size: base * 1.6),
            SizedBox(height: base * 0.5),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: temp, end: temp),
              duration: const Duration(milliseconds: 600),
              builder: (context, value, child) {
                return Text(
                  hasSensorReading ? '${value.toStringAsFixed(1)} C' : '-- C',
                  style: TextStyle(
                    fontSize: base * 1.4,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
            Text(
              label,
              style: TextStyle(fontSize: base * 0.8, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _glassCard({required Widget child}) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 6),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.45),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: Colors.white.withOpacity(0.7),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15),
            ],
          ),
          child: child,
        ),
      ),
    ),
  );
}
