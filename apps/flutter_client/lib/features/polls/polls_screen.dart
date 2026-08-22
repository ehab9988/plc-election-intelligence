import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/app_providers.dart';
import '../../widgets/async_view.dart';

class PollsScreen extends ConsumerWidget {
  const PollsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pollsAsync = ref.watch(pollsProvider);
    final dateFormat = DateFormat.yMMMd();

    return Scaffold(
      appBar: AppBar(title: const Text('Polls')),
      body: AsyncView(
        value: pollsAsync,
        builder: (context, polls) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: polls.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final poll = polls[i];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Fieldwork ${dateFormat.format(poll.fieldworkStart)}–${dateFormat.format(poll.fieldworkEnd)}',
                            style: Theme.of(context).textTheme.titleMedium),
                        if (poll.manuallyVerified)
                          Chip(
                            label: const Text('Verified', style: TextStyle(fontSize: 11)),
                            visualDensity: VisualDensity.compact,
                            avatar: const Icon(Icons.verified, size: 14),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'n = ${poll.sampleSize} · ${poll.population.replaceAll('_', ' ')} · ${poll.mode.replaceAll('_', ' ')}'
                      '${poll.marginOfError != null ? ' · ±${poll.marginOfError!.toStringAsFixed(1)}%' : ''}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(poll.geographicPopulation, style: Theme.of(context).textTheme.bodySmall),
                    const Divider(height: 24),
                    for (final q in poll.questions) ...[
                      Text(q.questionTextEn ?? q.questionTextAr, style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: q.results
                            .map((r) => Chip(
                                  label: Text('${r.label}: ${(r.normalizedPct ?? r.rawResponsePct).toStringAsFixed(0)}%'),
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
