import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'animated_hover_card.dart';

/// Small square device tile with a status dot, icon and label — used for
/// "Pump" and "Fan" inside the Humidifier control card.
class DeviceIconTile extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final bool isActive;
  final VoidCallback? onTap;
  final bool enabled;

  const DeviceIconTile({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.isActive,
    required this.onTap,
    this.enabled = true,
    this.iconColor = AppTheme.primary,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedHoverCard(
      onTap: enabled ? onTap : null,
      radius: AppTheme.radiusSm,
      border: Border.all(color: AppTheme.divider),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space4,
        vertical: AppTheme.space3,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatusDot(isActive: isActive),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.help_outline, size: 18),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text(title),
                      content: Text(description),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Close"),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space2),
          Icon(icon, size: 30, color: iconColor),
          const SizedBox(height: AppTheme.space2),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Wider device card with a leading switch, icon, label and optional info
/// icon — used for "UV Light" and "Ventilation" at the bottom of the
/// dashboard.
class DeviceSwitchCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  const DeviceSwitchCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final accent = value ? AppTheme.success : AppTheme.textSecondary;

    return AnimatedHoverCard(
      onTap: enabled ? () => onChanged(!value) : null,
      color: AppTheme.cardSurface,
      padding: const EdgeInsets.all(AppTheme.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Transform.scale(
                scale: 0.70,
                child: Switch(
                  value: value,
                  onChanged: enabled ? onChanged : null,
                  activeTrackColor: AppTheme.success,
                  thumbColor: WidgetStateProperty.all(const Color(0xFFFAF9F7)),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.help_outline),
                iconSize: 18,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text(title),
                      content: Text(description),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Close"),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: AppTheme.space2),

          Row(
            children: [
              Icon(icon, color: accent, size: 22),
              const SizedBox(width: AppTheme.space2),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Small green/red dot that signals whether a device is currently active.
class _StatusDot extends StatelessWidget {
  final bool isActive;
  const _StatusDot({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppTheme.success : AppTheme.textSecondary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: isActive
            ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6)]
            : null,
      ),
    );
  }
}
