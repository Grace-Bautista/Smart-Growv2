import 'package:flutter/material.dart';
import '../models/sensor.dart';
import '../theme/app_theme.dart';
import 'sensor_card.dart';

/// Top "Environment Status" card: title + online/offline badge, followed
/// by a responsive row/wrap of [SensorCard]s.
class EnvironmentStatus extends StatelessWidget {
  final bool isOnline;
  final List<Sensor> sensors;
  final VoidCallback onToggleOnline;
  final ValueChanged<Sensor> onSensorTap;

  const EnvironmentStatus({
    super.key,
    required this.isOnline,
    required this.sensors,
    required this.onToggleOnline,
    required this.onSensorTap,
  });

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Environment Status',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(fontSize: 19),
                ),
              ),
              const SizedBox(width: AppTheme.space3),
              _StatusBadge(isOnline: isOnline, onTap: onToggleOnline),
            ],
          ),
          const SizedBox(height: AppTheme.space5),
          LayoutBuilder(
            builder: (context, constraints) {
              // Wrap keeps sensor tiles from overflowing on very narrow
              // screens (e.g. a phone rotated, or a resized web window)
              // while still filling the row nicely on wider layouts.
              final tileWidth = (constraints.maxWidth - AppTheme.space3 * 2) / 3;
              final useWrap = tileWidth < 96;

              if (!useWrap) {
                return Row(
                  children: [
                    for (int i = 0; i < sensors.length; i++) ...[
                      if (i != 0) const SizedBox(width: AppTheme.space3),
                      Expanded(
                        child: SensorCard(
                          sensor: sensors[i],
                          onTap: () => onSensorTap(sensors[i]),
                        ),
                      ),
                    ],
                  ],
                );
              }

              return Wrap(
                spacing: AppTheme.space3,
                runSpacing: AppTheme.space3,
                children: [
                  for (final sensor in sensors)
                    SizedBox(
                      width: (constraints.maxWidth - AppTheme.space3) / 2,
                      child: SensorCard(
                        sensor: sensor,
                        onTap: () => onSensorTap(sensor),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}


/// Pill-shaped, tappable Online/Offline indicator with an animated colour
/// crossfade so state changes feel alive rather than snapping instantly.
class _StatusBadge extends StatelessWidget {
  final bool isOnline;
  final VoidCallback onTap;

  const _StatusBadge({required this.isOnline, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = isOnline ? AppTheme.success : AppTheme.danger;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space4,
          vertical: AppTheme.space2,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppTheme.space2),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                isOnline ? 'Online' : 'Offline',
                key: ValueKey(isOnline),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
