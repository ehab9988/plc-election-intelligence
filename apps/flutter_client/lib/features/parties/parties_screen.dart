import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n_ext.dart';
import '../../providers/app_providers.dart';
import '../../widgets/async_view.dart';
import '../../widgets/registration_status_badge.dart';

class PartiesScreen extends ConsumerStatefulWidget {
  const PartiesScreen({super.key});

  @override
  ConsumerState<PartiesScreen> createState() => _PartiesScreenState();
}

class _PartiesScreenState extends ConsumerState<PartiesScreen> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final partiesAsync = ref.watch(partiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.partiesTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: l10n.searchHint,
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),
      ),
      body: AsyncView(
        value: partiesAsync,
        builder: (context, parties) {
          final q = _controller.text.trim().toLowerCase();
          final filtered = q.isEmpty
              ? parties
              : parties
                  .where((p) => p.nameEn.toLowerCase().contains(q) || p.nameAr.contains(_controller.text))
                  .toList();
          return ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, i) {
              final party = filtered[i];
              final primary = context.primaryName(en: party.nameEn, ar: party.nameAr);
              final secondary = context.secondaryName(en: party.nameEn, ar: party.nameAr);
              return ListTile(
                leading: CircleAvatar(child: Text(party.abbreviation?.substring(0, 1) ?? party.nameEn.substring(0, 1))),
                title: Text(primary, textDirection: context.isArabic ? TextDirection.rtl : TextDirection.ltr),
                subtitle: Text(secondary, textDirection: context.isArabic ? TextDirection.ltr : TextDirection.rtl),
                trailing: RegistrationStatusBadge(status: party.registrationStatus),
                onTap: () => context.go('/parties/${party.id}'),
              );
            },
          );
        },
      ),
    );
  }
}
