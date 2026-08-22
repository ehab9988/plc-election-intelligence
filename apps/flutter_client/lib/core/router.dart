import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/candidates/candidate_detail_screen.dart';
import '../features/coalition_lab/coalition_lab_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/forecast/forecast_screen.dart';
import '../features/methodology/methodology_screen.dart';
import '../features/news/news_screen.dart';
import '../features/parliament/parliament_screen.dart';
import '../features/parties/party_detail_screen.dart';
import '../features/parties/parties_screen.dart';
import '../features/polls/polls_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/splash/splash_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/forecast', builder: (context, state) => const ForecastScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/parliament', builder: (context, state) => const ParliamentScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/polls', builder: (context, state) => const PollsScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/parties',
            builder: (context, state) => const PartiesScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => PartyDetailScreen(partyId: state.pathParameters['id']!),
              ),
            ],
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/coalition-lab', builder: (context, state) => const CoalitionLabScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/news', builder: (context, state) => const NewsScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/methodology', builder: (context, state) => const MethodologyScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
        ]),
      ],
    ),
    GoRoute(
      path: '/candidates/:id',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => CandidateDetailScreen(candidateId: state.pathParameters['id']!),
    ),
  ],
);
