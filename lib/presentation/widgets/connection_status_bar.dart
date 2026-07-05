import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/bluetooth_service.dart';

/// ============================================================================
/// CONNECTION STATUS BAR
/// ============================================================================
/// Top dashboard header: Bluetooth icon, connection state text, connected
/// device name, and a "battery-like" signal indicator that visually
/// represents connection strength/status.
/// ============================================================================
class ConnectionStatusBar extends StatelessWidget {
  final BtConnectionState state;
  final String? deviceName;
  final VoidCallback onTapChangeDevice;

  const ConnectionStatusBar({
    super.key,
    required this.state,
    required this.deviceName,
    required this.onTapChangeDevice,
  });

  bool get _isConnected => state == BtConnectionState.connected;
  bool get _isBusy =>
      state == BtConnectionState.connecting ||
      state == BtConnectionState.disconnecting;

  String get _statusLabel {
    switch (state) {
      case BtConnectionState.connected:
        return 'Connected';
      case BtConnectionState.connecting:
        return 'Connecting…';
      case BtConnectionState.disconnecting:
        return 'Disconnecting…';
      case BtConnectionState.error:
        return 'Connection error';
      case BtConnectionState.disconnected:
        return 'Not connected';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        gradient: AppTheme.headerGradient(scheme),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (_isConnected ? AppTheme.relayOnColor : scheme.outline)
                    .withValues(alpha: 0.15),
              ),
              child: Icon(
                _isConnected
                    ? Icons.bluetooth_connected_rounded
                    : Icons.bluetooth_disabled_rounded,
                color: _isConnected ? AppTheme.relayOnColor : scheme.outline,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (_isBusy)
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      Text(
                        _statusLabel,
                        style: textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    deviceName ?? 'No device selected',
                    style: textTheme.bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            _SignalIndicator(isConnected: _isConnected),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: onTapChangeDevice,
              icon: const Icon(Icons.settings_bluetooth_rounded),
              tooltip: 'Manage connection',
            ),
          ],
        ),
      ),
    );
  }
}

/// A small battery-like bar indicator representing connection quality/state.
class _SignalIndicator extends StatelessWidget {
  final bool isConnected;
  const _SignalIndicator({required this.isConnected});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final activeColor = isConnected ? AppTheme.relayOnColor : scheme.outline;
    final barsActive = isConnected ? 4 : 1;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (i) {
        final height = 8.0 + (i * 5);
        final active = i < barsActive;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(left: 3),
          width: 4,
          height: height,
          decoration: BoxDecoration(
            color: active ? activeColor : scheme.outlineVariant,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}
