import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plc_election_client/widgets/parliament_hemicycle.dart';

void main() {
  testWidgets('ParliamentHemicycle renders without throwing for a 132-seat chamber', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ParliamentHemicycle(
            totalSeats: 132,
            groups: const [
              HemicycleSeatGroup(label: 'A', seats: 54, color: Colors.red),
              HemicycleSeatGroup(label: 'B', seats: 48, color: Colors.blue),
              HemicycleSeatGroup(label: 'C', seats: 30, color: Colors.green),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('handles an empty groups list without throwing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ParliamentHemicycle(totalSeats: 132, groups: [])),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
