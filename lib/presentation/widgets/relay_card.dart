import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'animated_power_icon.dart';

/// ============================================================================
/// RELAY CARD
/// ============================================================================
/// A large, tappable dashboard card representing a single relay/load.
/// Shows the title, an animated power icon, a switch, and a status label.
/// Pressing the switch calls [onChanged] immediately (instant command send).
/// ============================================================================
class RelayCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isOn;
  final bool isEnabled;
  final ValueChanged<bool> onChanged;

  const RelayCard({
    super.key,
    required this.title,
    required this.icon,
    required this.isOn,
    required this.onChanged,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: AppTheme.relayCardGradient(scheme, isOn),
        border: Border.all(
          color: isOn
              ? AppTheme.relayOnColor.withValues(alpha: 0.4)
              : scheme.outlineVariant.withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: isEnabled ? () => onChanged(!isOn) : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AnimatedPowerIcon(isOn: isOn, icon: icon),
                    Switch(
                      value: isOn,
                      onChanged: isEnabled ? onChanged : null,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    isOn ? 'ON' : 'OFF',
                    key: ValueKey<bool>(isOn),
                    style: textTheme.bodyMedium?.copyWith(
                      color: isOn
                          ? AppTheme.relayOnColor
                          : scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
