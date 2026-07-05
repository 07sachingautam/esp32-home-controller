import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

/// ============================================================================
/// BLUETOOTH DEVICE MODEL
/// ============================================================================
/// A thin, app-friendly wrapper around [BluetoothDevice] from
/// flutter_bluetooth_serial so the rest of the app never depends directly on
/// the plugin's types (easier to swap plugins later, easier to test).
/// ============================================================================
class BtDeviceModel {
  final String name;
  final String address;
  final bool isBonded;

  const BtDeviceModel({
    required this.name,
    required this.address,
    required this.isBonded,
  });

  factory BtDeviceModel.fromBluetoothDevice(BluetoothDevice device) {
    return BtDeviceModel(
      name: device.name ?? 'Unknown device',
      address: device.address,
      isBonded: device.isBonded,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BtDeviceModel && other.address == address;

  @override
  int get hashCode => address.hashCode;
}
