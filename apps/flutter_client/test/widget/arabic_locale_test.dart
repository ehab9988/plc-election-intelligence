import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plc_election_client/main.dart';
import 'package:plc_election_client/providers/locale_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fixture_overrides.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('switching to Arabic renders Arabic nav labels and RTL layout', (tester) async {
    final container = ProviderContainer(overrides: fixtureProviderOverrides());
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const PlcElectionApp(),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    // Default locale (system, resolves to English in the test harness)
    // shows the English dashboard nav label.
    expect(find.text('Dashboard'), findsWidgets);

    // Force Arabic via the same provider Settings uses.
    await container.read(localeProvider.notifier).setLocale(const Locale('ar'));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    // Arabic nav label from app_ar.arb (navDashboard = "لوحة المعلومات").
    expect(find.text('لوحة المعلومات'), findsWidgets);

    // The whole app tree should now report RTL text direction.
    final directionality = tester.widget<Directionality>(
      find.byType(Directionality).first,
    );
    expect(directionality.textDirection, TextDirection.rtl);
  });
}
