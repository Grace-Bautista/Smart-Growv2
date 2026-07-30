import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:smart_grow_code/custom_header_button.dart';
import 'package:smart_grow_code/services/app_settings_service.dart';
import 'package:smart_grow_code/services/sensor_service.dart';
import 'package:smart_grow_code/models/sensor_data.dart';
import 'package:smart_grow_code/services/user_management_service.dart';
import 'package:smart_grow_code/screens/sensor_test_screen.dart';
import 'package:smart_grow_code/auth/auth_service.dart';
import 'package:smart_grow_code/screens/contact_us_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool scheduleEnabled = false;
  double intervalHours = 6;
  bool deviceOn = false;
  bool deviceConnected = false;
  late double headerFontSize;
  late double bodyFontSize;
  bool _saving = false;
  bool _resettingPassword = false;
  StreamSubscription<SensorData>? _deviceSubscription;

  @override
  void initState() {
    super.initState();
    final current = AppSettingsService.current;
    headerFontSize = current.headerFontSize;
    bodyFontSize = current.bodyFontSize;
    _deviceSubscription = SensorService.instance.watchLiveData().listen(_applyDeviceStatus);
  }

  void _applyDeviceStatus(SensorData data) {
    if (!mounted) return;
    setState(() {
      deviceConnected = data.isDeviceAvailable(DateTime.now());
      deviceOn = (data.humidifierOn ?? false) || (data.ventFanOn ?? false) ||
          (data.baseFanOn ?? false) || (data.refillPumpOn ?? false) ||
          (data.loopPumpOn ?? false) || (data.uvLightOn ?? false);
    });
  }

  @override
  void dispose() { _deviceSubscription?.cancel(); super.dispose(); }

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

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;

    return WillPopScope(
      onWillPop: () async {
        await _saveAndClose();
        return false;
      },
      child: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
          switchTheme: SwitchThemeData(
            thumbColor: WidgetStateProperty.all(Colors.brown.shade600),
            trackColor: WidgetStateProperty.all(Colors.brown.withOpacity(0.4)),
          ),
          sliderTheme: SliderThemeData(
            activeTrackColor: Colors.brown.shade500,
            inactiveTrackColor: Colors.grey.shade400,
            thumbColor: Colors.brown.shade700,
            overlayColor: Colors.brown.withOpacity(0.2),
          ),
        ),
        child: Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFF5E6D3),
                  Color(0xFFE6CCB2),
                  Color(0xFFD2B48C),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  CustomHeaderButton(
                    title: 'Settings',
                    onBack: () {
                      _saveAndClose();
                    },
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(screen.width * 0.05),
                      child: Column(
                        children: [
                          _glassCard(
                            child: Row(
                              children: [
                                _statusIndicator(),
                                const SizedBox(width: 10),
                                Text(
                                  _getStatusText(),
                                  style: TextStyle(
                                    fontSize: bodyFontSize,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.brown.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: screen.height * 0.02),
                          _glassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _title('Scheduling'),
                                SwitchListTile(
                                  value: scheduleEnabled,
                                  onChanged: (val) {
                                    setState(() => scheduleEnabled = val);
                                  },
                                  title: Text(
                                    'Enable Schedule',
                                    style: TextStyle(fontSize: bodyFontSize),
                                  ),
                                ),
                                Text(
                                  'Every ${intervalHours.toInt()} hours',
                                  style: TextStyle(
                                    fontSize: bodyFontSize,
                                    color: Colors.brown,
                                  ),
                                ),
                                Slider(
                                  value: intervalHours,
                                  min: 1,
                                  max: 24,
                                  divisions: 23,
                                  onChanged: (value) {
                                    setState(() => intervalHours = value);
                                  },
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: screen.height * 0.02),
                          _glassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _title('Text Size Settings'),
                                const SizedBox(height: 10),
                                Text(
                                  'Header Size: ${headerFontSize.toInt()}',
                                  style: TextStyle(fontSize: bodyFontSize),
                                ),
                                Slider(
                                  value: headerFontSize,
                                  min: 14,
                                  max: 30,
                                  divisions: 16,
                                  onChanged: (value) {
                                    setState(() => headerFontSize = value);
                                  },
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Body Size: ${bodyFontSize.toInt()}',
                                  style: TextStyle(fontSize: bodyFontSize),
                                ),
                                Slider(
                                  value: bodyFontSize,
                                  min: 10,
                                  max: 22,
                                  divisions: 12,
                                  onChanged: (value) {
                                    setState(() => bodyFontSize = value);
                                  },
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'These changes apply when you go back from Settings.',
                                  style: TextStyle(
                                    fontSize: bodyFontSize * 0.9,
                                    color: Colors.brown.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: screen.height * 0.02),
                          _glassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _title('Account Security'),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _resettingPassword
                                        ? null
                                        : _resetOwnPassword,
                                    icon: const Icon(Icons.lock_reset),
                                    label: Text(
                                      _resettingPassword
                                          ? 'Creating reset link...'
                                          : 'Reset My Password',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: screen.height * 0.02),

                          _glassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _title('Tools'),
                                const SizedBox(height: 10),

                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.sensors),
                                  title: Text(
                                    'Sensor Data Test',
                                    style: TextStyle(fontSize: bodyFontSize),
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => SensorTestScreen(),
                                      ),
                                    );
                                  },
                                ),

                                FutureBuilder(
                                  future: AuthService.currentAppUser(),
                                  builder: (context, snapshot) {
                                    final user = snapshot.data;

                                    if (user == null || !user.isAdmin) {
                                      return const SizedBox.shrink();
                                    }

                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: const Icon(
                                        Icons.manage_accounts,
                                      ),
                                      title: Text(
                                        'User Management',
                                        style: TextStyle(
                                          fontSize: bodyFontSize,
                                        ),
                                      ),
                                      onTap: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/admin/users',
                                        );
                                      },
                                    );
                                  },
                                ),

                                /// CONTACT
                                ListTile(
                                  leading: const Icon(Icons.phone),
                                  title: const Text('Contact Us'),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const ContactUsScreen(),
                                      ),
                                    );
                                  },
                                ),

                                /// LOGOUT
                                ListTile(
                                  leading: const Icon(
                                    Icons.logout,
                                    color: Colors.red,
                                  ),
                                  title: const Text(
                                    'Logout',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onTap: () async {
                                    final shouldLogout = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text("Confirm Logout"),
                                        content: const Text(
                                          "Are you sure you want to log out?",
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text("Cancel"),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text("Logout"),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (shouldLogout == true) {
                                      await AuthService.signOut();
                                      if (!context.mounted) return;
                                      Navigator.pushNamedAndRemoveUntil(
                                        context,
                                        '/',
                                        (_) => false,
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getStatusText() {
    if (!deviceConnected) return 'ESP32 not connected';
    return deviceOn ? 'One or more controller outputs are ON' : 'Controller outputs are OFF';
  }

  Widget _statusIndicator() {
    Color color;
    IconData icon;

    if (!deviceConnected) {
      color = Colors.grey;
      icon = Icons.wifi_off;
    } else if (deviceOn) {
      color = Colors.green;
      icon = Icons.power;
    } else {
      color = Colors.red;
      icon = Icons.power_off;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }

  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.35),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.brown.withOpacity(0.2)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _title(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: headerFontSize,
        fontWeight: FontWeight.bold,
        color: Colors.brown.shade800,
      ),
    );
  }
}
