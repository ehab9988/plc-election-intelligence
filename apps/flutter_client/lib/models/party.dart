/// Party / electoral list / person / candidate DTOs. Registration status is
/// always carried alongside the entity (section 5) so the UI can never
/// silently present "considering" as "officially approved".
class Party {
  final String id;
  final String nameAr;
  final String nameEn;
  final String? abbreviation;
  final String? logoUrl;
  final String? descriptionAr;
  final String? descriptionEn;
  final String registrationStatus;
  final DateTime? registrationStatusVerifiedAt;
  final String verificationConfidence;

  const Party({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.registrationStatus,
    required this.verificationConfidence,
    this.abbreviation,
    this.logoUrl,
    this.descriptionAr,
    this.descriptionEn,
    this.registrationStatusVerifiedAt,
  });

  factory Party.fromJson(Map<String, dynamic> json) => Party(
        id: json['id'] as String,
        nameAr: json['name_ar'] as String,
        nameEn: json['name_en'] as String,
        abbreviation: json['abbreviation'] as String?,
        logoUrl: json['logo_url'] as String?,
        descriptionAr: json['description_ar'] as String?,
        descriptionEn: json['description_en'] as String?,
        registrationStatus: json['registration_status'] as String,
        registrationStatusVerifiedAt: json['registration_status_verified_at'] == null
            ? null
            : DateTime.parse(json['registration_status_verified_at'] as String),
        verificationConfidence: json['verification_confidence'] as String,
      );
}

class ElectoralList {
  final String id;
  final String listNameAr;
  final String listNameEn;
  final int? listNumber;
  final String registrationStatus;
  final DateTime? registrationStatusVerifiedAt;
  final String? cecReference;
  final String? colorHex;

  const ElectoralList({
    required this.id,
    required this.listNameAr,
    required this.listNameEn,
    required this.registrationStatus,
    this.listNumber,
    this.registrationStatusVerifiedAt,
    this.cecReference,
    this.colorHex,
  });

  factory ElectoralList.fromJson(Map<String, dynamic> json) => ElectoralList(
        id: json['id'] as String,
        listNameAr: json['list_name_ar'] as String,
        listNameEn: json['list_name_en'] as String,
        listNumber: json['list_number'] as int?,
        registrationStatus: json['registration_status'] as String,
        registrationStatusVerifiedAt: json['registration_status_verified_at'] == null
            ? null
            : DateTime.parse(json['registration_status_verified_at'] as String),
        cecReference: json['cec_reference'] as String?,
        colorHex: json['color_hex'] as String?,
      );
}

class Person {
  final String id;
  final String fullNameAr;
  final String fullNameEn;
  final DateTime? dateOfBirth;
  final String? birthplace;
  final String? hometown;
  final String? currentPosition;
  final String? biographyAr;
  final String? biographyEn;
  final String? photoUrl;
  final String verificationConfidence;

  const Person({
    required this.id,
    required this.fullNameAr,
    required this.fullNameEn,
    required this.verificationConfidence,
    this.dateOfBirth,
    this.birthplace,
    this.hometown,
    this.currentPosition,
    this.biographyAr,
    this.biographyEn,
    this.photoUrl,
  });

  factory Person.fromJson(Map<String, dynamic> json) => Person(
        id: json['id'] as String,
        fullNameAr: json['full_name_ar'] as String,
        fullNameEn: json['full_name_en'] as String,
        dateOfBirth: json['date_of_birth'] == null ? null : DateTime.parse(json['date_of_birth'] as String),
        birthplace: json['birthplace'] as String?,
        hometown: json['hometown'] as String?,
        currentPosition: json['current_position'] as String?,
        biographyAr: json['biography_ar'] as String?,
        biographyEn: json['biography_en'] as String?,
        photoUrl: json['photo_url'] as String?,
        verificationConfidence: json['verification_confidence'] as String,
      );
}

class Candidate {
  final String id;
  final String personId;
  final String electoralListId;
  final int listRank;
  final String candidateStatus;
  final bool isReservedSeatCandidate;

  const Candidate({
    required this.id,
    required this.personId,
    required this.electoralListId,
    required this.listRank,
    required this.candidateStatus,
    required this.isReservedSeatCandidate,
  });

  factory Candidate.fromJson(Map<String, dynamic> json) => Candidate(
        id: json['id'] as String,
        personId: json['person_id'] as String,
        electoralListId: json['electoral_list_id'] as String,
        listRank: json['list_rank'] as int,
        candidateStatus: json['candidate_status'] as String,
        isReservedSeatCandidate: json['is_reserved_seat_candidate'] as bool? ?? false,
      );
}

class CandidateDetail {
  final Candidate candidate;
  final Person person;
  final ElectoralList electoralList;
  final double? seatProbability;
  final int? seatsMedian;
  final int? seatsLow80;
  final int? seatsHigh80;

  const CandidateDetail({
    required this.candidate,
    required this.person,
    required this.electoralList,
    this.seatProbability,
    this.seatsMedian,
    this.seatsLow80,
    this.seatsHigh80,
  });

  factory CandidateDetail.fromJson(Map<String, dynamic> json) => CandidateDetail(
        candidate: Candidate.fromJson(json['candidate'] as Map<String, dynamic>),
        person: Person.fromJson(json['person'] as Map<String, dynamic>),
        electoralList: ElectoralList.fromJson(json['electoral_list'] as Map<String, dynamic>),
        seatProbability: (json['seat_probability'] as num?)?.toDouble(),
        seatsMedian: json['projected_party_seats_median'] as int?,
        seatsLow80: json['seats_low80'] as int?,
        seatsHigh80: json['seats_high80'] as int?,
      );
}
