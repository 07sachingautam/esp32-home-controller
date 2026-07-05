import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/permission_utils.dart';
import '../../data/services/bluetooth_service.dart';
import '../../providers/bluetooth_provider.dart';
import '../widgets/device_list_tile.dart';

/// ============================================================================
/// CONNECTION SCREEN
/// ============================================================================
/// Lets the user:
///   - see current Bluetooth adapter status and enable it if needed
///   - view the list of paired devices
///   - connect to a chosen device
///   - disconnect from the currently connected device
/// ============================================================================
class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    final granted = await PermissionUtils.requestBluetoothPermissions();
    if (!mounted) return;

    if (!granted) {
      setState(() => _permissionDenied = true);
      return;
    }

    final provider = context.read<BluetoothProvider>();
    await provider.refreshAdapterStatus();

    if (!provider.isBluetoothEnabled) {
      await provider.enableBluetooth();
    }

    if (provider.isBluetoothEnabled) {
      await provider.loadPairedDevices();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BluetoothProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Device'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh paired devices',
            onPressed: provider.isLoading
                ? null
                : () async {
                    await provider.refreshAdapterStatus();
                    if (provider.isBluetoothEnabled) {
                      await provider.loadPairedDevices();
                    }
                  },
          ),
        ],
      ),
      body: _permissionDenied
          ? _buildPermissionDeniedView()
          : !provider.isBluetoothEnabled
              ? _buildBluetoothDisabledView(provider)
              : _buildDeviceListView(provider),
    );
  }

  Widget _buildPermissionDeniedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.privacy_tip_rounded, size: 56, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Bluetooth & Location permissions are required to scan and '
              'connect to your ESP32 device.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () async {
                await PermissionUtils.openSettings();
              },
              child: const Text('Open App Settings'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () {
                setState(() => _permissionDenied = false);
                _initialize();
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBluetoothDisabledView(BluetoothProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bluetooth_disabled_rounded,
                size: 56, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Bluetooth is turned off.\nEnable it to see paired devices.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              icon: const Icon(Icons.bluetooth_rounded),
              label: const Text('Enable Bluetooth'),
              onPressed: () async {
                final ok = await provider.enableBluetooth();
                if (ok) await provider.loadPairedDevices();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceListView(BluetoothProvider provider) {
    return RefreshIndicator(
      onRefresh: provider.loadPairedDevices,
      child: Column(
        children: [
          if (provider.isConnected) _buildConnectedBanner(provider),
          Expanded(
            child: provider.isLoading && provider.pairedDevices.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : provider.pairedDevices.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                        itemCount: provider.pairedDevices.length,
                        itemBuilder: (context, index) {
                          final device = provider.pairedDevices[index];
                          final isCurrent =
                              provider.connectedDevice?.address ==
                                  device.address;
                          return DeviceListTile(
                            device: device,
                            isCurrentlyConnected: isCurrent,
                            isConnecting: provider.isLoading && !isCurrent,
                            onTap: () => provider.connectToDevice(device),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedBanner(BluetoothProvider provider) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.bluetooth_connected_rounded),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Connected to ${provider.connectedDevice?.name ?? ""}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: provider.isLoading ? null : provider.disconnect,
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.devices_other_rounded, size: 56, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No paired devices found.\nPair your HC-05/HC-06/ESP32 module '
              'in your phone\'s Bluetooth settings first.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper extension so callers can quickly interpret BtConnectionState in the
/// widget tree without repeating switch statements.
extension BtConnectionStateX on BtConnectionState {
  bool get isBusy =>
      this == BtConnectionState.connecting ||
      this == BtConnectionState.disconnecting;
}
