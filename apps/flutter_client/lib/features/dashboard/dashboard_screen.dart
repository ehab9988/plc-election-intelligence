import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_config.dart';
import '../../core/l10n_ext.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/app_providers.dart';
import '../../widgets/async_view.dart';
import '../../widgets/freshness_banner.dart';
import '../../widgets/party_forecast_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final config = ref.watch(appConfigProvider).valueOrNull;
    final electionAsync = ref.watch(currentElectionProvider);
    final forecastAsync = ref.watch(latestForecastProvider);
    final rulesAsync = ref.watch(electionRulesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppConfig.productName)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(currentElectionProvider);
          ref.invalidate(latestForecastProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (config?.demoMode ?? true)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: MaterialBanner(
                  content: Text(l10n.demoDataBanner),
                  leading: const Icon(Icons.info_outline),
                  actions: [
                    TextButton(onPressed: () => context.go('/settings'), child: Text(l10n.navSettings)),
                  ],
                ),
              ),
            AsyncView(
              value: electionAsync,
              builder: (context, election) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.event, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(election.nameEn, style: Theme.of(context).textTheme.titleMedium),
                            if (election.scheduledDate != null)
                              Text(_countdown(l10n, election.scheduledDate!), style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            AsyncView(
              value: forecastAsync,
              builder: (context, forecast) {
                final sorted = [...forecast.partyResults]..sort((a, b) => b.seatsMedian.compareTo(a.seatsMedian));
                final leader = sorted.isNotEmpty ? sorted.first : null;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(l10n.latestForecastTitle, style: Theme.of(context).textTheme.titleLarge),
                        FreshnessBanner(timestamp: forecast.dataCutoffAt, labelPrefix: l10n.dataCutoffLabel),
                      ],
                    ),
                    if (leader != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 12),
                        child: Text(
                          '${l10n.projectedLargestList}: ${leader.listNameEn} · '
                          '${(leader.probabilityLargestList * 100).round()}%',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ...sorted.map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: PartyForecastCard(
                            result: r,
                            totalSeats: rulesAsync.valueOrNull?.totalSeats ?? 132,
                            onTap: () => context.go('/forecast'),
                          ),
                        )),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(onPressed: () => context.go('/forecast'), child: Text('${l10n.viewFullForecast} →')),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/polls'),
                    icon: const Icon(Icons.poll_outlined),
                    label: Text(l10n.latestPolls),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/coalition-lab'),
                    icon: const Icon(Icons.hub_outlined),
                    label: Text(l10n.coalitionLabTitle),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _countdown(AppLocalizations l10n, DateTime scheduledDate) {
    final days = scheduledDate.toUtc().difference(DateTime.now().toUtc()).inDays;
    if (days > 0) return l10n.daysUntilElection(days);
    return l10n.electionDay;
  }
}
