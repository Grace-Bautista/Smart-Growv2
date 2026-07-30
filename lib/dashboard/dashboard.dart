import 'package:flutter/material.dart';
import '../models/sensor.dart';
import '../services/alert_store.dart';
import '../services/esp32_service.dart';
import '../services/sensor_monitor_service.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/control_panel.dart';
import '../widgets/device_card.dart';
import '../widgets/environmental_status.dart';
import 'notification/notification_screen.dart';

/// The single scrollable SmartGrow dashboard screen.
///
/// All mutable state (sliders, switches, dropdown, activation) lives here
/// and is threaded down into the presentational widgets in `widgets/`,
/// keeping every child widget stateless/dumb and easy to reuse or test.
///
/// Sensor values and the online/offline badge come from
/// [SensorMonitorService], which polls the ESP32 in the background and
/// keeps a running log + raises alerts — this screen just displays them.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double _temp = 30;
  double _waterLevel = 30;
  bool _pumpActive = true;
  bool _fanActive = true;
  RefillMode _refillMode = RefillMode.auto;
  bool _isActivated = false;
  bool _uvLightOn = true;
  bool _ventilationOn = false;
  int _navIndex = 0;

  List<Sensor> _sensorsFrom(Esp32Snapshot snap) {
    return [
      Sensor(
        label: 'Humidity',
        value: snap.humidity != null ? snap.humidity!.toStringAsFixed(0) : '--',
        unit: '%',
        icon: Icons.water_drop_outlined,
        hasInfo: true,
      ),
      Sensor(
        label: 'Temp',
        value: snap.temperature != null
            ? snap.temperature!.toStringAsFixed(1)
            : '--',
        unit: 'c',
        icon: Icons.thermostat_outlined,
        hasInfo: true,
      ),
      Sensor(
        label: 'CO2',
        value: snap.co2 != null ? snap.co2.toString() : '--',
        // Was '%' before — CO2 is measured in ppm, not percent.
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
          duration: const Duration(milliseconds: 1200),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
        ),
      );
  }

  Future<void> _forceRefresh() async {
    _showSnack('Checking ESP32...');
    await SensorMonitorService.refreshNow();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Esp32Snapshot>(
      valueListenable: SensorMonitorService.latest,
      builder: (context, snapshot, _) {
        return Scaffold(
          extendBodyBehindAppBar: false,
          body: Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    _buildHeaderSliver(context),
                    SliverToBoxAdapter(child: _buildBody(context, snapshot)),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: SmartGrowBottomNav(
            selectedIndex: _navIndex,
            onTap: (i) => setState(() => _navIndex = i),
            onPowerTap: _forceRefresh,
          ),
        );
      },
    );
  }

  /// Notifications screen.
  Widget _buildHeaderSliver(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      floating: true,
      elevation: 0,
      backgroundColor: AppTheme.primary,
      automaticallyImplyLeading: false,
      toolbarHeight: 64,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primary, AppTheme.primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      title: Text(
        'SmartGrow',
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(color: Colors.white, fontSize: 22),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: AppTheme.space4),
          child: ValueListenableBuilder<int>(
            valueListenable: AlertStore.unreadCount,
            builder: (context, unread, _) {
              return InkResponse(
                radius: 24,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationScreen()),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.notifications_none_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                    if (unread > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.danger,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: AppTheme.primary,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            unread > 9 ? '9+' : '$unread',
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
              );
            },
          ),
        ),
      ],
    );
  }

  /// Main scrollable content, constrained to a comfortable reading width
  /// on large/desktop/web viewports and centred horizontally.
  Widget _buildBody(BuildContext context, Esp32Snapshot snapshot) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final hPad = AppTheme.adaptivePadding(width);
        final maxContentWidth = width >= 900 ? 720.0 : double.infinity;
        final isWide = width >= 700;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                hPad,
                AppTheme.space5,
                hPad,
                AppTheme.space7,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  EnvironmentStatus(
                    isOnline: snapshot.connected,
                    sensors: _sensorsFrom(snapshot),
                    onToggleOnline: _forceRefresh,
                    onSensorTap: (s) =>
                        _showSnack('${s.label}: ${s.value}${s.unit}'),
                  ),
                  const SizedBox(height: AppTheme.space5),
                  const SectionTitle(title: 'Control Panel'),
                  const SizedBox(height: AppTheme.space5),
                  ControlPanel(
                    temp: _temp,
                    waterLevel: _waterLevel,
                    pumpActive: _pumpActive,
                    fanActive: _fanActive,
                    refillMode: _refillMode,
                    isActivated: _isActivated,
                    onTempChanged: (v) => setState(() => _temp = v),
                    onWaterLevelChanged: (v) => setState(() => _waterLevel = v),
                    onTogglePump: () =>
                        setState(() => _pumpActive = !_pumpActive),
                    onToggleFan: () => setState(() => _fanActive = !_fanActive),
                    onRefillModeChanged: (m) => setState(() => _refillMode = m),
                    onActivate: () {
                      setState(() => _isActivated = !_isActivated);
                      _showSnack(
                        _isActivated
                            ? 'Humidifier activated'
                            : 'Humidifier stopped',
                      );
                    },
                  ),
                  const SizedBox(height: AppTheme.space5),
                  _buildDeviceRow(isWide),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// UV Light and Ventilation cards. Side-by-side on any reasonably wide
  /// screen, stacked is on very narrow ones via [Wrap] to avoid overflow.
  Widget _buildDeviceRow(bool isWide) {
    final uvCard = DeviceSwitchCard(
      title: 'UV Light',
      description: 'Controls the UV disinfection lamp connected to the ESP32.',
      icon: Icons.wb_sunny_outlined,
      value: _uvLightOn,
      onChanged: (v) {
        setState(() => _uvLightOn = v);
        _showSnack('UV Light ${v ? 'on' : 'off'}');
      },
    );
    final ventCard = DeviceSwitchCard(
      title: 'Ventilation',
      description: 'Controls the circulation of fresh and exhaust air.',
      icon: Icons.air_rounded,
      value: _ventilationOn,
      onChanged: (v) {
        setState(() => _ventilationOn = v);
        _showSnack('Ventilation ${v ? 'on' : 'off'}');
      },
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: uvCard),
        const SizedBox(width: AppTheme.space3),
        Expanded(child: ventCard),
      ],
    );
  }
}
