import 'package:permission_handler/permission_handler.dart';

/// ============================================================================
/// PERMISSION UTILS
/// ============================================================================
/// Centralises all runtime permission requests needed for Classic Bluetooth
/// on both legacy (API <= 30) and modern (API >= 31) Android versions.
/// ============================================================================
class PermissionUtils {
  PermissionUtils._();

  /// Requests every permission required to scan/connect over Bluetooth.
  /// Returns true only if ALL required permissions were granted.
  static Future<bool> requestBluetoothPermissions() async {
    final statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    // On older Android versions some of the above permissions don't exist
    // and will report as `denied` without ever prompting; the plugin returns
    // `PermissionStatus.granted` for permissions that aren't applicable to
    // the running OS version in most cases, but to be safe we only require
    // that none were permanently/explicitly denied.
    final allOk = statuses.values.every(
      (status) => status.isGranted || status.isLimited,
    );

    return allOk;
  }

  /// Returns true if any of the required permissions are permanently denied
  /// (meaning the user must be sent to app settings to fix it manually).
  static Future<bool> isPermanentlyDenied() async {
    final results = await Future.wait([
      Permission.bluetoothScan.status,
      Permission.bluetoothConnect.status,
      Permission.location.status,
    ]);
    return results.any((s) => s.isPermanentlyDenied);
  }

  static Future<void> openSettings() async {
    await openAppSettings();
  }
}
