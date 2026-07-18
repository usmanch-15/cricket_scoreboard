// Basic smoke test: verifies the app boots and shows the splash screen
// without throwing, since a real widget test would need a live Supabase
// connection to go further (network calls aren't available in the test
// environment).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricket_scoreboard/theme/app_theme.dart';
import 'package:cricket_scoreboard/screens/splash_screen.dart';

void main() {
  testWidgets('Splash screen renders without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: buildAppTheme(), home: const SplashScreen()),
    );

    expect(find.textContaining('CRICKET SCOREBOARD'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}