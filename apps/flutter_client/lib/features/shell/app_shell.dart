import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n_ext.dart';
import '../../l10n/generated/app_localizations.dart';

/// Adaptive navigation: NavigationRail on desktop-width windows (section
/// 47 — Windows gets a sidebar, not a stretched phone layout), bottom
/// navigation on phones (section 30). Labels are fully localized — Arabic
/// is a first-class language (section 31), not an afterthought.
class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  static const _icons = [
    (icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard),
    (icon: Icons.show_chart_outlined, selectedIcon: Icons.show_chart),
    (icon: Icons.event_seat_outlined, selectedIcon: Icons.event_seat),
    (icon: Icons.poll_outlined, selectedIcon: Icons.poll),
    (icon: Icons.groups_outlined, selectedIcon: Icons.groups),
    (icon: Icons.hub_outlined, selectedIcon: Icons.hub),
    (icon: Icons.newspaper_outlined, selectedIcon: Icons.newspaper),
    (icon: Icons.info_outline, selectedIcon: Icons.info),
    (icon: Icons.settings_outlined, selectedIcon: Icons.settings),
  ];

  List<String> _labels(AppLocalizations l10n) => [
        l10n.navDashboard,
        l10n.navForecast,
        l10n.navParliament,
        l10n.navPolls,
        l10n.navParties,
        l10n.navCoalitionLab,
        l10n.navNews,
        l10n.navMethodology,
        l10n.navSettings,
      ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    final labels = _labels(context.l10n);

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (i) => navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex),
              labelType: NavigationRailLabelType.all,
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Icon(Icons.how_to_vote, size: 32),
              ),
              destinations: [
                for (var i = 0; i < _icons.length; i++)
                  NavigationRailDestination(
                    icon: Icon(_icons[i].icon),
                    selectedIcon: Icon(_icons[i].selectedIcon),
                    label: Text(labels[i]),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (i) => navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex),
        destinations: [
          // Phone bottom bar keeps to 5 primary items; the rest are
          // reachable from the desktop rail / a future "more" sheet.
          for (var i = 0; i < 5; i++)
            NavigationDestination(icon: Icon(_icons[i].icon), selectedIcon: Icon(_icons[i].selectedIcon), label: labels[i]),
        ],
      ),
    );
  }
}
