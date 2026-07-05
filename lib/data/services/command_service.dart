import '../../core/constants/bt_commands.dart';
import 'bluetooth_service.dart';

/// ============================================================================
/// COMMAND SERVICE
/// ============================================================================
/// Translates high-level app intents ("turn relay 2 on", "all off") into the
/// exact single-character protocol the ESP32 firmware expects, then sends
/// them through the [AppBluetoothService] transport layer.
///
/// Keeping this separate from AppBluetoothService means the transport layer
/// stays protocol-agnostic, and this layer stays UI-agnostic.
/// ============================================================================
class CommandService {
  final AppBluetoothService _bluetoothService;

  CommandService(this._bluetoothService);

  /// Sends the ON/OFF command for a given relay (0-3).
  Future<bool> setRelay(int relayIndex, bool turnOn) {
    final command = BtCommands.forRelay(relayIndex, turnOn);
    return _bluetoothService.sendCommand(command);
  }

  /// Sends the master "ALL OFF" override command.
  Future<bool> allOff() {
    return _bluetoothService.sendCommand(BtCommands.masterAllOff);
  }

  /// Sends the master "NORMAL MODE" command (releases the override).
  Future<bool> normalMode() {
    return _bluetoothService.sendCommand(BtCommands.masterNormalMode);
  }
}
