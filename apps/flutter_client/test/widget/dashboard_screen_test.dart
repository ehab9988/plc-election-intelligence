import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plc_election_client/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fixture_overrides.dart';

void main() {
  setUp(() {
    // In-memory backing so AppConfig.load() (SharedPreferences.getInstance())
    // resolves immediately in the test environment instead of waiting on a
    // platform channel with no native implementation registered.
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('app boots to the dashboard and shows fixture forecast data', (tester) async {
    await tester.pumpWidget(ProviderScope(overrides: fixtureProviderOverrides(), child: const PlcElectionApp()));

    // Splash screen shows first.
    expect(find.byIcon(Icons.how_to_vote), findsOneWidget);

    // Let async config load + splash navigation settle. pumpAndSettle
    // can't be used here: the dashboard's own loading state briefly shows
    // a CircularProgressIndicator, which animates indefinitely.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(find.text('PLC Election Intelligence'), findsWidgets);
    // Fixture forecast data (Fatah List) should render.
    expect(find.textContaining('Fatah List'), findsWidgets);
  });

  testWidgets('bottom navigation switches to the Forecast tab on narrow screens', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(ProviderScope(overrides: fixtureProviderOverrides(), child: const PlcElectionApp()));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    await tester.tap(find.text('Forecast').first);
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(find.text('Polling Average'), findsWidgets);
    expect(find.text('Election-Day Forecast'), findsWidgets);
  });
}
