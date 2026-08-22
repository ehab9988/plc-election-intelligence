import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n_ext.dart';
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
    final l10n = context.l10n;
    final isArabic = context.isArabic;
    final forecastAsync = ref.watch(latestForecastProvider);
    final rulesAsync = ref.watch(electionRulesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navParliament)),
      body: AsyncView(
        value: forecastAsync,
        builder: (context, forecast) {
          final totalSeats = rulesAsync.valueOrNull?.totalSeats ?? 132;
          final majority = rulesAsync.valueOrNull?.majorityThreshold ?? ((totalSeats ~/ 2) + 1);
          final sorted = [...forecast.partyResults]..sort((a, b) => b.seatsMedian.compareTo(a.seatsMedian));
          final groups = sorted
              .map((r) => HemicycleSeatGroup(
                  label: isArabic ? r.listNameAr : r.listNameEn, seats: r.seatsMedian, color: _colorFor(r.colorHex)))
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                l10n.medianSeatForecastLine(majority, totalSeats),
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
                            Text('${isArabic ? r.listNameAr : r.listNameEn}: ${r.seatsMedian}'),
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
