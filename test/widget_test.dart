import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:esp32_home_controller/main.dart';

void main() {
  testWidgets('App launches and shows splash screen', (tester) async {
    await tester.pumpWidget(const ESP32HomeControllerApp());

    // The splash screen should be visible immediately on launch.
    expect(find.text('ESP32 Home Controller'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
