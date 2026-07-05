import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/bt_commands.dart';

/// ============================================================================
/// PREFERENCES SERVICE
/// ============================================================================
/// Thin wrapper around SharedPreferences used to remember the last connected
/// device so the app can attempt an automatic reconnect on next launch.
/// ============================================================================
class PreferencesService {
  Future<void> saveLastDevice(String address, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefKeys.lastDeviceAddress, address);
    await prefs.setString(PrefKeys.lastDeviceName, name);
  }

  Future<(String, String)?> getLastDevice() async {
    final prefs = await SharedPreferences.getInstance();
    final address = prefs.getString(PrefKeys.lastDeviceAddress);
    final name = prefs.getString(PrefKeys.lastDeviceName);
    if (address == null || address.isEmpty) return null;
    return (address, name ?? 'Unknown device');
  }

  Future<void> clearLastDevice() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(PrefKeys.lastDeviceAddress);
    await prefs.remove(PrefKeys.lastDeviceName);
  }

  Future<void> saveThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefKeys.themeMode, mode);
  }

  Future<String?> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(PrefKeys.themeMode);
  }
}
