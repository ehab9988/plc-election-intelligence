import 'package:flutter/material.dart';

import '../models/forecast.dart';
import 'uncertainty_range.dart';

/// Renders one list's forecast the way spec section 82 illustrates:
/// vote estimate + 80% range, seats + 80% range, largest-list probability
/// — never a bare percentage.
class PartyForecastCard extends StatelessWidget {
  final ForecastPartyResult result;
  final int totalSeats;
  final bool useArabicName;
  final VoidCallback? onTap;

  const PartyForecastCard({
    super.key,
    required this.result,
    required this.totalSeats,
    this.useArabicName = false,
    this.onTap,
  });

  Color get _color {
    if (result.colorHex == null) return Colors.blueGrey;
    final hex = result.colorHex!.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = useArabicName ? result.listNameAr : result.listNameEn;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 12, height: 12, decoration: BoxDecoration(color: _color, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(name, style: theme.textTheme.titleMedium, overflow: TextOverflow.ellipsis)),
                  Text('${result.seatsMedian}', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'seats · 80% range ${result.seatsLow80}–${result.seatsHigh80}',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
              ),
              const SizedBox(height: 12),
              UncertaintyRangeBar(
                low: result.seatsLow80.toDouble(),
                median: result.seatsMedian.toDouble(),
                high: result.seatsHigh80.toDouble(),
                max: totalSeats.toDouble(),
                color: _color,
                formatValue: (v) => v.round().toString(),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  _stat(theme, 'Vote share', '${result.forecastVoteShareMedian.toStringAsFixed(1)}%'),
                  _stat(theme, 'Largest-list prob.', _pct(result.probabilityLargestList)),
                  _stat(theme, 'Majority prob.', _pct(result.probabilityMajorityAlone)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _pct(double v) => '${(v * 100).round()}%';

  Widget _stat(ThemeData theme, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline)),
        Text(value, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
