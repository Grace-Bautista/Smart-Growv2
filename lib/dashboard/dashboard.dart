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
  void dispose() {
    _commands.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _commands.addListener(_rebuild);
    _commands.start();
  }

  List<Sensor> _sensorsFrom(SensorData data) {
    String reading(double? value, SensorReadingStatus status, int decimals) =>
        status.isFresh(DateTime.now()) && value != null
        ? value.toStringAsFixed(decimals)
        : '--';
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
        unit: 'c',
        icon: Icons.thermostat_outlined,
        hasInfo: true,
      ),
      Sensor(
        label: 'CO2',
        value: reading(data.co2, data.co2Status, 0),
        unit: 'ppm',
        icon: Icons.cloud_outlined,
        hasInfo: true,
      ),
    ];
  }

  void _showSnack(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  Future<void> _send(IotCommandTarget target, Object value) async {
    try {
      await _commands.submit(target, value);
    } catch (error) {
      if (mounted) _showSnack('Command unavailable: $error');
    }
  }

  bool _pending(IotCommandTarget target) => _commands.isPending(target);
  String? _error(IotCommandTarget target) => _commands.errorFor(target);

  @override
  Widget build(BuildContext context) => StreamBuilder<SensorData>(
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
          onTap: (i) => setState(() => _navIndex = i),
          onPowerTap: () => _showSnack(
            available ? 'Receiving live RTDB data' : 'ESP32 heartbeat is stale',
          ),
        ),
      );
    },
  );

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
          const SectionTitle(title: 'Control Panel'),
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
            onRefillModeChanged: (mode) => _setRefillPump(data, mode),
            onActivate: () => _send(
              IotCommandTarget.humidifier,
              !(data.humidifierOn ?? false),
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

  RefillMode _refillMode(SensorData data) =>
      data.refillPumpMode == AutomationMode.automatic
      ? RefillMode.auto
      : (data.refillPumpOn ?? false)
      ? RefillMode.on
      : RefillMode.off;
  Future<void> _setRefillPump(SensorData data, RefillMode mode) =>
      switch (mode) {
        RefillMode.auto => _send(IotCommandTarget.refillPumpMode, 'automatic'),
        RefillMode.on => _send(IotCommandTarget.refillPump, true),
        RefillMode.off => _send(IotCommandTarget.refillPump, false),
      };
  Widget _deviceRow(SensorData data, bool enabled) => Row(
    children: [
      Expanded(
        child: DeviceSwitchCard(
          title: 'UV Light',
          description: 'ESP32-reported controller output.',
          icon: Icons.wb_sunny_outlined,
          value: data.uvLightOn ?? false,
          enabled: enabled && !_pending(IotCommandTarget.uvLight),
          onChanged: (v) => _send(IotCommandTarget.uvLight, v),
        ),
      ),
      const SizedBox(width: AppTheme.space3),
      Expanded(
        child: DeviceSwitchCard(
          title: 'Ventilation',
          description: 'ESP32-reported vent-fan controller output.',
          icon: Icons.air_rounded,
          value: data.ventFanOn ?? false,
          enabled: enabled && !_pending(IotCommandTarget.ventFan),
          onChanged: (v) => _send(IotCommandTarget.ventFan, v),
        ),
      ),
    ],
  );
}
