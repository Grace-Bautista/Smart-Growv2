import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:smart_grow_code/custom_header_button.dart';
import 'package:smart_grow_code/services/esp32_service.dart';
import 'package:smart_grow_code/variables/background_template.dart';
import 'package:smart_grow_code/variables/custom_power_button.dart';
import 'package:smart_grow_code/variables/faqs_button_sheet.dart';

class LightScreen extends StatefulWidget {
  const LightScreen({super.key});

  @override
  State<LightScreen> createState() => _LightScreenState();
}

class _LightScreenState extends State<LightScreen>
    with SingleTickerProviderStateMixin {
  static const accentUv = Color(0xFF7C4DFF);

  late final AnimationController _glowController;
  Timer? _timer;
  bool uvOn = false;
  bool connected = false;
  bool isBusy = false;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _refreshState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _refreshState());
  }

  Future<void> _refreshState() async {
    final snapshot = await Esp32Service.readSnapshot();
    if (!mounted) return;
    setState(() {
      connected = snapshot.connected;
      uvOn = snapshot.uvOn;
    });
  }

  Future<void> _toggleUv() async {
    if (isBusy) return;
    setState(() => isBusy = true);

    final ok = uvOn ? await Esp32Service.uvOff() : await Esp32Service.uvOn();

    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('UV command failed. Check the ESP32 connection.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }

    await _refreshState();

    if (mounted) {
      setState(() => isBusy = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const BackgroundTemplate(),
          Container(color: Colors.black.withOpacity(0.35)),
          LayoutBuilder(
            builder: (context, constraints) {
              final base = constraints.maxWidth * 0.05;

              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 120),
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: base),
                        child: Row(
                          children: [
                            const Expanded(
                              child: CustomHeaderButton(title: 'UV Disinfection'),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.help_outline,
                                color: Colors.white,
                              ),
                              onPressed: () => _showFAQ(context, base),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _uvStatusCard(constraints),
                    ],
                  ),
                ),
              );
            },
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).padding.bottom + 20,
            child: ButtonUtils.floatingPowerButton(
              context: context,
              title: isBusy
                  ? 'WORKING...'
                  : uvOn
                      ? 'TURN UV OFF'
                      : 'TURN UV ON',
              onTap: () {
                _toggleUv();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _uvStatusCard(BoxConstraints c) {
    return _glassCard(
      c,
      Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'UV WATER DISINFECTION',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: c.maxWidth * 0.04,
              ),
            ),
          ),
          SizedBox(height: c.maxHeight * 0.04),
          AnimatedBuilder(
            animation: _glowController,
            builder: (_, __) {
              final glow = uvOn ? 0.4 + (_glowController.value * 0.6) : 0.08;

              return Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accentUv.withOpacity(glow),
                      blurRadius: 80 * glow,
                      spreadRadius: 25 * glow,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.water_drop,
                  size: c.maxWidth * 0.22,
                  color: accentUv.withOpacity(0.9),
                ),
              );
            },
          ),
          SizedBox(height: c.maxHeight * 0.04),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: uvOn
                  ? Colors.greenAccent.withOpacity(0.6)
                  : Colors.grey.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              uvOn ? 'ACTIVE' : 'OFF',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: c.maxHeight * 0.03),
          Text(
            connected
                ? 'UV relay is connected to the ESP32 and can be switched remotely.'
                : 'ESP32 is offline. Reconnect to the device AP before sending commands.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _glassCard(BoxConstraints c, Widget child) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: c.maxWidth * 0.9,
          padding: EdgeInsets.all(c.maxWidth * 0.05),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.55),
            borderRadius: BorderRadius.circular(26),
          ),
          child: child,
        ),
      ),
    );
  }

  void _showFAQ(BuildContext context, double scale) {
    FAQBottomSheet.show(
      context,
      title: 'UV Light FAQs',
      scale: scale,
      faqs: [
        FAQItem(
          question: 'What does this feature do?',
          answer: 'It turns the UV disinfection output on or off through the ESP32.',
        ),
        FAQItem(
          question: 'Why is the icon glowing?',
          answer: 'The glow animation gives quick visual feedback that the UV relay is active.',
        ),
      ],
    );
  }
}
