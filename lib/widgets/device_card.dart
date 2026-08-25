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
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space4,
        AppTheme.space3,
        AppTheme.space2,
        AppTheme.space3,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Status + help
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _StatusDot(isActive: isActive),
              const Spacer(),
              SizedBox(
                width: 28,
                height: 28,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 16,
                  icon: const Icon(
                    Icons.help_outline_rounded,
                    size: 17,
                    color: AppTheme.textSecondary,
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text(title),
                        content: Text(description),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.space2),

          Transform.translate(
            offset: const Offset(-4, 0),
            child: Icon(icon, size: 30, color: iconColor),
          ),

          const SizedBox(height: AppTheme.space2),

          Transform.translate(
            offset: const Offset(-4, 0),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
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
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space4,
        AppTheme.space3,
        AppTheme.space2,
        AppTheme.space3,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Switch + help
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 42,
                height: 26,
                child: Transform.scale(
                  scale: 0.60,
                  alignment: Alignment.centerLeft,
                  child: Switch(
                    value: value,
                    onChanged: enabled ? onChanged : null,
                    activeTrackColor: AppTheme.success,
                    thumbColor: WidgetStateProperty.all(
                      const Color(0xFFFAF9F7),
                    ),
                  ),
                ),
              ),

              const Spacer(),

              SizedBox(
                width: 24,
                height: 24,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 14,
                  icon: const Icon(
                    Icons.help_outline_rounded,
                    size: 17,
                    color: AppTheme.textSecondary,
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text(title),
                        content: Text(description),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.space3),

          // Device icon + label
          Transform.translate(
            offset: const Offset(-4, 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: accent, size: 22),
                const SizedBox(width: AppTheme.space2),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
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
