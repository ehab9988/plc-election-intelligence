import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/l10n_ext.dart';
import '../../providers/app_providers.dart';
import '../../widgets/async_view.dart';

class NewsScreen extends ConsumerWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final newsAsync = ref.watch(newsProvider);
    final dateFormat = DateFormat.yMMMd().add_jm();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.newsTitle)),
      body: AsyncView(
        value: newsAsync,
        builder: (context, articles) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: articles.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final article = articles[i];
            return Card(
              child: ListTile(
                title: Text(article.headline),
                subtitle: Text(
                  '${dateFormat.format(article.publishedAt)}'
                  '${article.permittedSnippet != null ? '\n${article.permittedSnippet}' : ''}',
                ),
                isThreeLine: article.permittedSnippet != null,
              ),
            );
          },
        ),
      ),
    );
  }
}
