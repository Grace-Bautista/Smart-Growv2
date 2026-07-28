import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:smart_grow_code/custom_header_button.dart';
import 'package:smart_grow_code/services/esp32_service.dart';
import 'package:smart_grow_code/variables/background_template.dart';
import 'package:smart_grow_code/variables/faqs_button_sheet.dart';

class FanScreen extends StatefulWidget {
  const FanScreen({super.key});

  @override
  State<FanScreen> createState() => _FanScreenState();
}

class _FanScreenState extends State<FanScreen> {
  String mode = 'MANUAL';
  bool powerOn = false;
  bool outputsEnabled = false;
  bool connected = false;
  int co2ppm = 0;
  double temperature = 0;
  bool hasSensorReading = false;
  double speed = 0;
  Duration remaining = Duration.zero;
  Timer? _pollTimer;
  Timer? _manualTimer;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refreshState();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _refreshState();
    });
  }

  Future<void> _refreshState() async {
    final snapshot = await Esp32Service.readSnapshot();
    if (!mounted) return;

    final nextMode = snapshot.fanMode.toUpperCase();
    final nextCo2 = snapshot.co2 ?? 0;
    final nextTemp = snapshot.temperature ?? 0;

    setState(() {
      connected = snapshot.connected;
      outputsEnabled = snapshot.powerOn;
      mode = nextMode;
      powerOn = snapshot.fanOn;
      co2ppm = nextCo2;
      temperature = nextTemp;
      hasSensorReading = snapshot.co2 != null || snapshot.temperature != null;
      speed = _deriveSpeed(
        powerOn: snapshot.fanOn,
        mode: nextMode,
        co2ppm: nextCo2,
        temperature: nextTemp,
      );
    });
  }

  double _deriveSpeed({
    required bool powerOn,
    required String mode,
    required int co2ppm,
    required double temperature,
  }) {
    if (!powerOn) return 0;
    if (mode != 'AUTO') return 0.65;

    final co2Factor = ((co2ppm - 600) / 900).clamp(0.0, 1.0);
    final tempFactor = ((temperature - 24) / 8).clamp(0.0, 1.0);
    return max(co2Factor, tempFactor).toDouble().clamp(0.25, 1.0);
  }

  Future<void> _setMode(String nextMode) async {
    if (_busy || nextMode == mode) return;
    setState(() => _busy = true);

    final ok = nextMode == 'AUTO'
        ? await Esp32Service.setFanModeAuto()
        : await Esp32Service.setFanModeManual();

    if (!mounted) return;

    if (ok && nextMode == 'AUTO') {
      _manualTimer?.cancel();
      remaining = Duration.zero;
    }

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to change fan mode. Check the ESP32 connection.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }

    await _refreshState();

    if (mounted) {
      setState(() => _busy = false);
    }
  }

  Future<void> _togglePower(bool nextValue) async {
    if (_busy || mode != 'MANUAL') return;
    if (!outputsEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enable relay outputs from the dashboard before starting the fan.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }
    setState(() => _busy = true);

    final ok = nextValue ? await Esp32Service.fanOn() : await Esp32Service.fanOff();
    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to switch the fan right now.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }

    await _refreshState();

    if (mounted) {
      setState(() => _busy = false);
    }
  }

  Future<void> _resetTimer() async {
    _manualTimer?.cancel();
    remaining = Duration.zero;

    if (mode == 'MANUAL') {
      await Esp32Service.fanOff();
      await _refreshState();
    }
  }

  Future<void> _startTimer(Duration duration) async {
    if (mode != 'MANUAL' || duration.inSeconds <= 0 || _busy) return;
    if (!outputsEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enable relay outputs from the dashboard before using the fan timer.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    _manualTimer?.cancel();
    remaining = duration;

    final turnedOn = await Esp32Service.fanOn();
    if (!turnedOn || !mounted) return;

    await _refreshState();

    _manualTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) return;

      if (remaining.inSeconds <= 1) {
        timer.cancel();
        remaining = Duration.zero;
        await Esp32Service.fanOff();
        await _refreshState();
        return;
      }

      setState(() {
        remaining -= const Duration(seconds: 1);
      });
    });
  }

  Color getCO2Color(int ppm) {
    if (ppm < 800) return Colors.green;
    if (ppm < 1000) return Colors.orange;
    return Colors.red;
  }

  void _showFAQ(BuildContext context, double scale) {
    FAQBottomSheet.show(
      context,
      scale: scale,
      title: 'Fan & CO2 FAQs',
      faqs: [
        FAQItem(
          question: 'What does auto mode do?',
          answer: 'The ESP32 automatically turns the fan on when CO2 or temperature rises too high.',
        ),
        FAQItem(
          question: 'What is a healthy CO2 range?',
          answer: 'Around 600 to 1000 ppm is a reasonable target for a ventilated grow space.',
        ),
        FAQItem(
          question: 'What does manual mode do?',
          answer: 'Manual mode lets you switch the fan yourself and use the built-in timer.',
        ),
      ],
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _manualTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final base = min(c.maxWidth, c.maxHeight);
        final gap = base * 0.05;

        return Scaffold(
          body: Stack(
            children: [
              const BackgroundTemplate(),
              Container(color: Colors.black.withOpacity(0.5)),
              SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.all(base * 0.05),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: CustomHeaderButton(title: 'Fan'),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.help_outline,
                                color: Colors.white,
                                size: base * 0.08,
                              ),
                              onPressed: () => _showFAQ(context, base * 0.05),
                            ),
                          ],
                        ),
                        SizedBox(height: gap),
                        FancyCard(
                          base: base,
                          child: FanGauge(
                            base: base,
                            powerOn: powerOn,
                            mode: mode,
                            speed: speed,
                            color: getCO2Color(co2ppm),
                            onPowerToggle: _togglePower,
                          ),
                        ),
                        SizedBox(height: gap),
                        FancyCard(
                          base: base,
                          child: CO2Section(
                            base: base,
                            ppm: co2ppm,
                            temperature: temperature,
                            color: getCO2Color(co2ppm),
                            connected: connected,
                            outputsEnabled: outputsEnabled,
                            hasSensorReading: hasSensorReading,
                            mode: mode,
                            fanOn: powerOn,
                          ),
                        ),
                        SizedBox(height: gap),
                        FancyCard(
                          base: base,
                          child: ModeSection(
                            base: base,
                            selected: mode,
                            onSelect: _setMode,
                          ),
                        ),
                        SizedBox(height: gap),
                        FancyCard(
                          base: base,
                          child: TimerSection(
                            base: base,
                            enabled: mode == 'MANUAL',
                            remaining: remaining,
                            onStart: _startTimer,
                          ),
                        ),
                        SizedBox(height: gap),
                        ElevatedButton.icon(
                          onPressed: mode == 'MANUAL'
                              ? () {
                                  _resetTimer();
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: base * 0.08,
                              vertical: base * 0.04,
                            ),
                          ),
                          icon: const Icon(Icons.restart_alt),
                          label: const Text(
                            'Reset Timer',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class FanGauge extends StatefulWidget {
  const FanGauge({
    super.key,
    required this.base,
    required this.powerOn,
    required this.mode,
    required this.speed,
    required this.color,
    required this.onPowerToggle,
  });

  final double base;
  final bool powerOn;
  final String mode;
  final double speed;
  final Color color;
  final Future<void> Function(bool) onPowerToggle;

  @override
  State<FanGauge> createState() => _FanGaugeState();
}

class _FanGaugeState extends State<FanGauge> with TickerProviderStateMixin {
  late final AnimationController controller;
  late final AnimationController inertiaController;
  double visualSpeed = 0;
  double startSpeed = 0;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    inertiaController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    visualSpeed = widget.powerOn ? widget.speed : 0;
    inertiaController.addListener(() {
      if (!mounted) return;
      setState(() {
        visualSpeed = lerpDouble(
              startSpeed,
              widget.speed,
              inertiaController.value,
            ) ??
            0;
        _updateSpeed();
      });
    });
    _updateSpeed();
  }

  @override
  void didUpdateWidget(covariant FanGauge oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.speed != widget.speed || oldWidget.powerOn != widget.powerOn) {
      startSpeed = visualSpeed;
      if (widget.powerOn && widget.speed > 0) {
        inertiaController.forward(from: 0);
      } else {
        controller.stop();
        setState(() => visualSpeed = 0);
      }
    }
  }

  void _updateSpeed() {
    if (!widget.powerOn || visualSpeed <= 0.01) {
      controller.stop();
      return;
    }

    controller.duration = Duration(
      milliseconds: (2000 - visualSpeed * 1500).toInt().clamp(300, 2000),
    );

    if (!controller.isAnimating) {
      controller.repeat();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    inertiaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.base * 0.7;
    final isManual = widget.mode == 'MANUAL';

    return Column(
      children: [
        Text(
          'FAN CONTROL',
          style: TextStyle(
            fontSize: widget.base * 0.07,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: widget.base * 0.05),
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black,
            border: Border.all(color: widget.color, width: 3),
          ),
          child: Center(
            child: RotationTransition(
              turns: controller,
              child: CustomPaint(
                size: Size(size * 0.7, size * 0.7),
                painter: FanBladePainter(
                  widget.powerOn ? widget.color : Colors.grey,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: widget.base * 0.04),
        GestureDetector(
          onTap: isManual
              ? () {
                  widget.onPowerToggle(!widget.powerOn);
                }
              : null,
          child: Container(
            width: widget.base * 0.15,
            height: widget.base * 0.15,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isManual
                  ? (widget.powerOn ? widget.color : Colors.grey)
                  : Colors.grey.shade700,
              boxShadow: [
                BoxShadow(color: widget.color.withOpacity(0.4), blurRadius: 20),
              ],
            ),
            child: const Icon(
              Icons.power_settings_new,
              color: Colors.white,
              size: 25,
            ),
          ),
        ),
      ],
    );
  }
}

class FanBladePainter extends CustomPainter {
  FanBladePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 4; i++) {
      final angle = (pi / 2) * i;
      final path = Path();
      path.moveTo(center.dx, center.dy);
      path.quadraticBezierTo(
        center.dx + radius * 0.8 * cos(angle - 0.3),
        center.dy + radius * 0.8 * sin(angle - 0.3),
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      path.quadraticBezierTo(
        center.dx + radius * 0.5 * cos(angle + 0.3),
        center.dy + radius * 0.5 * sin(angle + 0.3),
        center.dx,
        center.dy,
      );
      canvas.drawPath(path, paint);
    }

    canvas.drawCircle(center, radius * 0.12, Paint()..color = Colors.black);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class CO2Section extends StatelessWidget {
  const CO2Section({
    super.key,
    required this.base,
    required this.ppm,
    required this.temperature,
    required this.color,
    required this.connected,
    required this.outputsEnabled,
    required this.hasSensorReading,
    required this.mode,
    required this.fanOn,
  });

  final double base;
  final int ppm;
  final double temperature;
  final Color color;
  final bool connected;
  final bool outputsEnabled;
  final bool hasSensorReading;
  final String mode;
  final bool fanOn;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              Text(
                connected
                    ? hasSensorReading
                        ? 'LIVE CO2'
                        : 'WAITING FOR SENSOR'
                    : 'ESP32 OFFLINE',
                style: TextStyle(
                  color: connected ? Colors.white : Colors.orangeAccent,
                  fontSize: base * 0.05,
                ),
              ),
              SizedBox(height: base * 0.02),
              Text(
                hasSensorReading ? '$ppm ppm' : '--',
                style: TextStyle(
                  color: color,
                  fontSize: base * 0.09,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: base * 0.02),
              Text(
                outputsEnabled
                    ? (fanOn ? 'Fan running' : 'Fan standby')
                    : 'Relays disabled',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: base * 0.035,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                'TEMP',
                style: TextStyle(color: Colors.white, fontSize: base * 0.05),
              ),
              SizedBox(height: base * 0.02),
              Text(
                hasSensorReading ? '${temperature.toStringAsFixed(1)} C' : '--',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: base * 0.06,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: base * 0.02),
              Text(
                'Mode: $mode',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: base * 0.035,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ModeSection extends StatelessWidget {
  const ModeSection({
    super.key,
    required this.base,
    required this.selected,
    required this.onSelect,
  });

  final double base;
  final String selected;
  final Future<void> Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: ['AUTO', 'MANUAL'].map((m) {
        final selectedMode = selected == m;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: GestureDetector(
            onTap: () {
              onSelect(m);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
              decoration: BoxDecoration(
                color: selectedMode ? Colors.green : Colors.black,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white30),
              ),
              child: Text(
                m,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class TimerSection extends StatefulWidget {
  const TimerSection({
    super.key,
    required this.base,
    required this.enabled,
    required this.remaining,
    required this.onStart,
  });

  final double base;
  final bool enabled;
  final Duration remaining;
  final Future<void> Function(Duration) onStart;

  @override
  State<TimerSection> createState() => _TimerSectionState();
}

class _TimerSectionState extends State<TimerSection> {
  int hours = 0;
  int minutes = 30;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'TIMER',
          style: TextStyle(
            color: Colors.white,
            fontSize: widget.base * 0.06,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: widget.base * 0.02),
        Text(
          '${widget.remaining.inHours}h ${widget.remaining.inMinutes % 60}m',
          style: TextStyle(
            color: Colors.orange,
            fontSize: widget.base * 0.06,
          ),
        ),
        SizedBox(height: widget.base * 0.03),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                const Text('Hours', style: TextStyle(color: Colors.white)),
                DropdownButton<int>(
                  value: hours,
                  dropdownColor: Colors.black,
                  items: List.generate(13, (i) => i)
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(
                            '$e',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: widget.enabled
                      ? (value) => setState(() => hours = value ?? 0)
                      : null,
                ),
              ],
            ),
            const SizedBox(width: 20),
            Column(
              children: [
                const Text('Minutes', style: TextStyle(color: Colors.white)),
                DropdownButton<int>(
                  value: minutes,
                  dropdownColor: Colors.black,
                  items: [0, 5, 10, 15, 20, 30, 45, 55]
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(
                            '$e',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: widget.enabled
                      ? (value) => setState(() => minutes = value ?? 0)
                      : null,
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: widget.base * 0.03),
        ElevatedButton(
          onPressed: widget.enabled
              ? () {
                  final duration = Duration(hours: hours, minutes: minutes);
                  if (duration.inSeconds > 0) {
                    widget.onStart(duration);
                  }
                }
              : null,
          child: const Text('Start Timer'),
        ),
      ],
    );
  }
}

class FancyCard extends StatelessWidget {
  const FancyCard({super.key, required this.child, required this.base});

  final Widget child;
  final double base;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(base * 0.05),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.all(base * 0.05),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(base * 0.05),
            border: Border.all(color: Colors.white30),
          ),
          child: child,
        ),
      ),
    );
  }
}
