import '../core/api_client.dart';
import '../core/app_config.dart';
import '../core/static_data_client.dart';
import '../models/party.dart';
import 'remote_fetch.dart';

class PartyRepository with RemoteFetch {
  @override
  final ApiClient client;
  @override
  final StaticDataClient staticClient;
  @override
  final DataSource dataSource;

  PartyRepository(this.client, this.staticClient, {required this.dataSource});

  Future<List<Party>> listParties({String? query}) async {
    // The static snapshot has no server to filter on, so it always fetches
    // the full list and filters locally; the live API filters server-side.
    if (dataSource == DataSource.staticGithub) {
      final data = await staticClient.getJson('parties');
      final all = (data as List<dynamic>).map((e) => Party.fromJson(e as Map<String, dynamic>)).toList();
      return _filterParties(all, query);
    }
    final res = await client.dio.get('/parties', queryParameters: {'q': ?query});
    return (res.data as List<dynamic>).map((e) => Party.fromJson(e as Map<String, dynamic>)).toList();
  }

  List<Party> _filterParties(List<Party> all, String? query) {
    if (query == null || query.isEmpty) return all;
    final q = query.toLowerCase();
    return all
        .where((p) =>
            p.nameEn.toLowerCase().contains(q) ||
            p.nameAr.contains(query) ||
            (p.abbreviation?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  Future<List<ElectoralList>> listElectoralLists(String electionId) async {
    final data = await fetch(
      '/electoral-lists',
      'electoral_lists',
      query: {'election_id': electionId},
    );
    return (data as List<dynamic>).map((e) => ElectoralList.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Candidate>> listCandidates(String electoralListId) async {
    final data = await fetch(
      '/candidates',
      'candidates/by-list/$electoralListId',
      query: {'electoral_list_id': electoralListId},
    );
    return (data as List<dynamic>).map((e) => Candidate.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<CandidateDetail> getCandidate(String candidateId) async {
    final data = await fetch('/candidates/$candidateId', 'candidates/$candidateId');
    return CandidateDetail.fromJson(data as Map<String, dynamic>);
  }
}
