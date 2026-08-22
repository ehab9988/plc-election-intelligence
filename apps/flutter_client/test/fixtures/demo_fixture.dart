/// Offline test fixture data — used ONLY by the widget test suite (via
/// Riverpod provider overrides) so tests run deterministically without a
/// network. This is not shipped in the app; there is no user-facing "demo
/// mode" (see docs/STATIC_GITHUB_DEPLOYMENT.md for how the app actually
/// gets data with no server: a static GitHub-hosted JSON snapshot, or a
/// live API). Mirrors exactly what scripts/seed_data.py writes to a real
/// database from the August 2026 PCPSR test fixture (spec section 51).
/// These are TEST/SEED numbers only — see docs/POLLING_METHOD.md.
///
/// Two different confidence levels live in this one file, and they must
/// not be confused:
///   - The poll topline (Fatah 32% / Hamas 29%, fieldwork Aug 5-8, 2026)
///     is independently corroborated: a live web search on 2026-08-22
///     confirmed PCPSR Poll No. 97 reported these exact figures, plus a
///     genuine Gaza-specific breakdown (Hamas 34% vs Fatah 30%) that this
///     fixture does NOT yet encode as a PollGeographicResult — a real gap,
///     not an omission to hide.
///   - The seat/vote-share FORECAST numbers below (seats_median, 80%
///     ranges, probabilities) are ILLUSTRATIVE — a hand-computed
///     approximation, not the output of an actual Monte Carlo run against
///     this poll. Never present them as a real prediction.
///   - demoCoalitionEvidence and the Al Jazeera article in demoNews ARE
///     real, current reporting (retrieved 2026-08-22), not fabricated —
///     see the citation on each entry.
library;

const electionId = 'demo-election-2026';
const forecastRunId = 'demo-forecast-run-1';
const fatahListId = 'demo-list-fatah';
const hamasListId = 'demo-list-hamas';
const thirdWayListId = 'demo-list-third-way';

final Map<String, dynamic> demoElection = {
  'id': electionId,
  'name_ar': 'انتخابات المجلس التشريعي الفلسطيني 2026',
  'name_en': '2026 Palestinian Legislative Council Election',
  'election_type': 'legislative',
  'scheduled_date': '2026-11-28',
  'is_current': true,
  'status': 'scheduled',
};

final Map<String, dynamic> demoRuleSet = {
  'id': 'demo-ruleset-1',
  'version': '1.0.0',
  'effective_from': '2026-01-01T00:00:00Z',
  'effective_until': null,
  'electoral_system': 'Nationwide closed-list proportional representation',
  'district_structure': 'Single national constituency',
  'total_seats': 132,
  'threshold_fraction': 0.01,
  'allocation_method': 'sainte_lague',
  'minimum_candidate_age': 23,
  'allows_individual_candidate_votes': false,
  'source_document':
      'Palestinian Central Elections Commission / Palestinian election law — baseline captured August 2026',
  'verified_at': '2026-08-01T00:00:00Z',
};

final List<Map<String, dynamic>> demoTimeline = [
  {
    'id': 'demo-timeline-1',
    'milestone': 'election_day',
    'label_ar': 'يوم الانتخابات',
    'label_en': 'Election Day',
    'starts_at': '2026-11-28T00:00:00Z',
    'ends_at': '2026-11-28T00:00:00Z',
  },
];

final List<Map<String, dynamic>> demoElectoralLists = [
  {
    'id': fatahListId,
    'list_name_ar': 'قائمة فتح',
    'list_name_en': 'Fatah List',
    'list_number': null,
    'registration_status': 'announced_intention',
    'registration_status_verified_at': '2026-08-15T00:00:00Z',
    'cec_reference': null,
    'color_hex': '#FDB913',
  },
  {
    'id': hamasListId,
    'list_name_ar': 'قائمة التغيير والإصلاح',
    'list_name_en': 'Change and Reform List',
    'list_number': null,
    'registration_status': 'announced_intention',
    'registration_status_verified_at': '2026-08-15T00:00:00Z',
    'cec_reference': null,
    'color_hex': '#00843D',
  },
  {
    'id': thirdWayListId,
    'list_name_ar': 'قائمة الطريق الثالث',
    'list_name_en': 'Third Way List',
    'list_number': null,
    'registration_status': 'considering',
    'registration_status_verified_at': '2026-08-15T00:00:00Z',
    'cec_reference': null,
    'color_hex': '#4472C4',
  },
];

