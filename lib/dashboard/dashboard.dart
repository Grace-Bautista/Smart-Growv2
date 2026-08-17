import 'package:flutter/material.dart';

import '../models/iot_command.dart';
import '../models/sensor.dart';
import '../models/sensor_data.dart';
import '../services/alert_store.dart';
import '../services/iot_command_service.dart';
import '../services/sensor_service.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/control_panel.dart';
import '../widgets/device_card.dart';
import '../widgets/environmental_status.dart';
import 'notification/notification_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final SensorService _liveData = SensorService.instance;
  final IotCommandService _commands = IotCommandService.instance;

  int _navIndex = 0;

  @override
  void initState() {
    super.initState();

    _commands.addListener(_rebuild);
    _commands.start();
  }

  @override
  void dispose() {
    _commands.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) {
      setState(() {});
    }
  }

  List<Sensor> _sensorsFrom(SensorData data) {
    String reading(double? value, SensorReadingStatus status, int decimals) {
      final isAvailable = status.isFresh(DateTime.now()) && value != null;

      return isAvailable ? value.toStringAsFixed(decimals) : '--';
    }

    return [
      Sensor(
        label: 'Humidity',
        value: reading(data.humidity, data.humidityStatus, 0),
        unit: '%',
        icon: Icons.water_drop_outlined,
        hasInfo: true,
      ),
      Sensor(
        label: 'Temp',
        value: reading(
          data.environmentTemperature,
          data.environmentTempStatus,
          1,
        ),
        unit: '°C',
        icon: Icons.thermostat_outlined,
        hasInfo: true,
      ),
      Sensor(
        label: 'CO₂',
        value: reading(data.co2, data.co2Status, 0),
        unit: 'ppm',
        icon: Icons.cloud_outlined,
        hasInfo: true,
      ),
    ];
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _send(IotCommandTarget target, Object value) async {
    try {
      await _commands.submit(target, value);
    } catch (error) {
      if (mounted) {
        _showSnack('Command unavailable: $error');
      }
    }
  }

  bool _pending(IotCommandTarget target) {
    return _commands.isPending(target);
  }

  String? _error(IotCommandTarget target) {
    return _commands.errorFor(target);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SensorData>(
      stream: _liveData.watchLiveData(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? const SensorData();
        final available = data.isDeviceAvailable(DateTime.now());

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              _header(context),
              SliverToBoxAdapter(
                child: _body(context, data, available, snapshot.hasError),
              ),
            ],
          ),
          bottomNavigationBar: SmartGrowBottomNav(
            selectedIndex: _navIndex,
            onTap: (index) {
              setState(() {
                _navIndex = index;
              });
            },
            onPowerTap: () {
              _showSnack(
                available
                    ? 'Receiving live RTDB data'
                    : 'ESP32 heartbeat is stale',
              );
            },
          ),
        );
      },
    );
  }

  Widget _header(BuildContext context) => SliverAppBar(
    pinned: true,
    floating: true,
    backgroundColor: AppTheme.primary,
    title: const Text('SmartGrow'),
    actions: [
      Padding(
        padding: const EdgeInsets.only(right: AppTheme.space4),
        child: ValueListenableBuilder<int>(
          valueListenable: AlertStore.unreadCount,
          builder: (context, unread, _) => InkResponse(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationScreen()),
            ),
            child: Badge(
              isLabelVisible: unread > 0,
              label: Text(unread > 9 ? '9+' : '$unread'),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    ],
  );

  Widget _body(
    BuildContext context,
    SensorData data,
    bool available,
    bool hasError,
  ) {
    final manual = data.automationMode == AutomationMode.manual;
    final controlsEnabled = available && manual;
    final water = data.waterLevelStatus.isFresh(DateTime.now())
        ? data.waterLevel
        : null;
    final humidifierTemp = data.humidifierTempStatus.isFresh(DateTime.now())
        ? data.humidifierTemperature
        : null;
    return Padding(
      padding: const EdgeInsets.all(AppTheme.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EnvironmentStatus(
            isOnline: available,
            sensors: _sensorsFrom(data),
            onToggleOnline: () => _showSnack(
              hasError
                  ? 'RTDB connection error'
                  : available
                  ? 'Live data is current'
                  : 'ESP32 unavailable',
            ),
            onSensorTap: (sensor) =>
                _showSnack('${sensor.label}: ${sensor.value}${sensor.unit}'),
          ),
          const SizedBox(height: AppTheme.space5),
          Row(
            children: [
              Expanded(child: Divider(color: AppTheme.divider)),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space3,
                ),
                child: Text(
                  'Control Panel',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              Expanded(child: Divider(color: AppTheme.divider)),
            ],
          ),
          const SizedBox(height: AppTheme.space5),
          ControlPanel(
            temp: humidifierTemp ?? 0,
            waterLevel: water ?? 0,
            pumpActive: data.loopPumpOn ?? false,
            fanActive: data.baseFanOn ?? false,
            refillMode: _refillMode(data),
            isActivated: data.humidifierOn ?? false,
            controlsEnabled: controlsEnabled,
            pumpPending: _pending(IotCommandTarget.loopPump),
            fanPending: _pending(IotCommandTarget.baseFan),
            refillPending: _pending(IotCommandTarget.refillPumpMode),
            humidifierPending: _pending(IotCommandTarget.humidifier),
            onTempChanged: null,
            onWaterLevelChanged: null,
            onTogglePump: () =>
                _send(IotCommandTarget.loopPump, !(data.loopPumpOn ?? false)),
            onToggleFan: () =>
                _send(IotCommandTarget.baseFan, !(data.baseFanOn ?? false)),
            onRefillModeChanged: (mode) => _setRefillPumpMode(mode),
            onActivate: () => _send(
              IotCommandTarget.humidifier,
              !(data.humidifierOn ?? false),
            ),
          ),
          if (!manual)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Switch to Manual mode before controlling outputs.'),
            ),
          if (!manual && available)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _pending(IotCommandTarget.automationMode)
                    ? null
                    : () => _send(IotCommandTarget.automationMode, 'manual'),
                child: Text(
                  _pending(IotCommandTarget.automationMode)
                      ? 'Switching to Manual…'
                      : 'Switch to Manual mode',
                ),
              ),
            ),
          if (!available)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('ESP32 is offline or heartbeat is stale.'),
            ),
          const SizedBox(height: AppTheme.space5),
          _deviceRow(data, controlsEnabled),
          if (_error(IotCommandTarget.uvLight) != null)
            Text('UV command: ${_error(IotCommandTarget.uvLight)}'),
        ],
      ),
    );
  }

  RefillMode _refillMode(SensorData data) {
    if (data.refillPumpMode == AutomationMode.automatic) {
      return RefillMode.auto;
    }
    return (data.refillPumpOn ?? false) ? RefillMode.on : RefillMode.off;
  }

  Future<void> _setRefillPumpMode(RefillMode mode) {
    final desiredMode = switch (mode) {
      RefillMode.auto => 'auto',
      RefillMode.on => 'on',
      RefillMode.off => 'off',
    };

    return _send(IotCommandTarget.refillPump, desiredMode);
  }

  Widget _deviceRow(SensorData data, bool controlsEnabled) {
    return Row(
      children: [
        Expanded(
          child: DeviceSwitchCard(
            title: 'UV Light',
            description: 'ESP32-reported controller output.',
            icon: Icons.wb_sunny_outlined,
            value: data.uvLightOn ?? false,
            enabled: controlsEnabled && !_pending(IotCommandTarget.uvLight),
            onChanged: (value) {
              _send(IotCommandTarget.uvLight, value);
            },
          ),
        ),
        const SizedBox(width: AppTheme.space3),
        Expanded(
          child: DeviceSwitchCard(
            title: 'Ventilation',
            description: 'ESP32-reported ventilation fan output.',
            icon: Icons.air_rounded,
            value: data.ventFanOn ?? false,
            enabled: controlsEnabled && !_pending(IotCommandTarget.ventFan),
            onChanged: (value) {
              _send(IotCommandTarget.ventFan, value);
            },
          ),
        ),
      ],
    );
  }
}
