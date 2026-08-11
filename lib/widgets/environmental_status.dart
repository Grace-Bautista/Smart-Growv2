import 'package:flutter/material.dart';
import '../models/sensor.dart';
import '../theme/app_theme.dart';
import 'sensor_card.dart';

/// Top "Environment Status" card: title + online/offline badge, followed
/// by a responsive row/wrap of [SensorCard]s.
class EnvironmentStatus extends StatelessWidget {
  final bool isOnline;
  final bool isWaiting;
  final List<Sensor> sensors;
  final VoidCallback onToggleOnline;
  final ValueChanged<Sensor> onSensorTap;

  const EnvironmentStatus({
    super.key,
    required this.isOnline,
    this.isWaiting = false,
    required this.sensors,
    required this.onToggleOnline,
    required this.onSensorTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space3),
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
              _StatusBadge(
                isOnline: isOnline,
                isWaiting: isWaiting,
                onTap: onToggleOnline,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space3),
          LayoutBuilder(
            builder: (context, constraints) {
              final tileWidth =
                  (constraints.maxWidth - (AppTheme.space2 * 2)) / 3;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < sensors.length; i++) ...[
                    if (i != 0) const SizedBox(width: AppTheme.space2),

                    SizedBox(
                      width: tileWidth,
                      child: SensorCard(
                        sensor: sensors[i],
                        onTap: () => onSensorTap(sensors[i]),
                      ),
                    ),
                  ],
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
  final bool isWaiting;
  final VoidCallback onTap;

  const _StatusBadge({
    required this.isOnline,
    required this.isWaiting,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isOnline
        ? AppTheme.success
        : isWaiting
        ? Colors.orange
        : AppTheme.danger;

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
                isOnline ? 'Online' : isWaiting ? 'Connecting' : 'Offline',
                key: ValueKey((isOnline, isWaiting)),
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
