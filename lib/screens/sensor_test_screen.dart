import 'package:flutter/material.dart';
import 'package:smart_grow_code/models/iot_command.dart';
import 'package:smart_grow_code/models/sensor_data.dart';
import 'package:smart_grow_code/services/iot_command_service.dart';
import 'package:smart_grow_code/services/sensor_service.dart';

class SensorTestScreen extends StatelessWidget {
  SensorTestScreen({super.key, SensorService? sensorService})
    : _sensorService = sensorService ?? SensorService.instance;
  final SensorService _sensorService;
  final IotCommandService _commands = IotCommandService.instance;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Live RTDB Data Test'),
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
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;
        final now = DateTime.now();
        return AnimatedBuilder(
          animation: _commands,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Section('Sensors', [
                _tile(
                  'Environment temperature',
                  _reading(
                    data.environmentTemperature,
                    'C',
                    data.environmentTempStatus,
                    now,
                  ),
                ),
                _tile(
                  'Humidity',
                  _reading(data.humidity, '%', data.humidityStatus, now),
                ),
                _tile('CO2', _reading(data.co2, 'ppm', data.co2Status, now)),
                _tile(
                  'Water level',
                  _reading(data.waterLevel, '%', data.waterLevelStatus, now),
                ),
                _tile(
                  'Humidifier temperature',
                  _reading(
                    data.environmentTemperature,
                    'C',
                    data.environmentTempStatus,
                    now,
                  ),
                ),
              ]),
              _Section('Components', [
                _tile('Humidifier', _state(data.humidifierOn)),
                _tile('Vent fan', _state(data.ventFanOn)),
                _tile('Base fan', _state(data.baseFanOn)),
                _tile('Refill pump', _state(data.refillPumpOn)),
                _tile('Loop pump', _state(data.loopPumpOn)),
                _tile('UV light', _state(data.uvLightOn)),
              ]),
              _Section('Refill', [
                _tile('Mode', data.refillPumpMode),
                _tile('Running', _state(data.refillPumpOn)),
              ]),
              _Section('Device', [
                _tile('Online hint', _state(data.deviceOnline)),
                _tile(
                  'Available from heartbeat',
                  data.isDeviceAvailable(now) ? 'Yes' : 'No',
                ),
                _tile('Last heartbeat', _dateTime(data.lastHeartbeat)),
                _tile('Boot ID', data.bootId ?? '--'),
              ]),
              _Section('Command slots', [
                for (final target in IotCommandTarget.values)
                  _tile(target.path, _command(_commands.stateFor(target))),
              ]),
            ],
          ),
        );
      },
    ),
  );
  static Widget _tile(String title, String value) => ListTile(
    title: Text(title),
    trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
  );
  static String _reading(
    double? value,
    String unit,
    SensorReadingStatus status,
    DateTime now,
  ) {
    if (value == null) {
      return '--';
    }

    if (!status.isFresh(now)) {
      return status.valid == false ? 'Unavailable' : 'Stale';
    }

    return '${value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1)} $unit';
  }

  static String _state(bool? value) => value == null
      ? '--'
      : value
      ? 'On'
      : 'Off';
  static String _dateTime(DateTime? value) =>
      value?.toLocal().toString() ?? '--';
  static String _command(IotCommandState state) => state.isFailure
      ? '${state.status.name} (${state.lastError ?? 'unknown'})'
      : state.status.name;
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.children);
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Card(
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

class _MessageView extends StatelessWidget {
  const _MessageView({required this.icon, required this.message});
  final IconData icon;
  final String message;
  @override
  Widget build(BuildContext context) => Center(
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
