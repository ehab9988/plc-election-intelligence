import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n_ext.dart';
import '../../providers/app_providers.dart';
import '../../services/report_service.dart';
import '../../widgets/async_view.dart';
import '../../widgets/registration_status_badge.dart';

class PartyDetailScreen extends ConsumerStatefulWidget {
  final String partyId;

  const PartyDetailScreen({super.key, required this.partyId});

  @override
  ConsumerState<PartyDetailScreen> createState() => _PartyDetailScreenState();
}

class _PartyDetailScreenState extends ConsumerState<PartyDetailScreen> {
  bool _exporting = false;

  Future<void> _exportPdf() async {
    final parties = ref.read(partiesProvider).valueOrNull ?? [];
    final matches = parties.where((p) => p.id == widget.partyId);
    if (matches.isEmpty) return;
    final party = matches.first;
    final l10n = context.l10n;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    setState(() => _exporting = true);
    try {
      final bytes = await ReportService.buildPartyReport(
        party: party,
        title: l10n.reportPartyTitle,
        generatedOnLabel: l10n.generatedOn(''),
        disclaimer: l10n.reportDisclaimer,
        arabic: isArabic,
      );
      await ReportService.previewOrPrint(bytes, 'party-report-${party.id}');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final partiesAsync = ref.watch(partiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.partiesTitle),
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
      body: AsyncView(
        value: partiesAsync,
        builder: (context, parties) {
          final matches = parties.where((p) => p.id == widget.partyId);
          if (matches.isEmpty) {
            return Center(child: Text(l10n.noData));
          }
          final match = matches.first;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  CircleAvatar(radius: 28, child: Text(match.abbreviation?.substring(0, 1) ?? match.nameEn.substring(0, 1))),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.primaryName(en: match.nameEn, ar: match.nameAr),
                          textDirection: context.isArabic ? TextDirection.rtl : TextDirection.ltr,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          context.secondaryName(en: match.nameEn, ar: match.nameAr),
                          textDirection: context.isArabic ? TextDirection.ltr : TextDirection.rtl,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('${l10n.registrationStatus}: '),
                  RegistrationStatusBadge(status: match.registrationStatus),
                ],
              ),
              if (match.registrationStatusVerifiedAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    l10n.verifiedOn(match.registrationStatusVerifiedAt.toString()),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              const SizedBox(height: 16),
              if (match.descriptionEn != null) Text(match.descriptionEn!),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.groups_outlined),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(l10n.candidateListPendingForecast),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
