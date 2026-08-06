import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Wraps [child] in a rounded, shadowed surface that gently lifts on hover
/// (web/desktop) and scales down slightly on tap (all platforms).
///
/// Centralising this behaviour means every card in the dashboard — sensor
/// tiles, device tiles, the Activate button — shares one consistent feel
/// instead of re-implementing [MouseRegion]/[AnimatedContainer] logic.
class AnimatedHoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Border? border;

  const AnimatedHoverCard({
    super.key,
    required this.child,
    this.onTap,
    this.color,
    this.radius = AppTheme.radiusMd,
    this.padding = const EdgeInsets.all(AppTheme.space4),
    this.border,
  });

  @override
  State<AnimatedHoverCard> createState() => _AnimatedHoverCardState();
}

class _AnimatedHoverCardState extends State<AnimatedHoverCard> {
  bool _hovering = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scale = _pressed ? 0.97 : (_hovering ? 1.015 : 1.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: widget.onTap == null
            ? null
            : (_) => setState(() => _pressed = true),
        onTapUp: widget.onTap == null
            ? null
            : (_) => setState(() => _pressed = false),
        onTapCancel: widget.onTap == null
            ? null
            : () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: widget.padding,
            decoration: BoxDecoration(
              color: widget.color ?? AppTheme.cardSurface,
              borderRadius: BorderRadius.circular(widget.radius),
              border: widget.border,
              boxShadow: _hovering
                  ? AppTheme.hoverShadow()
                  : AppTheme.softShadow(),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
