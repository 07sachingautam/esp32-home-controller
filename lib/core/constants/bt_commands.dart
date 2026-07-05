/// ============================================================================
/// BLUETOOTH COMMAND PROTOCOL
/// ============================================================================
/// The ESP32 firmware expects EXACTLY ONE ASCII character per command.
/// No newlines, no extra whitespace, no strings — just the raw character.
///
/// This file is the single source of truth for the protocol so the rest of
/// the app never hardcodes a magic character anywhere else.
/// ============================================================================
class BtCommands {
  BtCommands._(); // prevent instantiation

  // ---------------- Relay 1 ----------------
  static const String relay1On = 'A';
  static const String relay1Off = 'a';

  // ---------------- Relay 2 ----------------
  static const String relay2On = 'B';
  static const String relay2Off = 'b';

  // ---------------- Relay 3 ----------------
  static const String relay3On = 'C';
  static const String relay3Off = 'c';

  // ---------------- Relay 4 ----------------
  static const String relay4On = 'D';
  static const String relay4Off = 'd';

  // ---------------- Master ----------------
  static const String masterAllOff = 'E';
  static const String masterNormalMode = 'e';

  /// Returns the correct command character for a given relay index (0-3)
  /// and the desired ON state.
  static String forRelay(int relayIndex, bool turnOn) {
    switch (relayIndex) {
      case 0:
        return turnOn ? relay1On : relay1Off;
      case 1:
        return turnOn ? relay2On : relay2Off;
      case 2:
        return turnOn ? relay3On : relay3Off;
      case 3:
        return turnOn ? relay4On : relay4Off;
      default:
        throw ArgumentError('Invalid relay index: $relayIndex. Must be 0-3.');
    }
  }
}

/// Keys used for persisting data locally via SharedPreferences.
class PrefKeys {
  PrefKeys._();
  static const String lastDeviceAddress = 'last_device_address';
  static const String lastDeviceName = 'last_device_name';
  static const String themeMode = 'theme_mode';
}
