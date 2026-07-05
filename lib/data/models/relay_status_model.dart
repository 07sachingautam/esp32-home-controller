/// ============================================================================
/// RELAY STATUS MODEL
/// ============================================================================
/// Represents the parsed state coming from the ESP32 status string:
///   power;load1;load2;load3;load4;
/// Example: "0;1;0;1;1;"
///
/// power:
///   0 = normal mode
///   1 = all loads OFF (master override active)
///
/// loadN:
///   0 = relay ON
///   1 = relay OFF
/// ============================================================================
class RelayStatusModel {
  /// true when the master override "ALL OFF" is active (power == 1)
  final bool isMasterOff;

  /// List of 4 booleans, true == relay is ON, in order [relay1, relay2, relay3, relay4]
  final List<bool> relaysOn;

  const RelayStatusModel({
    required this.isMasterOff,
    required this.relaysOn,
  });

  /// Sensible default state used before the first status packet arrives.
  factory RelayStatusModel.initial() {
    return const RelayStatusModel(
      isMasterOff: false,
      relaysOn: [false, false, false, false],
    );
  }

  /// Returns a copy of this status with a single relay toggled optimistically
  /// (used to update the UI instantly, before the ESP32 confirms).
  RelayStatusModel copyWithRelay(int index, bool isOn) {
    final updated = List<bool>.from(relaysOn);
    updated[index] = isOn;
    return RelayStatusModel(isMasterOff: isMasterOff, relaysOn: updated);
  }

  RelayStatusModel copyWith({
    bool? isMasterOff,
    List<bool>? relaysOn,
  }) {
    return RelayStatusModel(
      isMasterOff: isMasterOff ?? this.isMasterOff,
      relaysOn: relaysOn ?? this.relaysOn,
    );
  }

  @override
  String toString() =>
      'RelayStatusModel(isMasterOff: $isMasterOff, relaysOn: $relaysOn)';
}
