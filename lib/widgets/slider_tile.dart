import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A labelled, interactive slider used for "Temp" and "Water Level" rows.
///
/// [valueLabel] is shown to the left of the track (e.g. "30" or "30%").
/// An optional [warning] renders in red beneath the track, mirroring the
/// "Critical water level. Please refill." message in the original design.
class SliderTile extends StatelessWidget {
  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final String? warning;
  final Color activeColor;

  const SliderTile({
    super.key,
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 100,
    this.warning,
    this.activeColor = AppTheme.primaryDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: AppTheme.space1),
        Row(
          children: [
            SizedBox(
              width: 34,
              child: Text(
                valueLabel,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textPrimary,
                    ),
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 10,
                  activeTrackColor: activeColor,
                  inactiveTrackColor: AppTheme.divider,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 9,
                  ),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 18),
                  thumbColor: activeColor,
                  overlayColor: activeColor.withOpacity(0.15),
                  trackShape: const RoundedRectSliderTrackShape(),
                ),
                child: Slider(
                  value: value,
                  min: min,
                  max: max,
                  onChanged: onChanged,
                ),
              ),
            ),
          ],
        ),
        if (warning != null) ...[
          const SizedBox(height: AppTheme.space1),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              warning!,
              style: const TextStyle(
                color: AppTheme.danger,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
