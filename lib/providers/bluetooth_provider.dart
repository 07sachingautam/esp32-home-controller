import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/models/bt_device_model.dart';
import '../data/models/relay_status_model.dart';
import '../data/services/bluetooth_service.dart';
import '../data/services/command_service.dart';
import '../data/services/preferences_service.dart';
import '../data/services/status_parser_service.dart';

/// Snackbar-style transient message emitted for the UI to display.
class AppMessage {
  final String text;
  final bool isError;
  AppMessage(this.text, {this.isError = false});
}

/// ============================================================================
/// BLUETOOTH PROVIDER
/// ============================================================================
/// The single source of truth for all Bluetooth-related state in the app:
///   - adapter status
///   - paired device list
///   - connection state & connected device
///   - live relay status (parsed from ESP32 stream)
///   - auto-reconnect to the last used device
///
/// Screens/widgets should only ever talk to this provider — never touch the
/// services directly.
/// ============================================================================
class BluetoothProvider extends ChangeNotifier {
  final AppBluetoothService _btService = AppBluetoothService();
  final StatusParserService _parser = StatusParserService();
  final PreferencesService _prefs = PreferencesService();
  late final CommandService _commandService = CommandService(_btService);

  StreamSubscription<String>? _dataSub;
  StreamSubscription<BtConnectionState>? _stateSub;

  // ---------------- Public observable state ----------------
  bool _isBluetoothEnabled = false;
  bool _isLoading = false;
  bool _isAutoReconnecting = false;
  List<BtDeviceModel> _pairedDevices = [];
  BtConnectionState _connectionState = BtConnectionState.disconnected;
  BtDeviceModel? _connectedDevice;
  RelayStatusModel _relayStatus = RelayStatusModel.initial();

  final StreamController<AppMessage> _messagesController =
      StreamController<AppMessage>.broadcast();

  bool get isBluetoothEnabled => _isBluetoothEnabled;
  bool get isLoading => _isLoading;
  bool get isAutoReconnecting => _isAutoReconnecting;
  List<BtDeviceModel> get pairedDevices => _pairedDevices;
  BtConnectionState get connectionState => _connectionState;
  BtDeviceModel? get connectedDevice => _connectedDevice;
  RelayStatusModel get relayStatus => _relayStatus;
  bool get isConnected => _connectionState == BtConnectionState.connected;
  Stream<AppMessage> get messages => _messagesController.stream;

  BluetoothProvider() {
    _stateSub = _btService.connectionState.listen(_onConnectionStateChanged);
    _dataSub = _btService.incomingData.listen(_onDataReceived);
  }

  void _emit(String text, {bool isError = false}) {
    if (!_messagesController.isClosed) {
      _messagesController.add(AppMessage(text, isError: isError));
    }
  }

  // --------------------------------------------------------------------
  // ADAPTER STATUS
  // --------------------------------------------------------------------

  Future<void> refreshAdapterStatus() async {
    _isBluetoothEnabled = await _btService.isBluetoothEnabled();
    notifyListeners();
  }

  Future<bool> enableBluetooth() async {
    final enabled = await _btService.requestEnableBluetooth();
    _isBluetoothEnabled = enabled;
    notifyListeners();
    if (!enabled) {
      _emit('Bluetooth must be enabled to continue.', isError: true);
    }
    return enabled;
  }

  // --------------------------------------------------------------------
  // DEVICE DISCOVERY
  // --------------------------------------------------------------------

  Future<void> loadPairedDevices() async {
    _isLoading = true;
    notifyListeners();
    try {
      _pairedDevices = await _btService.getPairedDevices();
    } catch (e) {
      _emit('Failed to load paired devices: $e', isError: true);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --------------------------------------------------------------------
  // CONNECTION MANAGEMENT
  // --------------------------------------------------------------------

  Future<void> connectToDevice(BtDeviceModel device) async {
    _isLoading = true;
    notifyListeners();
    try {
      _parser.reset();
      await _btService.connect(device);
      await _prefs.saveLastDevice(device.address, device.name);
      _emit('Connected to ${device.name}');
    } catch (e) {
      _emit('Could not connect to ${device.name}. Make sure it is powered '
          'on and in range.', isError: true);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    _isLoading = true;
    notifyListeners();
    await _btService.disconnect();
    _relayStatus = RelayStatusModel.initial();
    _isLoading = false;
    _emit('Disconnected');
    notifyListeners();
  }

  /// Attempts to silently reconnect to the last-used device, if one was
  /// saved and Bluetooth is currently enabled. Safe to call on app start;
  /// fails silently (no error snackbar) since this is a background attempt.
  Future<void> tryAutoReconnect() async {
    final last = await _prefs.getLastDevice();
    if (last == null) return;
    final (address, name) = last;

    if (!await _btService.isBluetoothEnabled()) return;

    _isAutoReconnecting = true;
    notifyListeners();

    try {
      final paired = await _btService.getPairedDevices();
      final match = paired.where((d) => d.address == address).toList();
      final device = match.isNotEmpty
          ? match.first
          : BtDeviceModel(name: name, address: address, isBonded: true);

      _parser.reset();
      await _btService.connect(device);
      _emit('Reconnected to ${device.name}');
    } catch (_) {
      // Silent failure is intentional for background auto-reconnect.
    } finally {
      _isAutoReconnecting = false;
      notifyListeners();
    }
  }

  void _onConnectionStateChanged(BtConnectionState state) {
    _connectionState = state;
    if (state == BtConnectionState.connected) {
      _connectedDevice = _btService.connectedDevice;
    } else if (state == BtConnectionState.disconnected) {
      _connectedDevice = null;
      _relayStatus = RelayStatusModel.initial();
    }
    notifyListeners();
  }

  void _onDataReceived(String chunk) {
    final statuses = _parser.feed(chunk);
    if (statuses.isEmpty) return;
    // Only the most recent parsed status matters for the UI.
    _relayStatus = statuses.last;
    notifyListeners();
  }

  // --------------------------------------------------------------------
  // RELAY COMMANDS (optimistic UI update + send)
  // --------------------------------------------------------------------

  Future<void> toggleRelay(int index, bool turnOn) async {
    if (!isConnected) {
      _emit('Not connected to any device.', isError: true);
      return;
    }
    // Optimistic update so the switch feels instant.
    _relayStatus = _relayStatus.copyWithRelay(index, turnOn);
    notifyListeners();

    final ok = await _commandService.setRelay(index, turnOn);
    if (!ok) {
      // Revert optimistic update on failure.
      _relayStatus = _relayStatus.copyWithRelay(index, !turnOn);
      notifyListeners();
      _emit('Failed to send command to relay ${index + 1}.', isError: true);
    }
  }

  Future<void> allOff() async {
    if (!isConnected) {
      _emit('Not connected to any device.', isError: true);
      return;
    }
    final ok = await _commandService.allOff();
    if (ok) {
      _emit('All loads switched OFF');
    } else {
      _emit('Failed to send ALL OFF command.', isError: true);
    }
  }

  Future<void> normalMode() async {
    if (!isConnected) {
      _emit('Not connected to any device.', isError: true);
      return;
    }
    final ok = await _commandService.normalMode();
    if (ok) {
      _emit('Switched to Normal Mode');
    } else {
      _emit('Failed to send Normal Mode command.', isError: true);
    }
  }

  @override
  void dispose() {
    _dataSub?.cancel();
    _stateSub?.cancel();
    _messagesController.close();
    _btService.dispose();
    super.dispose();
  }
}
