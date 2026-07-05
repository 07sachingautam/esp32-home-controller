import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// ============================================================================
/// ANIMATED POWER ICON
/// ============================================================================
/// A power icon that smoothly animates its color, glow, and scale whenever
/// the relay's ON/OFF state changes — gives the dashboard a "living" feel.
/// ============================================================================
class AnimatedPowerIcon extends StatelessWidget {
  final bool isOn;
  final IconData icon;

  const AnimatedPowerIcon({
    super.key,
    required this.isOn,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final color = isOn ? AppTheme.relayOnColor : AppTheme.relayOffColor;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: isOn ? 1 : 0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.12 + (0.10 * value)),
            boxShadow: value > 0
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35 * value),
                      blurRadius: 16 * value,
                      spreadRadius: 1 * value,
                    ),
                  ]
                : [],
          ),
          child: Transform.scale(
            scale: 0.9 + (0.1 * value),
            child: Icon(icon, color: color, size: 28),
          ),
        );
      },
    );
  }
}
