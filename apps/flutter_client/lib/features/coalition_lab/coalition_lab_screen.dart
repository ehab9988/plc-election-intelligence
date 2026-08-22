import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n_ext.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/coalition.dart';
import '../../providers/app_providers.dart';
import '../../services/report_service.dart';
import '../../widgets/async_view.dart';

/// Interactive Coalition Builder (section 23). Mathematical feasibility
/// (majority probability) is computed live from forecast simulation data;
/// political compatibility evidence is shown separately and never
/// combined into a fabricated "probability of coalition formation"
/// (section 22).
class CoalitionLabScreen extends ConsumerStatefulWidget {
  const CoalitionLabScreen({super.key});

  @override
  ConsumerState<CoalitionLabScreen> createState() => _CoalitionLabScreenState();
}

class _CoalitionLabScreenState extends ConsumerState<CoalitionLabScreen> {
  final Set<String> _selected = {};
  final Map<String, String> _selectedNames = {};
  CoalitionSimulationResult? _result;
  bool _loading = false;
  bool _exporting = false;

  Future<void> _simulate() async {
    if (_selected.isEmpty) {
      setState(() => _result = null);
      return;
    }
    setState(() => _loading = true);
    final forecast = await ref.read(latestForecastProvider.future);
    final result = await ref.read(coalitionRepositoryProvider).simulate(
          forecastRunId: forecast.id,
          electoralListIds: _selected.toList(),
        );
    if (!mounted) return;
    setState(() {
      _result = result;
      _loading = false;
    });
  }

  Future<void> _exportPdf() async {
    if (_result == null) return;
    final l10n = context.l10n;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    setState(() => _exporting = true);
    try {
      final bytes = await ReportService.buildCoalitionReport(
        listNames: _selected.map((id) => _selectedNames[id] ?? id).toList(),
        result: _result!,
        title: l10n.reportCoalitionTitle,
        generatedOnLabel: l10n.generatedOn(''),
        disclaimer: l10n.mathematicalFeasibilityNote,
        arabic: isArabic,
      );
      if (!mounted) return;
      await ReportService.previewOrPrint(context, bytes, 'coalition-report');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final listsAsync = ref.watch(electoralListsProvider);
    final evidenceAsync = ref.watch(coalitionEvidenceProvider);
    final estimatesAsync = ref.watch(coalitionFormationEstimatesProvider);
    final partiesAsync = ref.watch(partiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.coalitionLabTitle),
        actions: [
          IconButton(
            icon: _exporting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.picture_as_pdf_outlined),
            tooltip: l10n.exportPdf,
            onPressed: (_result == null || _exporting) ? null : _exportPdf,
          ),
        ],
      ),
      body: AsyncView(
        value: listsAsync,
        builder: (context, lists) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(l10n.coalitionLabHint, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: lists
                  .map((l) => FilterChip(
                        label: Text(context.primaryName(en: l.listNameEn, ar: l.listNameAr)),
                        selected: _selected.contains(l.id),
                        onSelected: (sel) {
                          setState(() {
                            if (sel) {
                              _selected.add(l.id);
                              _selectedNames[l.id] = context.primaryName(en: l.listNameEn, ar: l.listNameAr);
                            } else {
                              _selected.remove(l.id);
                            }
                          });
                          _simulate();
                        },
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (_result != null) _resultCard(context, l10n, _result!),
            const SizedBox(height: 24),
            Text(l10n.politicalCompatibilityEvidence, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(l10n.mathematicalFeasibilityNote, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            AsyncView(
              value: evidenceAsync,
              builder: (context, evidence) => Column(
                children: evidence
                    .map((e) => Card(
                          child: ListTile(
                            leading: Icon(
                              e.evidenceType == 'supporting' ? Icons.check_circle_outline : Icons.cancel_outlined,
                              color: e.evidenceType == 'supporting' ? Colors.green : Colors.red,
                            ),
                            title: Text(e.statementSummary),
                            subtitle: Text('${l10n.confidenceLabel}: ${e.confidence}'),
                            trailing: e.impliesJointList
                                ? Tooltip(
                                    message: l10n.jointListReportedTooltip,
                                    child: Chip(
                                      avatar: const Icon(Icons.link, size: 16),
                                      label: Text(l10n.jointListReportedLabel),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  )
                                : null,
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 24),
            Text(l10n.aiFormationEstimatesTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(l10n.aiEstimateDisclaimer, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            AsyncView(
              value: estimatesAsync,
              builder: (context, estimates) {
                final parties = partiesAsync.valueOrNull ?? const [];
                String nameFor(String id) {
                  final matches = parties.where((p) => p.id == id);
                  if (matches.isEmpty) return id;
                  return context.primaryName(en: matches.first.nameEn, ar: matches.first.nameAr);
                }

                return Column(
                  children: estimates
                      .map((e) => Card(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: ListTile(
                              leading: const Icon(Icons.auto_awesome_outlined, size: 20),
                              title: Text('${nameFor(e.partyAId)} × ${nameFor(e.partyBId)}'),
                              subtitle: Text(e.reasoning, maxLines: 3, overflow: TextOverflow.ellipsis),
                              trailing: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${e.likelihoodPct.round()}%',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(l10n.aiEstimateLabel, style: Theme.of(context).textTheme.labelSmall),
                                ],
                              ),
                            ),
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultCard(BuildContext context, AppLocalizations l10n, CoalitionSimulationResult result) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.combinedSeats, style: theme.textTheme.labelMedium),
            Text('${result.seatsMedian}  (80% range ${result.seatsLow80}–${result.seatsHigh80})',
                style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(l10n.majorityLine(result.majorityThreshold)),
            const SizedBox(height: 4),
            Text(
              '${l10n.majorityProbability}: ${(result.majorityProbability * 100).round()}%',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