final List<Map<String, dynamic>> demoParties = [
  {
    'id': 'demo-party-fatah',
    'name_ar': 'حركة فتح',
    'name_en': 'Fatah Movement',
    'abbreviation': 'Fatah',
    'logo_url': null,
    'description_ar': null,
    'description_en': null,
    'registration_status': 'announced_intention',
    'registration_status_verified_at': '2026-08-15T00:00:00Z',
    'verification_confidence': 'medium',
  },
  {
    'id': 'demo-party-hamas',
    'name_ar': 'حركة المقاومة الإسلامية - حماس',
    'name_en': 'Islamic Resistance Movement (Hamas)',
    'abbreviation': 'Hamas',
    'logo_url': null,
    'description_ar': null,
    'description_en': null,
    'registration_status': 'announced_intention',
    'registration_status_verified_at': '2026-08-15T00:00:00Z',
    'verification_confidence': 'medium',
  },
  {
    'id': 'demo-party-third-way',
    'name_ar': 'الطريق الثالث',
    'name_en': 'Third Way',
    'abbreviation': 'TW',
    'logo_url': null,
    'description_ar': null,
    'description_en': null,
    'registration_status': 'considering',
    'registration_status_verified_at': '2026-08-15T00:00:00Z',
    'verification_confidence': 'low',
  },
  // The five entries below reflect real, sourced Aug 19, 2026 reporting
  // on alliance talks (see demoCoalitionEvidence) — registration_status
  // is 'considering' because no list has been formally submitted to the
  // CEC yet, only alliance exploration reported in the press.
  {
    'id': 'demo-party-pij',
    'name_ar': 'حركة الجهاد الإسلامي في فلسطين',
    'name_en': 'Palestinian Islamic Jihad',
    'abbreviation': 'PIJ',
    'logo_url': null,
    'description_ar': null,
    'description_en': null,
    'registration_status': 'considering',
    'registration_status_verified_at': '2026-08-19T00:00:00Z',
    'verification_confidence': 'medium',
  },
  {
    'id': 'demo-party-pflp',
    'name_ar': 'الجبهة الشعبية لتحرير فلسطين',
    'name_en': 'Popular Front for the Liberation of Palestine',
    'abbreviation': 'PFLP',
    'logo_url': null,
    'description_ar': null,
    'description_en': null,
    'registration_status': 'considering',
    'registration_status_verified_at': '2026-08-19T00:00:00Z',
    'verification_confidence': 'medium',
  },
  {
    'id': 'demo-party-national-initiative',
    'name_ar': 'المبادرة الوطنية الفلسطينية',
    'name_en': 'National Initiative',
    'abbreviation': 'Al-Mubadara',
    'logo_url': null,
    'description_ar': null,
    'description_en': null,
    'registration_status': 'considering',
    'registration_status_verified_at': '2026-08-19T00:00:00Z',
    'verification_confidence': 'medium',
  },
  {
    'id': 'demo-party-democratic-reform',
    'name_ar': 'تيار الإصلاح الديمقراطي',
    'name_en': 'Democratic Reform',
    'abbreviation': 'Dahlan faction',
    'logo_url': null,
    'description_ar': null,
    'description_en': 'Breakaway Fatah faction led by Mohammed Dahlan; local leader Osama al-Farra.',
    'registration_status': 'considering',
    'registration_status_verified_at': '2026-08-19T00:00:00Z',
    'verification_confidence': 'medium',
  },
];

/// PCPSR fieldwork Aug 5-8, 2026 (spec section 51 fixture): Fatah 32,
/// Hamas 29, third parties combined 18, undecided 21.
final Map<String, dynamic> demoPoll = {
  'id': 'demo-poll-pcpsr-aug-2026',
  'pollster_id': 'demo-pollster-pcpsr',
  'sponsor': null,
  'publication_date': '2026-08-10',
  'fieldwork_start': '2026-08-05',
  'fieldwork_end': '2026-08-08',
  'sample_size': 1270,
  'margin_of_error': 3.0,
  'mode': 'face_to_face',
  'geographic_population': 'West Bank and Gaza Strip',
  'west_bank_sample_size': null,
  'gaza_sample_size': null,
  'population': 'likely_voters',
  'manually_verified': true,
  'questions': [
    {
      'id': 'demo-question-1',
      'question_text_ar': 'لو أجريت الانتخابات التشريعية اليوم لمن كنت تعطي صوتك؟',
      'question_text_en': 'If legislative elections were held today, which list would you vote for?',
      'question_type': 'vote_choice_if_today',
      'results': [
        {'label': 'Fatah List', 'electoral_list_id': fatahListId, 'raw_response_pct': 32.0, 'normalized_pct': 32.0},
        {'label': 'Change and Reform List', 'electoral_list_id': hamasListId, 'raw_response_pct': 29.0, 'normalized_pct': 29.0},
        {'label': 'Third Way List', 'electoral_list_id': thirdWayListId, 'raw_response_pct': 18.0, 'normalized_pct': 18.0},
        {'label': 'undecided', 'electoral_list_id': null, 'raw_response_pct': 21.0, 'normalized_pct': 21.0},
      ],
    },
  ],
};

