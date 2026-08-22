import '../core/api_client.dart';
import '../models/party.dart';
import 'fixtures/demo_fixture.dart' as fixture;

class PartyRepository {
  final ApiClient _client;
  final bool demoMode;

  PartyRepository(this._client, {required this.demoMode});

  Future<List<Party>> listParties({String? query}) async {
    if (demoMode) {
      final all = fixture.demoParties.map(Party.fromJson).toList();
      if (query == null || query.isEmpty) return all;
      final q = query.toLowerCase();
      return all
          .where((p) =>
              p.nameEn.toLowerCase().contains(q) ||
              p.nameAr.contains(query) ||
              (p.abbreviation?.toLowerCase().contains(q) ?? false))
          .toList();
    }
    try {
      final res = await _client.dio.get('/parties', queryParameters: {'q': ?query});
      return (res.data as List<dynamic>).map((e) => Party.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return fixture.demoParties.map(Party.fromJson).toList();
    }
  }

  Future<List<ElectoralList>> listElectoralLists() async {
    if (demoMode) return fixture.demoElectoralLists.map(ElectoralList.fromJson).toList();
    // NOTE: the vertical-slice API does not yet expose a standalone
    // /electoral-lists endpoint; lists are currently reachable via
    // forecast results. Fall back to demo data until that endpoint ships.
    return fixture.demoElectoralLists.map(ElectoralList.fromJson).toList();
  }

  Future<List<Candidate>> listCandidates(String electoralListId) async {
    if (demoMode) return const [];
    try {
      final res = await _client.dio.get('/candidates', queryParameters: {'electoral_list_id': electoralListId});
      return (res.data as List<dynamic>).map((e) => Candidate.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<CandidateDetail?> getCandidate(String candidateId) async {
    if (demoMode) return null;
    try {
      final res = await _client.dio.get('/candidates/$candidateId');
      return CandidateDetail.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
