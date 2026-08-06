import 'package:flutter/material.dart';
import '../humidifier_system_stat/temperature_indicator.dart';
import '../models/sensor.dart';
import '../theme/app_theme.dart';
import 'device_card.dart';
import 'section_title.dart';
import 'slider_tile.dart';

/// The "Humidifier" control card: stats sliders, Pump/Fan tiles, the
/// Refill-water mode dropdown and the Activate button.
class ControlPanel extends StatelessWidget {
  final double temp;
  final double waterLevel;
  final bool pumpActive;
  final bool fanActive;
  final RefillMode refillMode;
  final bool isActivated;
  final ValueChanged<double>? onTempChanged;
  final ValueChanged<double>? onWaterLevelChanged;
  final VoidCallback onTogglePump;
  final VoidCallback onToggleFan;
  final ValueChanged<RefillMode> onRefillModeChanged;
  final VoidCallback onActivate;
  final bool controlsEnabled;
  final bool pumpPending;
  final bool fanPending;
  final bool refillPending;
  final bool humidifierPending;

  const ControlPanel({
    super.key,
    required this.temp,
    required this.waterLevel,
    required this.pumpActive,
    required this.fanActive,
    required this.refillMode,
    required this.isActivated,
    required this.onTempChanged,
    required this.onWaterLevelChanged,
    required this.onTogglePump,
    required this.onToggleFan,
    required this.onRefillModeChanged,
    required this.onActivate,
    required this.controlsEnabled,
    required this.pumpPending,
    required this.fanPending,
    required this.refillPending,
    required this.humidifierPending,
  });

  bool get _isCritical => waterLevel <= 30;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space5),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.softShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Humidifier',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontSize: 17),
          ),
          const SizedBox(height: AppTheme.space3),
          const Divider(color: AppTheme.divider),
          const SizedBox(height: AppTheme.space2),
          const SectionTitle(text: 'Stats', strength: TitleStrength.plain),
          const SizedBox(height: AppTheme.space4),

          // ---- Sliders ---------------------------------------------------
          TemperatureIndicator(temperature: temp),

          const SizedBox(height: AppTheme.space4),
          SliderTile(
            label: 'Water Level',
            valueLabel: '${waterLevel.round()}%',
            value: waterLevel,
            min: 0,
            max: 100,
            onChanged: onWaterLevelChanged,
            warning: _isCritical
                ? 'Critical water level. Please refill.'
                : null,
          ),
          const SizedBox(height: AppTheme.space5),

          // ---- Pump / Fan tiles -------------------------------------------
          LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                children: [
                  Expanded(
                    child: DeviceIconTile(
                      title: 'Pump',
                      description: 'Controls the water circulation system.',
                      icon: Icons.compare_arrows,
                      isActive: pumpActive,
                      onTap: onTogglePump,
                      enabled: controlsEnabled && !pumpPending,
                    ),
                  ),
                  const SizedBox(width: AppTheme.space3),
                  Expanded(
                    child: DeviceIconTile(
                      title: 'Fan',
                      description: 'Controls the air circulation system.',
                      icon: Icons.cyclone,
                      isActive: fanActive,
                      onTap: onToggleFan,
                      enabled: controlsEnabled && !fanPending,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppTheme.space5),

          // ---- Refill water dropdown --------------------------------------
          _RefillDropdown(
            mode: refillMode,
            onChanged: controlsEnabled && !refillPending
                ? onRefillModeChanged
                : null,
          ),
          const SizedBox(height: AppTheme.space4),

          // ---- Activate button ---------------------------------------------
          _ActivateButton(
            isActivated: isActivated,
            onTap: controlsEnabled && !humidifierPending ? onActivate : null,
          ),
        ],
      ),
    );
  }
}

/// Dropdown that lets the user pick between On / Off / Auto refill modes.
class _RefillDropdown extends StatelessWidget {
  final RefillMode mode;
  final ValueChanged<RefillMode>? onChanged;

  const _RefillDropdown({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space4,
        vertical: AppTheme.space1,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.divider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<RefillMode>(
          value: mode,
          isExpanded: true,
          icon: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          items: [
            for (final m in RefillMode.values)
              DropdownMenuItem(value: m, child: Text(m.label)),
          ],
          selectedItemBuilder: (context) {
            return [
              for (final _ in RefillMode.values)
                Row(
                  children: [
                    const Text(
                      'Refill water',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      mode.label,
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
            ];
          },
          onChanged: (value) {
            if (value != null) onChanged?.call(value);
          },
        ),
      ),
    );
  }
}

/// Full-width call-to-action button with a subtle gradient and animated
/// state swap between "Activate" and "Activated".
class _ActivateButton extends StatefulWidget {
  final bool isActivated;
  final VoidCallback? onTap;

  const _ActivateButton({required this.isActivated, required this.onTap});

  @override
  State<_ActivateButton> createState() => _ActivateButtonState();
}

class _ActivateButtonState extends State<_ActivateButton> {
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
          duration: const Duration(milliseconds: 200),
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(
              colors: widget.isActivated
                  ? [AppTheme.success, const Color(0xFF2E9E56)]
                  : [AppTheme.primary, AppTheme.primaryLight],
            ),
            boxShadow: [
              BoxShadow(
                color:
                    (widget.isActivated ? AppTheme.success : AppTheme.primary)
                        .withOpacity(_hovering ? 0.45 : 0.3),
                blurRadius: _hovering ? 20 : 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Row(
              key: ValueKey(widget.isActivated),
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.isActivated
                      ? Icons.check_circle
                      : Icons.power_settings_new,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.space2),
                Text(
                  widget.isActivated ? 'Activated' : 'Activate',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