final List<Map<String, dynamic>> demoPollingAverage = [
  {
    'electoral_list_id': fatahListId,
    'list_name_en': 'Fatah List',
    'weighted_average_pct': 32.0,
    'trend_low': 30.0,
    'trend_high': 34.0,
    'n_polls_used': 1,
    'most_recent_fieldwork_end': '2026-08-08',
  },
  {
    'electoral_list_id': hamasListId,
    'list_name_en': 'Change and Reform List',
    'weighted_average_pct': 29.0,
    'trend_low': 27.0,
    'trend_high': 31.0,
    'n_polls_used': 1,
    'most_recent_fieldwork_end': '2026-08-08',
  },
  {
    'electoral_list_id': thirdWayListId,
    'list_name_en': 'Third Way List',
    'weighted_average_pct': 18.0,
    'trend_low': 16.0,
    'trend_high': 20.0,
    'n_polls_used': 1,
    'most_recent_fieldwork_end': '2026-08-08',
  },
];

/// Illustrative Monte Carlo summary consistent with the poll above,
/// undecided (21%) allocated proportionally, seats via Sainte-Lague over
/// 132 seats. ILLUSTRATIVE PLACEHOLDER, not a claim about the real
/// election — see spec section 82 "Sample dashboard presentation".
final Map<String, dynamic> demoForecastRun = {
  'id': forecastRunId,
  'election_id': electionId,
  'model_version': 'forecast-model-0.1.0',
  'dataset_version': 'polls-as-of-2026-08-22',
  'data_cutoff_at': '2026-08-22T12:00:00Z',
  'simulations_performed': 20000,
  'random_seed': 20260822,
  'status': 'published',
  'assumptions_notes':
      'Undecided voters allocated proportionally. House effects and turnout modeled as independent Gaussian noise.',
  'change_summary': 'Initial seeded forecast from the August 2026 PCPSR fixture.',
  'published_at': '2026-08-22T12:05:00Z',
  'created_at': '2026-08-22T12:00:00Z',
  'majority_threshold': 67,
  'party_results': [
    {
      'electoral_list_id': fatahListId,
      'list_name_ar': 'قائمة فتح',
      'list_name_en': 'Fatah List',
      'color_hex': '#FDB913',
      'polling_average_pct': 32.0,
      'forecast_vote_share_median': 40.5,
      'vote_share_low80': 36.8,
      'vote_share_high80': 44.1,
      'vote_share_low95': 34.0,
      'vote_share_high95': 47.0,
      'seats_median': 54,
      'seats_mean': 53.6,
      'seats_low50': 51,
      'seats_high50': 57,
      'seats_low80': 47,
      'seats_high80': 61,
      'seats_low95': 42,
      'seats_high95': 66,
      'probability_largest_list': 0.63,
      'probability_cross_threshold': 1.0,
      'probability_majority_alone': 0.03,
    },
    {
      'electoral_list_id': hamasListId,
      'list_name_ar': 'قائمة التغيير والإصلاح',
      'list_name_en': 'Change and Reform List',
      'color_hex': '#00843D',
      'polling_average_pct': 29.0,
      'forecast_vote_share_median': 36.7,
      'vote_share_low80': 33.1,
      'vote_share_high80': 40.3,
      'vote_share_low95': 30.4,
      'vote_share_high95': 43.1,
      'seats_median': 48,
      'seats_mean': 47.9,
      'seats_low50': 45,
      'seats_high50': 51,
      'seats_low80': 41,
      'seats_high80': 55,
      'seats_low95': 37,
      'seats_high95': 59,
      'probability_largest_list': 0.36,
      'probability_cross_threshold': 1.0,
      'probability_majority_alone': 0.01,
    },
    {
      'electoral_list_id': thirdWayListId,
      'list_name_ar': 'قائمة الطريق الثالث',
      'list_name_en': 'Third Way List',
      'color_hex': '#4472C4',
      'polling_average_pct': 18.0,
      'forecast_vote_share_median': 22.8,
      'vote_share_low80': 19.6,
      'vote_share_high80': 26.0,
      'vote_share_low95': 17.2,
      'vote_share_high95': 28.9,
      'seats_median': 30,
      'seats_mean': 30.1,
      'seats_low50': 27,
      'seats_high50': 33,
      'seats_low80': 23,
      'seats_high80': 37,
      'seats_low95': 19,
      'seats_high95': 41,
      'probability_largest_list': 0.01,
      'probability_cross_threshold': 1.0,
      'probability_majority_alone': 0.0,
    },
  ],
};

