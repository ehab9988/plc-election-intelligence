import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n_ext.dart';
import '../../models/party.dart';
import '../../providers/app_providers.dart';
import '../../services/report_service.dart';

/// Section 21: candidate seat probability is ALWAYS derived from list rank
/// vs. simulated party seats, never from a fabricated individual vote
/// share (CRITICAL ACCURACY RULE #7). Probability is rounded to whole
/// percent — no false precision (section 21).
class CandidateDetailScreen extends ConsumerStatefulWidget {
  final String candidateId;

  const CandidateDetailScreen({super.key, required this.candidateId});

  @override
  ConsumerState<CandidateDetailScreen> createState() => _CandidateDetailScreenState();
}

class _CandidateDetailScreenState extends ConsumerState<CandidateDetailScreen> {
  bool _exporting = false;

  Future<void> _exportPdf(CandidateDetail detail) async {
    final l10n = context.l10n;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    setState(() => _exporting = true);
    try {
      final bytes = await ReportService.buildCandidateReport(
        fullNameAr: detail.person.fullNameAr,
        fullNameEn: detail.person.fullNameEn,
        listNameEn: detail.electoralList.listNameEn,
        listNameAr: detail.electoralList.listNameAr,
        listRank: detail.candidate.listRank,
        hometown: detail.person.hometown,
        biography: isArabic ? detail.person.biographyAr : detail.person.biographyEn,
        seatProbability: detail.seatProbability,
        seatsMedian: detail.seatsMedian,
        seatsLow80: detail.seatsLow80,
        seatsHigh80: detail.seatsHigh80,
        title: l10n.reportCandidateTitle,
        generatedOnLabel: l10n.generatedOn(''),
        disclaimer: l10n.reportDisclaimer,
        arabic: isArabic,
      );
      await ReportService.previewOrPrint(bytes, 'candidate-report-${detail.candidate.id}');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final repo = ref.watch(partyRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.candidatesTitle)),
      body: FutureBuilder(
        future: repo.getCandidate(widget.candidateId),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final detail = snapshot.data;
          if (detail == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.candidateDetailUnavailable,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final theme = Theme.of(context);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(radius: 36, child: Text(detail.person.fullNameEn.substring(0, 1))),
                  IconButton(
                    icon: _exporting
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.picture_as_pdf_outlined),
                    tooltip: l10n.exportPdf,
                    onPressed: _exporting ? null : () => _exportPdf(detail),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(detail.person.fullNameEn, style: theme.textTheme.headlineSmall),
              Text(detail.person.fullNameAr, textDirection: TextDirection.rtl, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                  '${context.primaryName(en: detail.electoralList.listNameEn, ar: detail.electoralList.listNameAr)} · '
                  '${l10n.listRank(detail.candidate.listRank)}'),
              if (detail.person.hometown != null) Text('${l10n.candidateHometown}: ${detail.person.hometown}'),
              const SizedBox(height: 16),
              if (detail.seatProbability != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.listRank(detail.candidate.listRank), style: theme.textTheme.titleMedium),
                        if (detail.seatsMedian != null)
                          Text('${l10n.seatsLabel}: ${detail.seatsMedian}'
                              '${detail.seatsLow80 != null ? ', 80%: ${detail.seatsLow80}–${detail.seatsHigh80}' : ''}'),
                        const SizedBox(height: 8),
                        Text(
                          '${l10n.seatProbability}: ${(detail.seatProbability! * 100).round()}%',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              if (detail.person.biographyEn != null) ...[
                const SizedBox(height: 16),
                Text(l10n.candidateBiography, style: theme.textTheme.titleMedium),
                Text(detail.person.biographyEn!),
              ],
            ],
          );
        },
      ),
    );
  }
}
