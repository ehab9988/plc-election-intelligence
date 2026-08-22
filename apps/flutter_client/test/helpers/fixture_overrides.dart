import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plc_election_client/models/coalition.dart';
import 'package:plc_election_client/models/election.dart';
import 'package:plc_election_client/models/forecast.dart';
import 'package:plc_election_client/models/news.dart';
import 'package:plc_election_client/models/party.dart';
import 'package:plc_election_client/models/poll.dart';
import 'package:plc_election_client/providers/app_providers.dart';

import '../fixtures/demo_fixture.dart' as fixture;

/// Overrides the screen-facing data providers directly with the offline
/// test fixture, so widget tests render deterministic data without
/// touching the network (there is no "demo mode" in the shipped app to
/// fall back on — see docs/STATIC_GITHUB_DEPLOYMENT.md).
List<Override> fixtureProviderOverrides() => [
      currentElectionProvider.overrideWith((ref) async => Election.fromJson(fixture.demoElection)),
      electionRulesProvider.overrideWith((ref) async => ElectionRuleSetSummary.fromJson(fixture.demoRuleSet)),
      latestForecastProvider.overrideWith((ref) async => ForecastRun.fromJson(fixture.demoForecastRun)),
      timelineProvider.overrideWith((ref) async => fixture.demoTimeline.map(TimelineEvent.fromJson).toList()),
      pollsProvider.overrideWith((ref) async => [Poll.fromJson(fixture.demoPoll)]),
      pollingAverageProvider.overrideWith(
        (ref) async => fixture.demoPollingAverage.map(PollingAveragePoint.fromJson).toList(),
      ),
      partiesProvider.overrideWith((ref) async => fixture.demoParties.map(Party.fromJson).toList()),
      electoralListsProvider.overrideWith(
        (ref) async => fixture.demoElectoralLists.map(ElectoralList.fromJson).toList(),
      ),
      coalitionEvidenceProvider.overrideWith(
        (ref) async => fixture.demoCoalitionEvidence.map(CoalitionEvidence.fromJson).toList(),
      ),
      coalitionFormationEstimatesProvider.overrideWith((ref) async => const <CoalitionFormationEstimate>[]),
      newsProvider.overrideWith((ref) async => fixture.demoNews.map(NewsArticle.fromJson).toList()),
    ];