// Coalition evidence sourced from Al Jazeera's Aug 19, 2026 report
// "Palestinian factions explore broad alliance for November elections"
// (https://www.aljazeera.com/news/2026/8/19/palestinian-factions-explore-broad-alliance-for-november-elections),
// retrieved via web search on 2026-08-22 — NOT fabricated. Direct quotes
// are attributed to the named officials the article quotes. This is a
// real, current news event, unlike the illustrative seat/vote-share
// numbers elsewhere in this fixture — see the module doc comment.
const _aljazeeraSourceId = 'demo-source-aljazeera-2026-08-19';

final List<Map<String, dynamic>> demoCoalitionEvidence = [
  {
    'id': 'demo-evidence-fatah-hamas',
    'party_a_id': 'demo-party-fatah',
    'party_b_id': 'demo-party-hamas',
    'evidence_type': 'conflicting',
    'statement_summary':
        'Fatah spokesperson Munther al-Hayek: "organisational bases of the Fatah movement refuse to '
        'participate with Hamas in a single list while the door remains open to alliances with the rest '
        'of the factions." (Al Jazeera, Aug 19, 2026)',
    'source_id': _aljazeeraSourceId,
    'confidence': 'high',
  },
  {
    'id': 'demo-evidence-hamas-pij',
    'party_a_id': 'demo-party-hamas',
    'party_b_id': 'demo-party-pij',
    'evidence_type': 'supporting',
    'statement_summary':
        'Hamas held meetings with Palestinian Islamic Jihad on forming a broad electoral alliance. '
        'Hamas official Husam Badran: "We do not need permission or a guarantee from any party to '
        'participate in the Palestinian elections." (Al Jazeera, Aug 19, 2026)',
    'source_id': _aljazeeraSourceId,
    'confidence': 'medium',
  },
  {
    'id': 'demo-evidence-hamas-pflp',
    'party_a_id': 'demo-party-hamas',
    'party_b_id': 'demo-party-pflp',
    'evidence_type': 'supporting',
    'statement_summary': 'Hamas held meetings with the Popular Front for the Liberation of Palestine (PFLP) '
        'on forming a broad electoral alliance. (Al Jazeera, Aug 19, 2026)',
    'source_id': _aljazeeraSourceId,
    'confidence': 'medium',
  },
  {
    'id': 'demo-evidence-hamas-national-initiative',
    'party_a_id': 'demo-party-hamas',
    'party_b_id': 'demo-party-national-initiative',
    'evidence_type': 'supporting',
    'statement_summary': 'Hamas held meetings with the National Initiative on forming a broad electoral '
        'alliance. (Al Jazeera, Aug 19, 2026)',
    'source_id': _aljazeeraSourceId,
    'confidence': 'medium',
  },
  {
    'id': 'demo-evidence-hamas-democratic-reform',
    'party_a_id': 'demo-party-hamas',
    'party_b_id': 'demo-party-democratic-reform',
    'evidence_type': 'supporting',
    'statement_summary': 'Democratic Reform leader Osama al-Farra confirmed the Mohammed Dahlan-led faction '
        'decided to participate, favoring a "broad national alliance" comprising factions, professionals, '
        'and community figures. (Al Jazeera, Aug 19, 2026)',
    'source_id': _aljazeeraSourceId,
    'confidence': 'medium',
  },
];

final List<Map<String, dynamic>> demoNews = [
  {
    'id': 'demo-article-aljazeera-alliance',
    'news_source_id': 'demo-news-source-aljazeera',
    'headline': 'Palestinian factions explore broad alliance for November elections',
    'author': null,
    'published_at': '2026-08-19T00:00:00Z',
    'canonical_url':
        'https://www.aljazeera.com/news/2026/8/19/palestinian-factions-explore-broad-alliance-for-november-elections',
    'permitted_snippet': 'Hamas has held bilateral and collective meetings with Palestinian Islamic Jihad, '
        'the PFLP, the National Initiative, and the Mohammed Dahlan-led Democratic Reform faction on a '
        'possible joint list. Fatah says it will not run on a single list with Hamas but remains open to '
        'alliances with other factions.',
    'image_url': null,
    'language': 'en',
    'importance_score': 0.91,
  },
  {
    'id': 'demo-article-1',
    'news_source_id': 'demo-news-source-1',
    'headline': 'CEC publishes provisional candidate-list submission timeline',
    'author': null,
    'published_at': '2026-08-18T09:00:00Z',
    'canonical_url': 'https://www.elections.ps/',
    'permitted_snippet': 'The Central Elections Commission announced key dates for list submission ahead of the November 28 vote.',
    'image_url': null,
    'language': 'en',
    'importance_score': 0.82,
  },
];
