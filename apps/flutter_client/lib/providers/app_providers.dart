import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/app_config.dart';
import '../data/coalition_repository.dart';
import '../data/election_repository.dart';
import '../data/forecast_repository.dart';
import '../data/news_repository.dart';
import '../data/party_repository.dart';
import '../data/poll_repository.dart';
import '../models/election.dart';
import '../models/forecast.dart';

final appConfigProvider = FutureProvider<AppConfig>((ref) => AppConfig.load());

final apiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(appConfigProvider).valueOrNull ?? const AppConfig(
    apiBaseUrl: AppConfig.defaultApiBaseUrl,
    demoMode: true,
  );
  return ApiClient(config);
});

final electionRepositoryProvider = Provider<ElectionRepository>((ref) {
  final config = ref.watch(appConfigProvider).valueOrNull;
  return ElectionRepository(ref.watch(apiClientProvider), demoMode: config?.demoMode ?? true);
});

final forecastRepositoryProvider = Provider<ForecastRepository>((ref) {
  final config = ref.watch(appConfigProvider).valueOrNull;
  return ForecastRepository(ref.watch(apiClientProvider), demoMode: config?.demoMode ?? true);
});

final partyRepositoryProvider = Provider<PartyRepository>((ref) {
  final config = ref.watch(appConfigProvider).valueOrNull;
  return PartyRepository(ref.watch(apiClientProvider), demoMode: config?.demoMode ?? true);
});

final pollRepositoryProvider = Provider<PollRepository>((ref) {
  final config = ref.watch(appConfigProvider).valueOrNull;
  return PollRepository(ref.watch(apiClientProvider), demoMode: config?.demoMode ?? true);
});

final coalitionRepositoryProvider = Provider<CoalitionRepository>((ref) {
  final config = ref.watch(appConfigProvider).valueOrNull;
  return CoalitionRepository(ref.watch(apiClientProvider), demoMode: config?.demoMode ?? true);
});

final newsRepositoryProvider = Provider<NewsRepository>((ref) {
  final config = ref.watch(appConfigProvider).valueOrNull;
  return NewsRepository(ref.watch(apiClientProvider), demoMode: config?.demoMode ?? true);
});

final currentElectionProvider = FutureProvider<Election>((ref) async {
  await ref.watch(appConfigProvider.future);
  return ref.watch(electionRepositoryProvider).getCurrentElection();
});

final electionRulesProvider = FutureProvider<ElectionRuleSetSummary>((ref) async {
  final election = await ref.watch(currentElectionProvider.future);
  return ref.watch(electionRepositoryProvider).getRules(election.id);
});

final latestForecastProvider = FutureProvider<ForecastRun>((ref) async {
  final election = await ref.watch(currentElectionProvider.future);
  return ref.watch(forecastRepositoryProvider).getLatest(election.id);
});

final timelineProvider = FutureProvider((ref) async {
  final election = await ref.watch(currentElectionProvider.future);
  return ref.watch(electionRepositoryProvider).getTimeline(election.id);
});

final pollsProvider = FutureProvider((ref) async {
  final election = await ref.watch(currentElectionProvider.future);
  return ref.watch(pollRepositoryProvider).listPolls(election.id);
});

final pollingAverageProvider = FutureProvider((ref) async {
  final election = await ref.watch(currentElectionProvider.future);
  return ref.watch(pollRepositoryProvider).getPollingAverage(election.id);
});

final partiesProvider = FutureProvider((ref) => ref.watch(partyRepositoryProvider).listParties());

final electoralListsProvider = FutureProvider((ref) => ref.watch(partyRepositoryProvider).listElectoralLists());

final coalitionEvidenceProvider = FutureProvider((ref) => ref.watch(coalitionRepositoryProvider).listEvidence());

final newsProvider = FutureProvider((ref) => ref.watch(newsRepositoryProvider).listNews());
