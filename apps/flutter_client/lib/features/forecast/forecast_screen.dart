import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n_ext.dart';
import '../../providers/app_providers.dart';
import '../../services/report_service.dart';
import '../../widgets/async_view.dart';
import '../../widgets/freshness_banner.dart';
import '../../widgets/party_forecast_card.dart';

/// Section 30 "Forecast" screen: toggles between the polls-only Polling
/// Average and the simulation-based Election-Day Forecast — these are
/// DIFFERENT statistical objects (section 81 terminology) and must never
/// be shown as if they were the same number.
class ForecastScreen extends ConsumerStatefulWidget {
  const ForecastScreen({super.key});

  @override
  ConsumerState<ForecastScreen> createState() => _ForecastScreenState();
}

enum _ForecastView { pollingAverage, electionDay }

class _ForecastScreenState extends ConsumerState<ForecastScreen> {
  _ForecastView _view = _ForecastView.electionDay;
  bool _exporting = false;

  Future<void> _exportPdf() async {
    final l10n = context.l10n;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    setState(() => _exporting = true);
    try {
      final run = await ref.read(latestForecastProvider.future);
      final rules = await ref.read(electionRulesProvider.future);
      final bytes = await ReportService.buildForecastReport(
        run: run,
        rules: rules,
        title: l10n.reportForecastTitle,
        generatedOnLabel: l10n.generatedOn(''),
        modelVersionLabel: l10n.modelVersionLabel,
        seatsLabel: l10n.seatsLabel,
        voteShareLabel: l10n.voteShareLabel,
        disclaimer: l10n.reportDisclaimer,
        arabic: isArabic,
      );
      if (!mounted) return;
      await ReportService.previewOrPrint(context, bytes, 'forecast-report');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final forecastAsync = ref.watch(latestForecastProvider);
    final pollingAvgAsync = ref.watch(pollingAverageProvider);
    final rulesAsync = ref.watch(electionRulesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navForecast),
        actions: [
          IconButton(
            icon: _exporting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.picture_as_pdf_outlined),
            tooltip: l10n.exportPdf,
            onPressed: _exporting ? null : _exportPdf,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<_ForecastView>(
              segments: [
                ButtonSegment(value: _ForecastView.pollingAverage, label: Text(l10n.pollingAverage)),
                ButtonSegment(value: _ForecastView.electionDay, label: Text(l10n.electionDayForecast)),
              ],
              selected: {_view},
              onSelectionChanged: (s) => setState(() => _view = s.first),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _view == _ForecastView.pollingAverage
                  ? AsyncView(
                      value: pollingAvgAsync,
                      builder: (context, points) => ListView(
                        children: [
                          Text(
                            l10n.pollingAverageExplanation,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          ...points.map((p) => Card(
                                child: ListTile(
                                  title: Text(context.primaryName(en: p.listNameEn, ar: p.listNameAr)),
                                  subtitle: Text('${p.nPollsUsed} poll(s) · range ${p.trendLow}–${p.trendHigh}%'),
                                  trailing: Text('${p.weightedAveragePct.toStringAsFixed(1)}%',
                                      style: Theme.of(context).textTheme.titleMedium),
                                ),
                              )),
                        ],
                      ),
                    )
                  : AsyncView(
                      value: forecastAsync,
                      builder: (context, forecast) {
                        final sorted = [...forecast.partyResults]..sort((a, b) => b.seatsMedian.compareTo(a.seatsMedian));
                        return ListView(
                          children: [
                            Wrap(
                              spacing: 12,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                FreshnessBanner(timestamp: forecast.dataCutoffAt, labelPrefix: l10n.dataCutoffLabel),
                                Text(
                                  l10n.modelSimulationsLabel(forecast.modelVersion, forecast.simulationsPerformed),
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              ],
                            ),
                            if (forecast.changeSummary != null) ...[
                              const SizedBox(height: 8),
                              Text(l10n.whyThisChangedLabel(forecast.changeSummary!),
                                  style: Theme.of(context).textTheme.bodySmall),
                            ],
                            const SizedBox(height: 12),
                            ...sorted.map((r) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: PartyForecastCard(
                                    result: r,
                                    totalSeats: rulesAsync.valueOrNull?.totalSeats ?? 132,
                                    useArabicName: context.isArabic,
                                  ),
                                )),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
