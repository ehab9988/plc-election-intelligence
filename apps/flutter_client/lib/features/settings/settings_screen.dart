import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_config.dart';
import '../../core/l10n_ext.dart';
import '../../providers/app_providers.dart';
import '../../providers/locale_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _urlController;
  bool _demoMode = true;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: AppConfig.defaultApiBaseUrl);
    final config = ref.read(appConfigProvider).valueOrNull;
    if (config != null) {
      _urlController.text = config.apiBaseUrl;
      _demoMode = config.demoMode;
    }
  }

  Future<void> _save() async {
    await AppConfig.save(apiBaseUrl: _urlController.text.trim(), demoMode: _demoMode);
    ref.invalidate(appConfigProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.reportGenerated)));
    }
  }

  Future<void> _pickLanguage() async {
    final l10n = context.l10n;
    final current = ref.read(localeProvider);
    // 'system' is a distinct sentinel from "dismissed without choosing" (null),
    // so tapping outside the sheet never accidentally resets the language.
    final options = <(String, Locale?, String)>[
      ('system', null, l10n.languageSystem),
      ('en', const Locale('en'), l10n.languageEnglish),
      ('ar', const Locale('ar'), l10n.languageArabic),
    ];
    final selectedKey = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (key, locale, label) in options)
              ListTile(
                title: Text(label),
                trailing: locale?.languageCode == current?.languageCode ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(context, key),
              ),
          ],
        ),
      ),
    );
    if (selectedKey == null) return;
    final chosen = options.firstWhere((o) => o.$1 == selectedKey).$2;
    if (chosen?.languageCode != current?.languageCode) {
      await ref.read(localeProvider.notifier).setLocale(chosen);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = ref.watch(localeProvider);
    final languageSubtitle = switch (locale?.languageCode) {
      'en' => l10n.languageEnglish,
      'ar' => l10n.languageArabic,
      _ => l10n.languageSystem,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navSettings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: Text(l10n.settingsDemoMode),
            subtitle: const Text(
              'No live backend is configured yet — see README "Getting started" to run the API, '
              'then turn this off and set the API base URL below.',
            ),
            value: _demoMode,
            onChanged: (v) => setState(() => _demoMode = v),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _urlController,
            enabled: !_demoMode,
            decoration: InputDecoration(labelText: l10n.settingsApiBaseUrl, border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _save, child: Text(l10n.settingsSave)),
          const Divider(height: 40),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.settingsLanguage),
            subtitle: Text(languageSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickLanguage,
          ),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: Text(l10n.settingsTheme),
            subtitle: Text('${l10n.settingsThemeLight} / ${l10n.settingsThemeDark} / ${l10n.settingsThemeSystem}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Alerts'),
            subtitle: const Text('Follow parties, candidates, pollsters, governorates'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.workspace_premium_outlined),
            title: const Text('Subscription'),
            subtitle: const Text('Free · Premium · Professional (API access)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
