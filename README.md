# ESP32 Home Controller

A modern Flutter (Material 3) Android app that controls a 4-relay home
automation board over **Classic Bluetooth (HC-05/HC-06/ESP32 SPP)**, using a
simple single-character command protocol.

## ✨ Features

- Runtime Bluetooth + Location permission requests (Android 12+ and legacy)
- Bluetooth adapter status check & enable prompt
- Paired device list with connect/disconnect
- Auto-reconnect to the last connected device on launch
- Live status parsing from the ESP32 (`power;load1;load2;load3;load4;`)
- 4 animated relay cards with instant-send switches
- Master control card: **ALL OFF** / **NORMAL MODE**
- Light & dark Material 3 themes with persisted preference
- Snackbar feedback for every action, robust error handling, no crashes

## 🗂 Project Structure

```
lib/
  core/
    constants/bt_commands.dart      # single source of truth for protocol chars
    theme/app_theme.dart            # Material 3 light/dark theme + gradients
    utils/permission_utils.dart     # runtime permission helpers
  data/
    models/
      relay_status_model.dart       # parsed ESP32 status
      bt_device_model.dart          # paired device wrapper
    services/
      bluetooth_service.dart        # raw SPP transport layer
      command_service.dart          # protocol-aware command sender
      status_parser_service.dart    # buffered, resilient line parser
      preferences_service.dart      # SharedPreferences (last device, theme)
  providers/
    bluetooth_provider.dart         # ChangeNotifier: single source of truth
  presentation/
    screens/
      splash_screen.dart
      home_screen.dart
      connection_screen.dart
    widgets/
      connection_status_bar.dart
      relay_card.dart
      master_control_card.dart
      device_list_tile.dart
      animated_power_icon.dart
  main.dart

android/
  build.gradle                      # root project build config
  settings.gradle                   # plugin management + module includes
  gradle.properties
  gradlew / gradlew.bat             # Gradle wrapper scripts
  gradle/wrapper/gradle-wrapper.properties
  app/
    build.gradle                    # app module config (applicationId, SDKs)
    proguard-rules.pro
    src/
      main/
        AndroidManifest.xml
        kotlin/com/esp32homecontroller/app/MainActivity.kt
        res/
          values/styles.xml
          values-night/styles.xml
          drawable/launch_background.xml
          drawable-v21/launch_background.xml
          mipmap-mdpi/ic_launcher.png
          mipmap-hdpi/ic_launcher.png
          mipmap-xhdpi/ic_launcher.png
          mipmap-xxhdpi/ic_launcher.png
          mipmap-xxxhdpi/ic_launcher.png
      debug/AndroidManifest.xml
      profile/AndroidManifest.xml

test/
  widget_test.dart
```

## 🔌 Bluetooth Command Protocol

Single ASCII characters only, no newline:

| Action              | Command |
|----------------------|---------|
| Relay 1 ON / OFF     | `A` / `a` |
| Relay 2 ON / OFF     | `B` / `b` |
| Relay 3 ON / OFF     | `C` / `c` |
| Relay 4 ON / OFF     | `D` / `d` |
| Master ALL OFF       | `E` |
| Master NORMAL MODE   | `e` |

## 📡 Status Format (ESP32 → App)

```
power;load1;load2;load3;load4;
```
Example: `0;1;0;1;1;`

- `power`: `0` = normal mode, `1` = all loads forced OFF
- `loadN`: `0` = relay ON, `1` = relay OFF

The parser (`status_parser_service.dart`) buffers partial reads and only
emits fully-formed lines, so it never crashes on split/garbled packets.

## 🚀 Getting Started

This repository now contains the **complete** Flutter + Android project:
Dart source, `pubspec.yaml`, full `android/` folder (Gradle build files,
Gradle wrapper scripts, Kotlin `MainActivity`, manifests for main/debug/profile,
launcher icons at every density, styles, launch background, ProGuard rules),
and root project files (`.gitignore`, `.metadata`, `test/widget_test.dart`).

**Only one file could not be generated in this sandbox: `gradle-wrapper.jar`.**
It's a small compiled binary (not source code) that Gradle's own tooling
normally downloads from `services.gradle.org`, and this environment has no
network access. Everything else — including `gradlew`, `gradlew.bat`, and
`gradle-wrapper.properties` (pinned to Gradle 8.9) — is in place. Fix it with
**one** of these (each takes a few seconds, no other manual changes needed):

- **Easiest:** open the project folder in Android Studio once — it detects
  the missing wrapper jar and offers to regenerate it automatically.
- **Or, from a terminal**, if you have any Gradle installed locally:
  ```bash
  cd android
  gradle wrapper --gradle-version 8.9
  ```
- **Or** simply run `flutter run` / `flutter build apk` — recent Flutter
  versions detect a missing wrapper jar and re-provision it automatically
  before invoking Gradle.

### Steps

1. **Get packages**
   ```bash
   flutter pub get
   ```
   This also auto-generates `android/local.properties` with your local
   Flutter SDK path (that file is intentionally gitignored/machine-specific,
   so it isn't included in this zip).

2. **Run**
   ```bash
   flutter run
   ```

3. **Pair your HC-05/HC-06/ESP32** module in the phone's system Bluetooth
   settings first (Classic Bluetooth devices must be bonded at the OS level
   before this app — or any SPP app — can connect to them).

### Project configuration reference

- `applicationId`: `com.esp32homecontroller.app`
- `minSdk`: 23 (Android 6.0) — needed for reliable Bluetooth permission
  behavior with `flutter_bluetooth_serial`
- `targetSdk` / `compileSdk`: 35
- AGP: 8.5.2, Kotlin: 1.9.24, Gradle: 8.9, Java: 17

## 🧩 ESP32 Firmware Notes

Your ESP32 sketch should:
- Accept the single characters above on its Bluetooth Serial (SPP) input
  and toggle the corresponding relay GPIO.
- Continuously transmit `power;load1;load2;load3;load4;` (terminated with
  either `\n` or just the trailing `;`) so the app can reflect live state.

## 📦 Key Dependencies

- `flutter_bluetooth_serial` — Classic Bluetooth SPP
- `provider` — state management
- `permission_handler` — runtime permissions
- `shared_preferences` — persistence
- `google_fonts` — typography
