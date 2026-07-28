import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:smart_grow_code/custom_header_button.dart';
import 'package:smart_grow_code/services/esp32_service.dart';
import 'package:smart_grow_code/variables/background_template.dart';
import 'package:smart_grow_code/variables/custom_power_button.dart';
import 'package:smart_grow_code/variables/faqs_button_sheet.dart';

class HumidityScreen extends StatefulWidget {
  const HumidityScreen({super.key});

  @override
  State<HumidityScreen> createState() => _HumidityScreenState();
}

class _HumidityScreenState extends State<HumidityScreen> {
  double humidity = 0;
  bool hasSensorReading = false;
  bool waterPresent = false;
  bool pumpOn = false;
  bool isBusy = false;
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
      humidity = (snapshot.humidity ?? 0).clamp(0.0, 100.0).toDouble();
      hasSensorReading = snapshot.humidity != null;
      waterPresent = snapshot.waterPresent;
      pumpOn = snapshot.pumpOn;
    });
  }

  Future<void> _togglePump() async {
    if (isBusy) return;

    setState(() => isBusy = true);

    final ok = pumpOn
        ? await Esp32Service.humidifierOff()
        : await Esp32Service.humidifierOn();

    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pump command failed. Check the ESP32 connection.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }

    await _refreshData();

    if (mounted) {
      setState(() => isBusy = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scale = (size.width / 400).clamp(0.8, 1.5);

    return Scaffold(
      body: Stack(
        children: [
          const BackgroundTemplate(),
          Container(color: Colors.black.withOpacity(0.35)),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 14 * scale),
              child: Column(
                children: [
                  SizedBox(height: 10 * scale),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8 * scale),
                    child: Row(
                      children: [
                        const Expanded(
                          child: CustomHeaderButton(title: 'Humidifier'),
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
                  SizedBox(height: 14 * scale),
                  _glassCard(
                    scale,
                    child: Column(
                      children: [
                        SizedBox(
                          height: size.width * 0.55,
                          width: size.width * 0.55,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: (humidity / 100).clamp(0.0, 1.0),
                                strokeWidth: 12 * scale,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                color: Colors.cyanAccent,
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    hasSensorReading ? '${humidity.toInt()}%' : '--%',
                                    style: TextStyle(
                                      fontSize: 36 * scale,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'Humidity',
                                    style: TextStyle(
                                      fontSize: 14 * scale,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 12 * scale),
                        Text(
                          hasSensorReading
                              ? 'Live humidity from SCD40'
                              : 'Waiting for humidity sensor data...',
                          style: TextStyle(
                            fontSize: 13 * scale,
                            color: hasSensorReading
                                ? Colors.white70
                                : Colors.orangeAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _glassCard(
                    scale,
                    child: Row(
                      children: [
                        Icon(
                          waterPresent ? Icons.check_circle : Icons.cancel,
                          size: 28 * scale,
                          color: waterPresent
                              ? Colors.greenAccent
                              : Colors.redAccent,
                        ),
                        SizedBox(width: 12 * scale),
                        Expanded(
                          child: Text(
                            waterPresent
                                ? 'Water detected in the tank.'
                                : 'Low water detected. Pump will auto-start and stay on until stopped.',
                            style: TextStyle(
                              fontSize: 16 * scale,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _glassCard(
                    scale,
                    child: Row(
                      children: [
                        Icon(
                          pumpOn ? Icons.toggle_on : Icons.toggle_off,
                          size: 36 * scale,
                          color: pumpOn
                              ? Colors.greenAccent
                              : Colors.white70,
                        ),
                        SizedBox(width: 12 * scale),
                        Expanded(
                          child: Text(
                            pumpOn
                                ? 'Refill pump is ON'
                                : 'Refill pump is OFF',
                            style: TextStyle(
                              fontSize: 16 * scale,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _glassCard(
                    scale,
                    child: Text(
                      'Water level checks are sampled every 15 minutes to avoid noisy rapid switching.',
                      style: TextStyle(
                        fontSize: 14 * scale,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 150 * scale),
                ],
              ),
            ),
          ),
          ButtonUtils.floatingPowerButton(
            context: context,
            title: isBusy
                ? 'WORKING...'
                : pumpOn
                    ? 'TURN PUMP OFF'
                    : 'TURN PUMP ON',
            onTap: () {
              _togglePump();
            },
          ),
        ],
      ),
    );
  }

  Widget _glassCard(double scale, {required Widget child}) {
    return Container(
      margin: EdgeInsets.only(bottom: 16 * scale),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20 * scale),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: EdgeInsets.all(18 * scale),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20 * scale),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  void _showFAQ(BuildContext context, double scale) {
    FAQBottomSheet.show(
      context,
      scale: scale,
      title: 'Humidifier FAQs',
      faqs: [
        FAQItem(
          question: 'What does this screen control?',
          answer: 'It monitors humidity and manages the refill pump that supplies the humidifier system.',
        ),
        FAQItem(
          question: 'Why can the pump start when water is low?',
          answer: 'When low water is detected, the system automatically starts the pump and keeps it running until you stop it.',
        ),
        FAQItem(
          question: 'Ideal humidity for mushrooms?',
          answer: 'Most fruiting stages do best around 80% to 90% humidity.',
        ),
      ],
    );
  }
}
