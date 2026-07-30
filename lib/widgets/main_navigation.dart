import 'package:flutter/material.dart';
import 'package:smart_grow_code/dashboard/dashboard.dart';
import 'package:smart_grow_code/screens/guide_screen.dart';
import 'package:smart_grow_code/screens/logbook_screen.dart';
import 'package:smart_grow_code/screens/settings_screen.dart';
import 'bottom_navigation.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    DashboardScreen(),
    LogBookScreen(),
    SizedBox(), // placeholder for power button
    GuidesScreen(),
    SettingsScreen(),
  ];

  void _changeTab(int index) {
    if (index == 2) return;

    setState(() {
      _selectedIndex = index;
    });
  }

  void _powerPressed() {
    // Your existing power logic here
    debugPrint("Power button pressed");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: SmartGrowBottomNav(
        selectedIndex: _selectedIndex,
        onTap: _changeTab,
        onPowerTap: _powerPressed,
      ),
    );
  }
}