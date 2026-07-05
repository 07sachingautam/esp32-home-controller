import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// ============================================================================
/// MASTER CONTROL CARD
/// ============================================================================
/// Bottom dashboard card exposing the two master-level commands:
///   - ALL OFF     -> forces every load off, overriding individual switches
///   - NORMAL MODE -> releases the override, returns to per-relay control
/// ============================================================================
class MasterControlCard extends StatelessWidget {
  final bool isMasterOff;
  final bool isEnabled;
  final VoidCallback onAllOff;
  final VoidCallback onNormalMode;

  const MasterControlCard({
    super.key,
    required this.isMasterOff,
    required this.onAllOff,
    required this.onNormalMode,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: scheme.surfaceContainerHigh,
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, color: scheme.primary),
              const SizedBox(width: 10),
              Text(
                'Master Control',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isMasterOff
                      ? AppTheme.dangerColor.withValues(alpha: 0.15)
                      : AppTheme.relayOnColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isMasterOff ? 'OVERRIDE ACTIVE' : 'NORMAL',
                  style: textTheme.labelSmall?.copyWith(
                    color: isMasterOff
                        ? AppTheme.dangerColor
                        : AppTheme.relayOnColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isEnabled ? onAllOff : null,
                  icon: const Icon(Icons.power_settings_new_rounded),
                  label: const Text('ALL OFF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.dangerColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isEnabled ? onNormalMode : null,
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('NORMAL MODE'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.relayOnColor,
                    side: const BorderSide(color: AppTheme.relayOnColor),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
