import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:smart_grow_code/custom_header_button.dart';
import 'package:smart_grow_code/services/app_settings_service.dart';
import 'package:smart_grow_code/services/esp32_service.dart';
import 'package:smart_grow_code/services/sensor_service.dart';
import 'package:smart_grow_code/models/sensor_data.dart';
import 'package:smart_grow_code/services/user_management_service.dart';
import 'package:smart_grow_code/screens/sensor_test_screen.dart';
import 'package:smart_grow_code/auth/auth_service.dart';
import 'package:smart_grow_code/screens/contact_us_screen.dart';
import 'package:smart_grow_code/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool deviceOn = false;
  bool deviceConnected = false;
  late double headerFontSize;
  late double bodyFontSize;
  bool _saving = false;
  bool _resettingPassword = false;
  StreamSubscription<SensorData>? _deviceSubscription;

  static const _brown = AppTheme.primary;

  @override
  void initState() {
    super.initState();
    final current = AppSettingsService.current;
    headerFontSize = current.headerFontSize;
    bodyFontSize = current.bodyFontSize;
    deviceConnected = Esp32Service.instance.isOnline.value;
    Esp32Service.instance.isOnline.addListener(_applyConnectionStatus);
    _deviceSubscription = SensorService.instance.watchLiveData().listen(
      _applyControllerStatus,
    );
  }

  void _applyConnectionStatus() {
    if (!mounted) return;
    final online = Esp32Service.instance.isOnline.value;
    if (deviceConnected != online) {
      setState(() => deviceConnected = online);
    }
  }

  void _applyControllerStatus(SensorData data) {
    if (!mounted) return;

    final anyControllerOutputOn =
        (data.humidifierOn ?? false) ||
        (data.ventFanOn ?? false) ||
        (data.baseFanOn ?? false) ||
        (data.refillPumpOn ?? false) ||
        (data.loopPumpOn ?? false) ||
        (data.uvLightOn ?? false);

    if (deviceOn != anyControllerOutputOn) {
      setState(() => deviceOn = anyControllerOutputOn);
    }
  }

  @override
  void dispose() {
    Esp32Service.instance.isOnline.removeListener(_applyConnectionStatus);
    _deviceSubscription?.cancel();
    super.dispose();
  }

  Future<void> _saveAndClose() async {
    if (_saving) return;
    setState(() => _saving = true);

    await AppSettingsService.save(
      AppFontSettings(
        headerFontSize: headerFontSize,
        bodyFontSize: bodyFontSize,
      ),
    );

    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _resetOwnPassword() async {
    if (_resettingPassword) return;
    setState(() => _resettingPassword = true);

    try {
      await UserManagementService.resetCurrentUserPassword();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'A password reset email has been sent to your email address.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to send a password reset email right now.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _resettingPassword = false);
      }
    }
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await AuthService.signOut();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _saveAndClose();
      },
      child: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.fromSeed(seedColor: _brown),
          switchTheme: SwitchThemeData(
            thumbColor: WidgetStateProperty.all(AppTheme.primaryLight),
            trackColor: WidgetStateProperty.all(_brown.withValues(alpha: 0.4)),
          ),
          sliderTheme: SliderThemeData(
            activeTrackColor: Colors.green.shade500,
            inactiveTrackColor: Colors.white,
            thumbColor: AppTheme.primaryLight,
            overlayColor: _brown.withValues(alpha: 0.2),
          ),
        ),
        child: Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                CustomHeaderButton(title: 'Settings', onBack: _saveAndClose),
                // Everything below lives in ONE scroll view now — previously
                // only the first card scrolled and the rest (Appearance,
                // Account, Tools, Logout) sat outside it in a fixed-height
                // Column, which is what caused the RenderFlex overflow
                // errors whenever content didn't fit the screen.
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.symmetric(
                      horizontal: screen.width * 0.05,
                      vertical: screen.height * 0.02,
                    ),
                    children: [
                      _sectionLabel('Device'),
                      _glassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _statusIndicator(),
                                const SizedBox(width: 10),
                                // Expanded + overflow handling: this is what
                                // was causing "RenderFlex overflowed by 75
                                // pixels on the right" when the status
                                // message was long on a narrow screen.
                                Expanded(
                                  child: Text(
                                    _getStatusText(),
                                    style: TextStyle(
                                      fontSize: bodyFontSize,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),
                      _sectionLabel('Appearance'),
                      _glassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Header Size: ${headerFontSize.toInt()}',
                              style: TextStyle(fontSize: bodyFontSize),
                            ),
                            Slider(
                              value: headerFontSize,
                              min: 14,
                              max: 30,
                              divisions: 16,
                              label: headerFontSize.toInt().toString(),
                              onChanged: (value) {
                                setState(() => headerFontSize = value);
                              },
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Body Size: ${bodyFontSize.toInt()}',
                              style: TextStyle(fontSize: bodyFontSize),
                            ),
                            Slider(
                              value: bodyFontSize,
                              min: 10,
                              max: 22,
                              divisions: 12,
                              label: bodyFontSize.toInt().toString(),
                              onChanged: (value) {
                                setState(() => bodyFontSize = value);
                              },
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'These changes apply when you go back from Settings.',
                              style: TextStyle(
                                fontSize: (bodyFontSize * 0.85).clamp(10, 20),
                                color: AppTheme.primaryDark,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),
                      _sectionLabel('Account & Security'),
                      _glassCard(
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _resettingPassword
                                ? null
                                : _resetOwnPassword,
                            icon: const Icon(Icons.lock_reset),
                            label: Text(
                              _resettingPassword
                                  ? 'Creating reset link...'
                                  : 'Reset My Password',
                              style: TextStyle(fontSize: bodyFontSize),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),
                      _sectionLabel('Tools & Support'),
                      _glassCard(
                        child: Column(
                          children: [
                            FutureBuilder(
                              future: AuthService.currentAppUser(),
                              builder: (context, snapshot) {
                                final user = snapshot.data;
                                if (user == null || !user.isAdmin) {
                                  return const SizedBox.shrink();
                                }
                                return Column(
                                  children: [
                                    _divider(),
                                    _settingsTile(
                                      icon: Icons.manage_accounts,
                                      title: 'User Management',
                                      onTap: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/admin/users',
                                        );
                                      },
                                    ),
                                  ],
                                );
                              },
                            ),
                            _divider(),
                            _settingsTile(
                              icon: Icons.phone,
                              title: 'Contact Us',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ContactUsScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      // Logout gets its own isolated section at the bottom —
                      // the standard pattern (iOS/Android Settings) of
                      // keeping session/destructive actions separate from
                      // regular tools, so it isn't tapped by accident.
                      const SizedBox(height: 22),
                      _glassCard(
                        child: _settingsTile(
                          icon: Icons.logout,
                          title: 'Logout',
                          iconColor: Colors.red.shade400,
                          titleColor: Colors.red.shade400,
                          bold: true,
                          showChevron: false,
                          onTap: _confirmLogout,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getStatusText() {
    if (!deviceConnected) {
      return 'ESP32 is offline';
    }

    return deviceOn
        ? 'ESP32 is online • One or more controller outputs are ON'
        : 'ESP32 is online • Controller outputs are OFF';
  }

  Widget _statusIndicator() {
    final Color color = deviceConnected ? Colors.green : Colors.grey;
    final IconData icon = deviceConnected
        ? Icons.wifi_rounded
        : Icons.wifi_off_rounded;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }

  /// Small uppercase group label above a card — e.g. "APPEARANCE",
  /// "TOOLS & SUPPORT" — the same grouping pattern used by standard
  /// iOS/Android settings screens.
  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: (bodyFontSize * 0.72).clamp(11, 14),
          fontWeight: FontWeight.w700,
          letterSpacing: 0.9,
          color: AppTheme.primaryLight,
        ),
      ),
    );
  }

  Widget _divider() =>
      Divider(height: 1, indent: 4, color: _brown.withValues(alpha: 0.12));

  /// A single tappable settings row (icon + title + optional chevron).
  ///
  /// Wrapped in its own `Material(type: MaterialType.transparency)` so its
  /// ink splash renders correctly — this is what fixes the "ListTile
  /// background color or ink splashes may be invisible" error, which
  /// happened because a plain `ListTile` was nested inside the glass
  /// card's colored `DecoratedBox` with no Material of its own in between.
  Widget _settingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? titleColor,
    bool bold = false,
    bool showChevron = true,
  }) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Row(
            children: [
              Icon(icon, size: 22, color: iconColor ?? AppTheme.primaryDark),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: bodyFontSize,
                    fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                    color:
                        titleColor ?? Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (showChevron)
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppTheme.primaryLight,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _brown.withValues(alpha: 0.2)),
          ),
          child: child,
        ),
      ),
    );
  }
}
