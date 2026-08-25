import 'dart:async';

import 'package:flutter/material.dart';

import '../models/iot_command.dart';
import '../models/sensor.dart';
import '../models/sensor_data.dart';
import '../services/alert_store.dart';
import '../services/esp32_service.dart';
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

  late final Stream<SensorData> _liveDataStream;

  int _navIndex = 0;

  // Rebuilds periodically so heartbeat freshness can be re-evaluated
  // even when no new RTDB event arrives.
  Timer? _heartbeatTimer;

  @override
  void initState() {
    super.initState();

    _liveDataStream = _liveData.watchLiveData();
    _commands.addListener(_rebuild);
    _commands.start();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _rebuild(),
    );
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _commands.removeListener(_rebuild);

    super.dispose();
  }

  void _rebuild() {
    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // SENSOR CARDS
  // ============================================================

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

  // ============================================================
  // SNACKBAR
  // ============================================================

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

  // ============================================================
  // COMMANDS
  // ============================================================

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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: Esp32Service.instance.isOnline,
      builder: (context, espOnline, _) => StreamBuilder<SensorData>(
        stream: _liveDataStream,
        builder: (context, snapshot) {
          final data = snapshot.data ?? const SensorData();

        // --------------------------------------------------------
        // REAL DEVICE AVAILABILITY
        // --------------------------------------------------------
        //
        // Keep this unchanged.
        //
        // This continues to control actual application behaviour
        // such as enabling/disabling commands.
        //
          final available = data.isDeviceAvailable(DateTime.now());

          return Scaffold(
            body: CustomScrollView(
              slivers: [
                _header(context),

                SliverToBoxAdapter(
                  child: _body(
                    context,
                    data,
                    available,
                    espOnline,
                    snapshot.hasError,
                  ),
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
                // Keep this based on the REAL availability state.
                _showSnack(
                  available
                      ? 'Receiving live RTDB data'
                      : 'ESP32 heartbeat is stale',
                );
              },
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _header(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      floating: true,
      backgroundColor: AppTheme.primary,
      title: const Text('SmartGrow'),

      actions: [
        Padding(
          padding: const EdgeInsets.only(right: AppTheme.space4),
          child: ValueListenableBuilder<int>(
            valueListenable: AlertStore.unreadCount,

            builder: (context, unread, child) {
              return InkResponse(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationScreen(),
                    ),
                  );
                },

                child: Badge(
                  isLabelVisible: unread > 0,
                  label: Text(unread > 9 ? '9+' : '$unread'),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DASHBOARD BODY
  // ============================================================

  Widget _body(
    BuildContext context,
    SensorData data,
    bool available,
    bool uiEspOnline,
    bool hasError,
  ) {
    // ------------------------------------------------------------
    // REAL CONTROL AVAILABILITY
    // ------------------------------------------------------------
    //
    // IMPORTANT:
    // This deliberately uses "available", NOT "uiEspOnline".
    //
    // The UI heartbeat smoothing must never affect whether commands
    // can actually be sent.
    //
    final controlsEnabled = available;

    final waitingForHeartbeat = data.lastHeartbeat == null && !hasError;

    // ------------------------------------------------------------
    // SENSOR DATA
    // ------------------------------------------------------------
    //
    // Sensor freshness remains independent from the UI connection
    // indicator.
    //
    final waterLevel = data.waterLevelStatus.isFresh(DateTime.now())
        ? data.waterLevel
        : null;

    final environmentTemperature =
        data.environmentTempStatus.isFresh(DateTime.now())
        ? data.environmentTemperature
        : null;

    return Padding(
      padding: const EdgeInsets.all(AppTheme.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ======================================================
          // ENVIRONMENT STATUS
          // ======================================================
          EnvironmentStatus(
            // UI-only smoothed connection status.
            isOnline: uiEspOnline,

            isWaiting: waitingForHeartbeat,

            // Sensor values remain real-time.
            sensors: _sensorsFrom(data),

            onToggleOnline: () {
              _showSnack(
                hasError
                    ? 'RTDB connection error'
                    : uiEspOnline
                    ? 'ESP32 connection is online'
                    : 'ESP32 connection appears offline',
              );
            },

            onSensorTap: (sensor) {
              _showSnack(
                '${sensor.label}: '
                '${sensor.value}${sensor.unit}',
              );
            },
          ),

          const SizedBox(height: AppTheme.space3),

          const SectionTitle(title: 'Control Panel'),

          const SizedBox(height: AppTheme.space4),

          // ======================================================
          // CONTROL PANEL
          // ======================================================
          ControlPanel(
            temp: environmentTemperature ?? 0,
            waterLevel: waterLevel ?? 0,

            pumpActive: data.loopPumpOn ?? false,

            fanActive: data.baseFanOn ?? false,

            refillMode: _refillMode(data),

            isActivated: data.humidifierOn ?? false,

            // Uses REAL device availability.
            controlsEnabled: controlsEnabled,

            refillPending: _pending(IotCommandTarget.refillPump),

            humidifierPending: _pending(IotCommandTarget.humidifier),

            onTempChanged: null,
            onWaterLevelChanged: null,

            onRefillModeChanged: _setRefillPumpMode,

            onActivate: () {
              _send(IotCommandTarget.humidifier, !(data.humidifierOn ?? false));
            },

            refillRunning: data.refillPump.running ?? false,

            refillReason: data.refillPump.reason,

            refillFault: data.refillPump.fault,

            humidifierFault: data.statusFor('humidifier').fault,

            pumpFault: data.statusFor('loopPump').fault,

            fanFault: data.statusFor('baseFan').fault,
          ),

          // ======================================================
          // UI-ONLY OFFLINE MESSAGE
          // ======================================================
          //
          // This uses uiEspOnline rather than "available".
          //
          // It therefore gets the heartbeat grace period without
          // affecting sensor or command behaviour.
          //
          if (!uiEspOnline && !waitingForHeartbeat)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'ESP32 is offline. '
                'Waiting for a fresh heartbeat.',
              ),
            ),

          const SizedBox(height: AppTheme.space5),

          // ======================================================
          // DEVICE CONTROLS
          // ======================================================
          _deviceRow(data, controlsEnabled),

          // ======================================================
          // COMMAND ERRORS
          // ======================================================
          if (_error(IotCommandTarget.uvLight) != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'UV command: '
                '${_error(IotCommandTarget.uvLight)}',
              ),
            ),

          if (_error(IotCommandTarget.ventFan) != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Ventilation command: '
                '${_error(IotCommandTarget.ventFan)}',
              ),
            ),

          if (_error(IotCommandTarget.refillPump) != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Refill pump command: '
                '${_error(IotCommandTarget.refillPump)}',
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // REFILL PUMP MODE
  // ============================================================

  RefillMode _refillMode(SensorData data) {
    switch (data.refillPumpMode) {
      case 'auto':
        return RefillMode.auto;

      case 'on':
        return RefillMode.on;

      case 'off':
      default:
        return RefillMode.off;
    }
  }

  Future<void> _setRefillPumpMode(RefillMode mode) {
    final desiredMode = switch (mode) {
      RefillMode.auto => 'auto',
      RefillMode.on => 'on',
      RefillMode.off => 'off',
    };

    return _send(IotCommandTarget.refillPump, desiredMode);
  }

  // ============================================================
  // DEVICE ROW
  // ============================================================

  Widget _deviceRow(SensorData data, bool controlsEnabled) {
    return Row(
      children: [
        Expanded(
          child: DeviceSwitchCard(
            title: 'UV Light',

            description:
                data.statusFor('uvLight').fault ??
                'ESP32-reported controller output.',

            icon: Icons.wb_sunny_outlined,

            // Actual ESP32-reported value.
            value: data.uvLightOn ?? false,

            // Actual device availability.
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

            description:
                data.statusFor('ventFan').fault ??
                'ESP32-reported ventilation fan output.',

            icon: Icons.air_rounded,

            // Actual ESP32-reported value.
            value: data.ventFanOn ?? false,

            // Actual device availability.
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
