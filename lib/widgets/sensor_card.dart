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
          return 'Measures the current air temperature inside the mushroom house.';

        case 'humidity':
          return 'Measures the relative humidity level of the air in the mushroom house.';

        case 'co₂':
        case 'co2':
          return 'Measures the concentration of carbon dioxide in the mushroom house.';

        default:
          return 'Displays the current reading of the $label sensor.';
      }
    }

    return AnimatedHoverCard(
      onTap: onTap,
      radius: AppTheme.radiusSm,
      color: AppTheme.surface,
      border: Border.all(color: AppTheme.divider),

      // Less space at the top
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Sensor icon
              Icon(sensor.icon, size: 14, color: AppTheme.primary),

              const SizedBox(width: 3),

              // Sensor name
              Expanded(
                child: Text(
                  sensor.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),

              const SizedBox(width: 2),

              // Compact info icon - does NOT reserve IconButton's large space
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
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
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Center the reading independently from the header
          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text.rich(
                TextSpan(
                  text: sensor.value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                  children: [
                    TextSpan(
                      text: sensor.unit,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
