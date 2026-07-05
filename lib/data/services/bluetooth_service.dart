import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import '../models/bt_device_model.dart';

/// Represents the high-level connection state exposed to the rest of the app.
enum BtConnectionState {
  disconnected,
  connecting,
  connected,
  disconnecting,
  error,
}

/// ============================================================================
/// BLUETOOTH SERVICE
/// ============================================================================
/// Wraps flutter_bluetooth_serial to provide a clean, testable API for:
///   - checking/enabling the Bluetooth adapter
///   - listing paired (bonded) devices
///   - connecting/disconnecting a Classic Bluetooth SPP socket
///   - sending raw single-character commands
///   - streaming incoming raw text data
///
/// This class deliberately knows NOTHING about relays, UI, or the app's
/// command protocol — it is a pure transport layer.
/// ============================================================================
class AppBluetoothService {
  BluetoothConnection? _connection;
  StreamSubscription<Uint8List>? _dataSubscription;

  final StreamController<String> _incomingDataController =
      StreamController<String>.broadcast();
  final StreamController<BtConnectionState> _stateController =
      StreamController<BtConnectionState>.broadcast();

  BtConnectionState _currentState = BtConnectionState.disconnected;
  BtDeviceModel? _connectedDevice;

  /// Stream of raw text chunks received from the ESP32.
  Stream<String> get incomingData => _incomingDataController.stream;

  /// Stream of connection state changes.
  Stream<BtConnectionState> get connectionState => _stateController.stream;

  BtConnectionState get currentState => _currentState;
  BtDeviceModel? get connectedDevice => _connectedDevice;
  bool get isConnected =>
      _currentState == BtConnectionState.connected &&
      _connection != null &&
      _connection!.isConnected;

  void _setState(BtConnectionState state) {
    _currentState = state;
    if (!_stateController.isClosed) {
      _stateController.add(state);
    }
  }

  /// Checks whether the device's Bluetooth adapter is currently enabled.
  Future<bool> isBluetoothEnabled() async {
    final state = await FlutterBluetoothSerial.instance.state;
    return state == BluetoothState.STATE_ON;
  }

  /// Prompts the user with the system dialog to enable Bluetooth.
  /// Returns true if the user enabled it.
  Future<bool> requestEnableBluetooth() async {
    final result = await FlutterBluetoothSerial.instance.requestEnable();
    return result == true;
  }

  /// Returns the list of devices already paired ("bonded") with this phone.
  Future<List<BtDeviceModel>> getPairedDevices() async {
    final devices = await FlutterBluetoothSerial.instance.getBondedDevices();
    return devices.map(BtDeviceModel.fromBluetoothDevice).toList();
  }

  /// Connects to the given device address over Classic Bluetooth (SPP).
  /// Throws an exception on failure — caller is expected to catch it.
  Future<void> connect(BtDeviceModel device) async {
    _setState(BtConnectionState.connecting);
    try {
      final connection = await BluetoothConnection.toAddress(device.address);
      _connection = connection;
      _connectedDevice = device;

      _dataSubscription = connection.input?.listen(
        (Uint8List data) {
          final text = utf8.decode(data, allowMalformed: true);
          if (!_incomingDataController.isClosed) {
            _incomingDataController.add(text);
          }
        },
        onDone: () {
          // Remote side closed the connection.
          _handleUnexpectedDisconnect();
        },
        onError: (_) {
          _handleUnexpectedDisconnect();
        },
        cancelOnError: true,
      );

      _setState(BtConnectionState.connected);
    } catch (e) {
      _setState(BtConnectionState.error);
      _connection = null;
      _connectedDevice = null;
      rethrow;
    }
  }

  void _handleUnexpectedDisconnect() {
    _connection = null;
    _setState(BtConnectionState.disconnected);
  }

  /// Sends a single raw command character (or short string) to the ESP32.
  /// Returns true if the write succeeded.
  Future<bool> sendCommand(String command) async {
    if (!isConnected || _connection == null) return false;
    try {
      _connection!.output.add(Uint8List.fromList(utf8.encode(command)));
      await _connection!.output.allSent;
      return true;
    } catch (e) {
      _handleUnexpectedDisconnect();
      return false;
    }
  }

  /// Gracefully closes the current connection, if any.
  Future<void> disconnect() async {
    if (_connection == null) {
      _setState(BtConnectionState.disconnected);
      return;
    }
    _setState(BtConnectionState.disconnecting);
    try {
      await _dataSubscription?.cancel();
      await _connection?.finish();
      await _connection?.close();
    } catch (_) {
      // Ignore errors during teardown — we're disconnecting regardless.
    } finally {
      _connection = null;
      _connectedDevice = null;
      _setState(BtConnectionState.disconnected);
    }
  }

  /// Releases all resources. Call when the app/provider is disposed.
  void dispose() {
    _dataSubscription?.cancel();
    _connection?.close();
    _incomingDataController.close();
    _stateController.close();
  }
}
