import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A centred label flanked by thin dividers, e.g. "Control Panel", "Stats".
///
/// [strength] controls visual weight — the outer "Control Panel" title uses
/// [TitleStrength.strong] while inner labels like "Stats" use
/// [TitleStrength.subtle].
enum TitleStrength { strong, subtle, plain }

class SectionTitle extends StatelessWidget {
  final String text;
  final TitleStrength strength;

  const SectionTitle({
    super.key,
    required this.text,
    this.strength = TitleStrength.strong,
  });

  @override
  Widget build(BuildContext context) {
    final style = switch (strength) {
      TitleStrength.strong => Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontSize: 16),
      TitleStrength.subtle => Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: AppTheme.textSecondary,
        fontWeight: FontWeight.w500,
      ),
      TitleStrength.plain => Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
    };

    // "plain" is just centred text with no flanking dividers — used for
    // minor sub-labels like "Stats" inside the Humidifier card.
    if (strength == TitleStrength.plain) {
      return Text(text, textAlign: TextAlign.center, style: style);
    }

    return Row(
      children: [
        Expanded(child: Divider(color: AppTheme.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space3),
          child: Text(text, style: style),
        ),
        Expanded(child: Divider(color: AppTheme.divider)),
      ],
    );
  }
}
