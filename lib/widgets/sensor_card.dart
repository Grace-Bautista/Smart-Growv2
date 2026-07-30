import 'package:flutter/material.dart';
import '../models/sensor.dart';
import '../theme/app_theme.dart';
import 'animated_hover_card.dart';

/// A single sensor reading tile — icon, label, value + unit.
///
/// Sized flexibly by its parent (via [Expanded]/[Wrap]) rather than a
/// fixed width, so it reflows cleanly across phone, tablet and web.
class SensorCard extends StatelessWidget {
  final Sensor sensor;
  final VoidCallback? onTap;

  const SensorCard({super.key, required this.sensor, this.onTap});

  @override
  Widget build(BuildContext context) {
    // Helper function to provide a description for each sensor type. This is used in the info dialog when the help icon is tapped.
    String _sensorDescription(String label) {
      switch (label.toLowerCase()) {
        case 'temperature':
          return 'Measures the current air temperature inside the greenhouse.';

        case 'humidity':
          return 'Measures the relative humidity level of the air.';

        case 'co₂':
        case 'co2':
          return 'Measures the concentration of carbon dioxide in the greenhouse.';

        default:
          return 'Displays the current reading of the $label sensor.';
      }
    }

    return AnimatedHoverCard(
      onTap: onTap,
      radius: AppTheme.radiusSm,
      color: AppTheme.surface,
      border: Border.all(color: AppTheme.divider),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space3,
        vertical: AppTheme.space4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(sensor.icon, size: 18, color: AppTheme.primary),
              const SizedBox(width: AppTheme.space1),
              Expanded(
                child: Text(
                  sensor.label,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline_rounded, size: 18),
                color: AppTheme.textSecondary,
                tooltip: 'More info about ${sensor.label}',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(sensor.label),
                      content: Text(_sensorDescription(sensor.label)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(
                text: sensor.value,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontSize: 20),
                children: [
                  TextSpan(
                    text: sensor.unit,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
