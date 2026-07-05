import 'package:flutter/material.dart';
import '../../data/models/bt_device_model.dart';

/// ============================================================================
/// DEVICE LIST TILE
/// ============================================================================
/// A single row in the paired-devices list on the Connection Screen.
/// ============================================================================
class DeviceListTile extends StatelessWidget {
  final BtDeviceModel device;
  final bool isConnecting;
  final bool isCurrentlyConnected;
  final VoidCallback onTap;

  const DeviceListTile({
    super.key,
    required this.device,
    required this.onTap,
    this.isConnecting = false,
    this.isCurrentlyConnected = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCurrentlyConnected
              ? scheme.primary.withValues(alpha: 0.6)
              : scheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: ListTile(
        onTap: isConnecting ? null : onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: scheme.primary.withValues(alpha: 0.12),
          child: Icon(Icons.developer_board_rounded, color: scheme.primary),
        ),
        title: Text(
          device.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(device.address),
        trailing: isConnecting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : isCurrentlyConnected
                ? Icon(Icons.check_circle_rounded, color: scheme.primary)
                : const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
