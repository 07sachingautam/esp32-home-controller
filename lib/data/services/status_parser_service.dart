import '../models/relay_status_model.dart';

/// ============================================================================
/// STATUS PARSER SERVICE
/// ============================================================================
/// Parses raw text streamed from the ESP32 over the serial connection.
///
/// The ESP32 continuously sends lines shaped like:
///   power;load1;load2;load3;load4;
/// e.g. "0;1;0;1;1;"
///
/// Because Bluetooth SPP data can arrive in arbitrary chunks (a single UI
/// "line" may be split across several socket reads, or several lines may
/// arrive in one read), this service keeps an internal buffer and only emits
/// fully-formed, valid status lines.
/// ============================================================================
class StatusParserService {
  /// Internal buffer holding bytes that haven't yet formed a complete line.
  final StringBuffer _buffer = StringBuffer();

  /// Feeds a raw chunk of incoming text into the parser.
  ///
  /// Returns a list of every valid [RelayStatusModel] found in this chunk
  /// (usually 0 or 1, but could be more if multiple packets arrived at once).
  List<RelayStatusModel> feed(String chunk) {
    _buffer.write(chunk);
    final combined = _buffer.toString();

    // Split on newlines OR on the trailing ';' terminator the firmware uses,
    // whichever appears — this makes the parser resilient to firmware
    // variants that do/don't send a newline after the status string.
    final parts = combined.split(RegExp(r'[\r\n]+'));

    final results = <RelayStatusModel>[];

    // The last part might be incomplete (no trailing newline yet), so we
    // keep it in the buffer and only process the earlier, complete parts.
    for (var i = 0; i < parts.length - 1; i++) {
      final line = parts[i].trim();
      final parsed = _tryParseLine(line);
      if (parsed != null) results.add(parsed);
    }

    // Handle firmware that never sends a newline, only terminates with ';'
    final remainder = parts.last;
    final semiSplit = remainder.split(';');
    if (remainder.trim().endsWith(';') && semiSplit.length >= 6) {
      final reconstructed = '${semiSplit[0]};${semiSplit[1]};${semiSplit[2]};'
          '${semiSplit[3]};${semiSplit[4]};';
      final parsed = _tryParseLine(reconstructed);
      if (parsed != null) {
        results.add(parsed);
        _buffer.clear();
        return results;
      }
    }

    _buffer
      ..clear()
      ..write(remainder);

    return results;
  }

  /// Attempts to parse a single line such as "0;1;0;1;1;".
  /// Returns null if the line is malformed (never throws).
  RelayStatusModel? _tryParseLine(String line) {
    if (line.isEmpty) return null;

    // Remove a trailing ';' if present, then split.
    final cleaned = line.endsWith(';')
        ? line.substring(0, line.length - 1)
        : line;
    final fields = cleaned.split(';').map((e) => e.trim()).toList();

    if (fields.length != 5) return null;

    final values = <int>[];
    for (final f in fields) {
      final n = int.tryParse(f);
      if (n == null || (n != 0 && n != 1)) return null;
      values.add(n);
    }

    final power = values[0];
    final loads = values.sublist(1); // [load1, load2, load3, load4]

    return RelayStatusModel(
      isMasterOff: power == 1,
      // load == 0 means relay ON, load == 1 means relay OFF
      relaysOn: loads.map((v) => v == 0).toList(),
    );
  }

  /// Clears any partially-buffered data (call on disconnect/reconnect).
  void reset() => _buffer.clear();
}
