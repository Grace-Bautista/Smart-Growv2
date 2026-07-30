import 'package:flutter/material.dart';
import 'package:smart_grow_code/models/sensor_data.dart';
import 'package:smart_grow_code/services/sensor_service.dart';

/// Temporary screen for confirming Realtime Database updates before the final
/// dashboard design is connected to Firebase.
class SensorTestScreen extends StatelessWidget {
  SensorTestScreen({super.key, SensorService? sensorService})
    : _sensorService = sensorService ?? SensorService();

  final SensorService _sensorService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Sensor Data Test'),
        backgroundColor: const Color(0xFFB68C63),
      ),
      body: StreamBuilder<SensorData>(
        stream: _sensorService.watchLiveData(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _MessageView(
              icon: Icons.error_outline,
              message: 'Could not read live data.\n${snapshot.error}',
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data;
          if (data == null) {
            return const _MessageView(
              icon: Icons.sensors_off_outlined,
              message: 'No data exists yet for smartGrow01.',
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Section(
                title: 'Sensors',
                children: [
                  _ValueTile(
                    'Environment temperature',
                    _number(data.environmentTemperature, 'C'),
                  ),
                  _ValueTile('Humidity', _number(data.humidity, '%')),
                  _ValueTile('CO2', _number(data.co2, 'ppm')),
                  _ValueTile('Water level', _number(data.waterLevel, '%')),
                  _ValueTile(
                    'Humidifier temperature',
                    _number(data.humidifierTemperature, 'C'),
                  ),
                ],
              ),
              _Section(
                title: 'Components',
                children: [
                  _ValueTile('Humidifier', _state(data.humidifierOn)),
                  _ValueTile('Vent fan', _state(data.ventFanOn)),
                  _ValueTile('Base fan', _state(data.baseFanOn)),
                  _ValueTile(
                    'Refill pump',
                    _refillPumpMode(data.refillPumpMode),
                  ),
                  _ValueTile('Loop pump', _state(data.loopPumpOn)),
                  _ValueTile('UV light', _state(data.uvLightOn)),
                ],
              ),
              _Section(
                title: 'Automation',
                children: [_ValueTile('Mode', data.automationMode ?? '--')],
              ),
              _Section(
                title: 'Device',
                children: [
                  _ValueTile('Online', _state(data.deviceOnline)),
                  _ValueTile('Last heartbeat', _dateTime(data.lastHeartbeat)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  static String _number(double? value, String unit) {
    if (value == null) return '--';
    return '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)} $unit';
  }

  static String _state(bool? value) {
    if (value == null) return '--';
    return value ? 'On' : 'Off';
  }

  static String _refillPumpMode(RefillPumpMode? value) {
    return switch (value) {
      RefillPumpMode.on => 'On',
      RefillPumpMode.off => 'Off',
      RefillPumpMode.auto => 'Auto',
      RefillPumpMode.unknown => 'Unknown',
      null => '--',
    };
  }

  static String _dateTime(DateTime? value) {
    if (value == null) return '--';
    final local = value.toLocal();
    return '${local.year}-${_twoDigits(local.month)}-${_twoDigits(local.day)} '
        '${_twoDigits(local.hour)}:${_twoDigits(local.minute)}:${_twoDigits(local.second)}';
  }

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ValueTile extends StatelessWidget {
  const _ValueTile(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
