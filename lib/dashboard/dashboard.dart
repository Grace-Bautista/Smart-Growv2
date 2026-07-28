import 'dart:async';

import 'package:flutter/material.dart';
import 'package:smart_grow_code/dashboard/notification/notification_screen.dart';
import 'package:smart_grow_code/dashboard/sg_custom_scaffold.dart';
import 'package:smart_grow_code/iot_screens/fan_screen.dart';
import 'package:smart_grow_code/iot_screens/humidifier_screen.dart';
import 'package:smart_grow_code/iot_screens/light_screen.dart';
import 'package:smart_grow_code/iot_screens/temperature_screen.dart';
import 'package:smart_grow_code/services/esp32_service.dart';

class SmartGrowDashboard extends StatefulWidget {
  const SmartGrowDashboard({super.key});

  @override
  State<SmartGrowDashboard> createState() => _SmartGrowDashboardState();
}

class _SmartGrowDashboardState extends State<SmartGrowDashboard> {
  Esp32Snapshot _snapshot = Esp32Snapshot.offline();
  Timer? _pollTimer;
  bool _powerBusy = false;

  @override
  void initState() {
    super.initState();
    _refreshSnapshot();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _refreshSnapshot(),
    );
  }

  Future<void> _refreshSnapshot() async {
    final snapshot = await Esp32Service.readSnapshot();
    if (!mounted) return;
    setState(() => _snapshot = snapshot);
  }

  Future<void> _toggleSystemPower() async {
    if (_powerBusy) return;

    if (_snapshot.powerOn) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Disable relay outputs?'),
          content: const Text(
            'This will turn off only the fan and pump relays. The ESP32, OLED, and sensors will stay powered.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Turn off'),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    setState(() => _powerBusy = true);

    final ok = _snapshot.powerOn
        ? await Esp32Service.powerRailOff()
        : await Esp32Service.powerRailOn();

    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to reach the ESP32 right now.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }

    await _refreshSnapshot();

    if (mounted) {
      setState(() => _powerBusy = false);
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(child: AppDrawer(onClose: () => Navigator.pop(context))),
      appBar: AppBar(
        title: const Text(
          'Smart Grow',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFB68C63),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationScreen()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background-image.jpg',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final crossAxisCount = width < 600 ? 2 : 4;
                final padding = (width * 0.04).clamp(12.0, 24.0);
                final spacing = (width * 0.03).clamp(10.0, 20.0);

                return SingleChildScrollView(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    children: [
                      WeatherCard(snapshot: _snapshot),
                      SizedBox(height: spacing),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: spacing,
                        mainAxisSpacing: spacing,
                        childAspectRatio: width < 420 ? 0.95 : 1.0,
                        children: [
                          FeatureCard(
                            title: 'Humidifier',
                            icon: Icons.water_drop,
                            color: Colors.blue,
                            isActive: _snapshot.pumpOn,
                            description:
                                'Monitors humidity and controls the refill pump for the humidifier tank.',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const HumidityScreen(),
                              ),
                            ),
                          ),
                          FeatureCard(
                            title: 'Temperature',
                            icon: Icons.thermostat,
                            color: Colors.red,
                            isActive: _snapshot.temperature != null,
                            description:
                                'Shows the live SCD40 temperature reading and its control state.',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TemperatureScreen(),
                              ),
                            ),
                          ),
                          FeatureCard(
                            title: 'UV Light',
                            icon: Icons.lightbulb,
                            color: Colors.orange,
                            isActive: _snapshot.uvOn,
                            description:
                                'Controls the UV disinfection lamp connected to the ESP32.',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LightScreen(),
                              ),
                            ),
                          ),
                          FeatureCard(
                            title: 'Fan / CO2',
                            icon: Icons.air,
                            color: Colors.green,
                            isActive: _snapshot.fanOn,
                            description:
                                'Controls airflow manually or automatically based on CO2 and temperature.',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const FanScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: spacing),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _powerBusy
                              ? null
                              : () {
                                  _toggleSystemPower();
                                },
                          icon: Icon(
                            _snapshot.powerOn
                                ? Icons.power_settings_new
                                : Icons.power_off,
                            color: Colors.white,
                          ),
                          label: Text(
                            _snapshot.powerOn
                                ? 'RELAY OUTPUTS ENABLED'
                                : 'RELAY OUTPUTS DISABLED',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _snapshot.powerOn
                                ? Colors.green
                                : Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class WeatherCard extends StatelessWidget {
  const WeatherCard({super.key, required this.snapshot});

  final Esp32Snapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: width * 0.06,
        horizontal: width * 0.05,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: Colors.white.withOpacity(0.95),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.cloud, size: 40, color: Colors.black87),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'ENVIRONMENT STATUS',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              _EspStatusChip(connected: snapshot.connected),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _MetricChip(
                label: 'Temp',
                value: snapshot.temperature == null
                    ? '--'
                    : '${snapshot.temperature!.toStringAsFixed(1)} C',
              ),
              _MetricChip(
                label: 'Humidity',
                value: snapshot.humidity == null
                    ? '--'
                    : '${snapshot.humidity!.toStringAsFixed(0)}%',
              ),
              _MetricChip(
                label: 'CO2',
                value: snapshot.co2 == null ? '--' : '${snapshot.co2} ppm',
              ),
              _MetricChip(
                label: 'Water',
                value: snapshot.waterPresent ? 'Detected' : 'Empty',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5EFE6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _EspStatusChip extends StatelessWidget {
  const _EspStatusChip({required this.connected});

  final bool connected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: connected ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        connected ? 'ESP32 ONLINE' : 'ESP32 OFFLINE',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class FeatureCard extends StatelessWidget {
  const FeatureCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.isActive,
    required this.description,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final bool isActive;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final iconSize = (width * 0.08).clamp(28.0, 46.0);
    final textSize = (width * 0.035).clamp(12.0, 18.0);

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: Colors.white.withOpacity(0.95),
          border: Border.all(
            color: isActive ? color : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.help_outline, size: 18),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text(title),
                      content: Text(description),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: iconSize, color: color),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: textSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isActive ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  isActive ? 'ACTIVE' : 'INACTIVE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
