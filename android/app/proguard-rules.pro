# ============================================================================
# ESP32 Home Controller - ProGuard / R8 rules
# ============================================================================
# Flutter's wrapper classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep Bluetooth Classic serial plugin classes
-keep class io.github.edufolly.** { *; }

# Keep annotation defaults referenced via reflection
-keepattributes *Annotation*

# Ignore warnings from missing optional dependencies pulled in transitively
-dontwarn io.flutter.embedding.**
