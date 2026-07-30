import 'package:flutter/material.dart';
import '../dashboard/dashboard.dart';
import '../screens/guide_screen.dart';
import '../screens/logbook_screen.dart';
import '../screens/settings_screen.dart';
import '../theme/app_theme.dart';

/// Bottom bar with four icon items and a raised centre power button —
/// matches the original design's home/docs/power/help/settings row.
class SmartGrowBottomNav extends StatelessWidget {
  final int selectedIndex;
  final VoidCallback onPowerTap;

  const SmartGrowBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onPowerTap,
    required void Function(int) onTap,
  });

  static const _icons = [
    Icons.home_rounded,
    Icons.description_outlined,
    null,
    Icons.help_outline_rounded,
    Icons.settings_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space4,
        vertical: AppTheme.space3,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryLight],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_icons.length, (index) {
            if (_icons[index] == null) {
              return _PowerButton(onTap: onPowerTap);
            }

            return _NavIcon(
              icon: _icons[index]!,
              selected: selectedIndex == index,
              onTap: () {
                if (selectedIndex == index) return;

                Widget page;

                switch (index) {
                  case 0:
                    page = const DashboardScreen();
                    break;
                  case 1:
                    page = const LogBookScreen();
                    break;
                  case 3:
                    page = const GuidesScreen();
                    break;
                  case 4:
                    page = const SettingsScreen();
                    break;
                  default:
                    return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => page),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _NavIcon({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 28,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space2),
        child: Icon(
          icon,
          color: selected ? Colors.white : Colors.white.withOpacity(0.75),
          size: 24,
        ),
      ),
    );
  }
}

/// Raised, glowing centre button — the "power" toggle for the whole system.
class _PowerButton extends StatefulWidget {
  final VoidCallback onTap;
  const _PowerButton({required this.onTap});

  @override
  State<_PowerButton> createState() => _PowerButtonState();
}

class _PowerButtonState extends State<_PowerButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          transform: Matrix4.translationValues(0, _hovering ? -4 : 0, 0),
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppTheme.success,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppTheme.success.withOpacity(0.5),
                blurRadius: _hovering ? 18 : 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Icon(
            Icons.power_settings_new_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
    );
  }
}
