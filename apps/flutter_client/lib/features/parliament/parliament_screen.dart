import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';
import '../../widgets/async_view.dart';
import '../../widgets/parliament_hemicycle.dart';

class ParliamentScreen extends ConsumerWidget {
  const ParliamentScreen({super.key});

  Color _colorFor(String? hex) {
    if (hex == null) return Colors.blueGrey;
    return Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forecastAsync = ref.watch(latestForecastProvider);
    final rulesAsync = ref.watch(electionRulesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Parliament')),
      body: AsyncView(
        value: forecastAsync,
        builder: (context, forecast) {
          final totalSeats = rulesAsync.valueOrNull?.totalSeats ?? 132;
          final majority = rulesAsync.valueOrNull?.majorityThreshold ?? ((totalSeats ~/ 2) + 1);
          final sorted = [...forecast.partyResults]..sort((a, b) => b.seatsMedian.compareTo(a.seatsMedian));
          final groups = sorted
              .map((r) => HemicycleSeatGroup(label: r.listNameEn, seats: r.seatsMedian, color: _colorFor(r.colorHex)))
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Median-seat forecast. Majority line: $majority of $totalSeats seats.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ParliamentHemicycle(groups: groups, totalSeats: totalSeats),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: sorted
                    .map((r) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 10, height: 10, decoration: BoxDecoration(color: _colorFor(r.colorHex), shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Text('${r.listNameEn}: ${r.seatsMedian}'),
                          ],
                        ))
                    .toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}
