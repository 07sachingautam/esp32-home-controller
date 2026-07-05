import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'data/services/preferences_service.dart';
import 'presentation/screens/splash_screen.dart';
import 'providers/bluetooth_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ESP32HomeControllerApp());
}

/// ============================================================================
/// APP ROOT
/// ============================================================================
/// Wires up global providers (Bluetooth state) and Material 3 theming,
/// including persisted light/dark mode preference.
/// ============================================================================
class ESP32HomeControllerApp extends StatefulWidget {
  const ESP32HomeControllerApp({super.key});

  @override
  State<ESP32HomeControllerApp> createState() =>
      _ESP32HomeControllerAppState();
}

class _ESP32HomeControllerAppState extends State<ESP32HomeControllerApp> {
  final PreferencesService _prefsService = PreferencesService();
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final saved = await _prefsService.getThemeMode();
    if (saved == null || !mounted) return;
    setState(() {
      _themeMode = saved == 'dark'
          ? ThemeMode.dark
          : saved == 'light'
              ? ThemeMode.light
              : ThemeMode.system;
    });
  }

  void _toggleTheme() {
    final isCurrentlyDark = _themeMode == ThemeMode.dark ||
        (_themeMode == ThemeMode.system &&
            WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark);
    final newMode = isCurrentlyDark ? ThemeMode.light : ThemeMode.dark;
    setState(() => _themeMode = newMode);
    _prefsService.saveThemeMode(newMode == ThemeMode.dark ? 'dark' : 'light');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _themeMode == ThemeMode.dark ||
        (_themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return ChangeNotifierProvider(
      create: (_) => BluetoothProvider(),
      child: MaterialApp(
        title: 'ESP32 Home Controller',
        debugShowCheckedModeBanner: false,
        themeMode: _themeMode,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: SplashScreen(
          onToggleTheme: _toggleTheme,
          isDarkMode: isDark,
        ),
      ),
    );
  }
}
