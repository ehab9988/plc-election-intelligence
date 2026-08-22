import 'package:flutter/material.dart';

import '../../core/l10n_ext.dart';
import '../../l10n/generated/app_localizations.dart';

/// Section 30 "Methodology" screen — plain-language explanation of every
/// number the app shows. Full technical detail lives in docs/*.md; this
/// screen is the in-app summary a non-technical user can read.
class MethodologyScreen extends StatelessWidget {
  const MethodologyScreen({super.key});

  List<(String, String)> _sections(AppLocalizations l10n) => [
        (l10n.pollingAverage, l10n.methodologyPollingAvgBody),
        (l10n.electionDayForecast, l10n.methodologyForecastBody),
        (l10n.methodologySeatAllocationTitle, l10n.methodologySeatAllocationBody),
        (l10n.methodologyCandidateProbTitle, l10n.methodologyCandidateProbBody),
        (l10n.coalitionLabTitle, l10n.methodologyCoalitionLabBody),
        (l10n.methodologyUncertaintyTitle, l10n.methodologyUncertaintyBody),
      ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.methodologyTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final (title, body) in _sections(l10n))
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(body, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          Text(
            l10n.methodologyFooter,
            style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}
