import 'package:collection/collection.dart';

enum TournamentStage {
  group,
  roundOf32,
  roundOf16,
  quarterfinal,
  semifinal,
  thirdPlace,
  finalMatch,
}

enum FixtureStatus { scheduled, live, finished, postponed }

enum BracketStatus { draft, submitted, locked }

enum AuthProviderLink { email, google, apple }

enum ReportTargetType { user, bracket }

enum ReportStatus { open, reviewed, dismissed }

enum NotificationKind { lockReminder, leaderboardUpdate }

class Country {
  const Country({
    required this.id,
    required this.apiFootballTeamId,
    required this.name,
    required this.abbreviation,
    required this.flagUrl,
    required this.fallbackAssetKey,
    this.isActive = true,
  });

  final String id;
  final int apiFootballTeamId;
  final String name;
  final String abbreviation;
  final String flagUrl;
  final String fallbackAssetKey;
  final bool isActive;

  factory Country.fromMap(String id, Map<String, Object?> map) {
    return Country(
      id: id,
      apiFootballTeamId: (map['apiFootballTeamId'] as num?)?.toInt() ?? 0,
      name: map['name'] as String? ?? '',
      abbreviation: map['abbreviation'] as String? ?? '',
      flagUrl: map['flagUrl'] as String? ?? '',
      fallbackAssetKey: map['fallbackAssetKey'] as String? ?? '',
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  Map<String, Object?> toMap() => {
    'apiFootballTeamId': apiFootballTeamId,
    'name': name,
    'abbreviation': abbreviation,
    'flagUrl': flagUrl,
    'fallbackAssetKey': fallbackAssetKey,
    'isActive': isActive,
  };
}

class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    required this.createdAt,
    this.email,
    this.linkedProviders = const {},
    this.isHidden = false,
  });

  final String id;
  final String username;
  final DateTime createdAt;
  final String? email;
  final Set<AuthProviderLink> linkedProviders;
  final bool isHidden;

  factory AppUser.fromMap(String id, Map<String, Object?> map) {
    final providerNames =
        (map['linkedProviders'] as List<dynamic>? ?? const [])
            .whereType<String>();
    return AppUser(
      id: id,
      username: map['username'] as String? ?? '',
      email: map['email'] as String?,
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      linkedProviders:
          providerNames
              .map(
                (name) => AuthProviderLink.values.firstWhereOrNull(
                  (provider) => provider.name == name,
                ),
              )
              .whereType<AuthProviderLink>()
              .toSet(),
      isHidden: map['isHidden'] as bool? ?? false,
    );
  }

  Map<String, Object?> toMap() => {
    'username': username,
    'email': email,
    'createdAt': createdAt.toIso8601String(),
    'linkedProviders':
        linkedProviders.map((provider) => provider.name).toList()..sort(),
    'isHidden': isHidden,
  };
}

class Fixture {
  const Fixture({
    required this.id,
    required this.externalId,
    required this.stage,
    required this.roundLabel,
    required this.kickoff,
    required this.status,
    this.homeCountryId,
    this.awayCountryId,
    this.homeScore,
    this.awayScore,
    this.winnerCountryId,
    this.venueName,
    this.venueCity,
    this.updatedAt,
    this.updatedBy,
  });

  final String id;
  final String externalId;
  final TournamentStage stage;
  final String roundLabel;
  final DateTime kickoff;
  final FixtureStatus status;
  final String? homeCountryId;
  final String? awayCountryId;
  final int? homeScore;
  final int? awayScore;
  final String? winnerCountryId;
  final String? venueName;
  final String? venueCity;
  final DateTime? updatedAt;
  final String? updatedBy;

  String? get venueLabel {
    final name = venueName?.trim();
    final city = venueCity?.trim();
    final hasName = name != null && name.isNotEmpty;
    final hasCity = city != null && city.isNotEmpty;
    if (hasName && hasCity) return '$name, $city';
    if (hasName) return name;
    if (hasCity) return city;
    return null;
  }

  factory Fixture.fromMap(String id, Map<String, Object?> map) {
    return Fixture(
      id: id,
      externalId: map['externalId'] as String? ?? id,
      stage: _enumFromName(
        TournamentStage.values,
        map['stage'] as String?,
        TournamentStage.group,
      ),
      roundLabel: map['roundLabel'] as String? ?? '',
      kickoff:
          DateTime.tryParse(map['kickoff'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      status: _enumFromName(
        FixtureStatus.values,
        map['status'] as String?,
        FixtureStatus.scheduled,
      ),
      homeCountryId: map['homeCountryId'] as String?,
      awayCountryId: map['awayCountryId'] as String?,
      homeScore: (map['homeScore'] as num?)?.toInt(),
      awayScore: (map['awayScore'] as num?)?.toInt(),
      winnerCountryId: map['winnerCountryId'] as String?,
      venueName: map['venueName'] as String?,
      venueCity: map['venueCity'] as String?,
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? ''),
      updatedBy: map['updatedBy'] as String?,
    );
  }

  Map<String, Object?> toMap() => {
    'externalId': externalId,
    'stage': stage.name,
    'roundLabel': roundLabel,
    'kickoff': kickoff.toIso8601String(),
    'status': status.name,
    'homeCountryId': homeCountryId,
    'awayCountryId': awayCountryId,
    'homeScore': homeScore,
    'awayScore': awayScore,
    'winnerCountryId': winnerCountryId,
    'venueName': venueName,
    'venueCity': venueCity,
    'updatedAt': updatedAt?.toIso8601String(),
    'updatedBy': updatedBy,
  };

  Fixture copyWith({
    String? externalId,
    TournamentStage? stage,
    String? roundLabel,
    DateTime? kickoff,
    FixtureStatus? status,
    String? homeCountryId,
    String? awayCountryId,
    int? homeScore,
    int? awayScore,
    String? winnerCountryId,
    String? venueName,
    String? venueCity,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return Fixture(
      id: id,
      externalId: externalId ?? this.externalId,
      stage: stage ?? this.stage,
      roundLabel: roundLabel ?? this.roundLabel,
      kickoff: kickoff ?? this.kickoff,
      status: status ?? this.status,
      homeCountryId: homeCountryId ?? this.homeCountryId,
      awayCountryId: awayCountryId ?? this.awayCountryId,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      winnerCountryId: winnerCountryId ?? this.winnerCountryId,
      venueName: venueName ?? this.venueName,
      venueCity: venueCity ?? this.venueCity,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}

class GroupPick {
  const GroupPick({
    required this.groupId,
    required this.firstCountryId,
    required this.secondCountryId,
    this.thirdCountryId,
  });

  final String groupId;
  final String firstCountryId;
  final String secondCountryId;
  final String? thirdCountryId;

  factory GroupPick.fromMap(Map<String, Object?> map) => GroupPick(
    groupId: map['groupId'] as String? ?? '',
    firstCountryId: map['firstCountryId'] as String? ?? '',
    secondCountryId: map['secondCountryId'] as String? ?? '',
    thirdCountryId: map['thirdCountryId'] as String?,
  );

  Map<String, Object?> toMap() => {
    'groupId': groupId,
    'firstCountryId': firstCountryId,
    'secondCountryId': secondCountryId,
    'thirdCountryId': thirdCountryId,
  };
}

class KnockoutPick {
  const KnockoutPick({
    required this.slotId,
    required this.stage,
    required this.winnerCountryId,
  });

  final String slotId;
  final TournamentStage stage;
  final String winnerCountryId;

  factory KnockoutPick.fromMap(Map<String, Object?> map) => KnockoutPick(
    slotId: map['slotId'] as String? ?? '',
    stage: _enumFromName(
      TournamentStage.values,
      map['stage'] as String?,
      TournamentStage.roundOf32,
    ),
    winnerCountryId: map['winnerCountryId'] as String? ?? '',
  );

  Map<String, Object?> toMap() => {
    'slotId': slotId,
    'stage': stage.name,
    'winnerCountryId': winnerCountryId,
  };
}

class FinalScoreTiebreaker {
  const FinalScoreTiebreaker({
    required this.championScore,
    required this.runnerUpScore,
  });

  final int championScore;
  final int runnerUpScore;

  int distanceFrom(int actualChampionScore, int actualRunnerUpScore) {
    return (championScore - actualChampionScore).abs() +
        (runnerUpScore - actualRunnerUpScore).abs();
  }

  factory FinalScoreTiebreaker.fromMap(Map<String, Object?> map) {
    return FinalScoreTiebreaker(
      championScore: (map['championScore'] as num?)?.toInt() ?? 0,
      runnerUpScore: (map['runnerUpScore'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, Object?> toMap() => {
    'championScore': championScore,
    'runnerUpScore': runnerUpScore,
  };
}

class Bracket {
  const Bracket({
    required this.userId,
    required this.status,
    required this.groupPicks,
    required this.bestThirdGroupIds,
    required this.knockoutPicks,
    required this.finalScoreTiebreaker,
    required this.updatedAt,
    this.submittedAt,
    this.totalScore = 0,
    this.groupScore = 0,
    this.knockoutScore = 0,
    this.tiebreakerDistance = 0,
  });

  final String userId;
  final BracketStatus status;
  final List<GroupPick> groupPicks;
  final List<String> bestThirdGroupIds;
  final List<KnockoutPick> knockoutPicks;
  final FinalScoreTiebreaker finalScoreTiebreaker;
  final DateTime updatedAt;
  final DateTime? submittedAt;
  final int totalScore;
  final int groupScore;
  final int knockoutScore;
  final int tiebreakerDistance;

  bool get isEditable => status != BracketStatus.locked;

  String? get championCountryId {
    return knockoutPicks
        .where((pick) => pick.stage == TournamentStage.finalMatch)
        .map((pick) => pick.winnerCountryId)
        .firstOrNull;
  }

  factory Bracket.empty(String userId) => Bracket(
    userId: userId,
    status: BracketStatus.draft,
    groupPicks: const [],
    bestThirdGroupIds: const [],
    knockoutPicks: const [],
    finalScoreTiebreaker: const FinalScoreTiebreaker(
      championScore: 2,
      runnerUpScore: 1,
    ),
    updatedAt: DateTime.now(),
  );

  factory Bracket.fromMap(String userId, Map<String, Object?> map) {
    return Bracket(
      userId: userId,
      status: _enumFromName(
        BracketStatus.values,
        map['status'] as String?,
        BracketStatus.draft,
      ),
      groupPicks:
          (map['groupPicks'] as List<dynamic>? ?? const [])
              .whereType<Map>()
              .map((item) => GroupPick.fromMap(item.cast<String, Object?>()))
              .toList(),
      bestThirdGroupIds:
          (map['bestThirdGroupIds'] as List<dynamic>? ?? const [])
              .whereType<String>()
              .toList(),
      knockoutPicks:
          (map['knockoutPicks'] as List<dynamic>? ?? const [])
              .whereType<Map>()
              .map((item) => KnockoutPick.fromMap(item.cast<String, Object?>()))
              .toList(),
      finalScoreTiebreaker: FinalScoreTiebreaker.fromMap(
        (map['finalScoreTiebreaker'] as Map<dynamic, dynamic>? ?? const {})
            .cast<String, Object?>(),
      ),
      updatedAt:
          DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      submittedAt: DateTime.tryParse(map['submittedAt'] as String? ?? ''),
      totalScore: (map['totalScore'] as num?)?.toInt() ?? 0,
      groupScore: (map['groupScore'] as num?)?.toInt() ?? 0,
      knockoutScore: (map['knockoutScore'] as num?)?.toInt() ?? 0,
      tiebreakerDistance: (map['tiebreakerDistance'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, Object?> toMap() => {
    'status': status.name,
    'groupPicks': groupPicks.map((pick) => pick.toMap()).toList(),
    'bestThirdGroupIds': bestThirdGroupIds,
    'knockoutPicks': knockoutPicks.map((pick) => pick.toMap()).toList(),
    'finalScoreTiebreaker': finalScoreTiebreaker.toMap(),
    'updatedAt': updatedAt.toIso8601String(),
    'submittedAt': submittedAt?.toIso8601String(),
    'totalScore': totalScore,
    'groupScore': groupScore,
    'knockoutScore': knockoutScore,
    'tiebreakerDistance': tiebreakerDistance,
  };

  Bracket copyWith({
    BracketStatus? status,
    List<GroupPick>? groupPicks,
    List<String>? bestThirdGroupIds,
    List<KnockoutPick>? knockoutPicks,
    FinalScoreTiebreaker? finalScoreTiebreaker,
    DateTime? updatedAt,
    DateTime? submittedAt,
    int? totalScore,
    int? groupScore,
    int? knockoutScore,
    int? tiebreakerDistance,
  }) {
    return Bracket(
      userId: userId,
      status: status ?? this.status,
      groupPicks: groupPicks ?? this.groupPicks,
      bestThirdGroupIds: bestThirdGroupIds ?? this.bestThirdGroupIds,
      knockoutPicks: knockoutPicks ?? this.knockoutPicks,
      finalScoreTiebreaker: finalScoreTiebreaker ?? this.finalScoreTiebreaker,
      updatedAt: updatedAt ?? this.updatedAt,
      submittedAt: submittedAt ?? this.submittedAt,
      totalScore: totalScore ?? this.totalScore,
      groupScore: groupScore ?? this.groupScore,
      knockoutScore: knockoutScore ?? this.knockoutScore,
      tiebreakerDistance: tiebreakerDistance ?? this.tiebreakerDistance,
    );
  }
}

class PublicBracketProfile {
  const PublicBracketProfile({required this.user, required this.bracket});

  final AppUser user;
  final Bracket bracket;
}

class GlobalContestConfig {
  const GlobalContestConfig({
    required this.lockAt,
    this.isAcceptingSubmissions = true,
    this.pointsPerCorrectPick = 1,
    this.updatedAt,
    this.updatedBy,
  });

  final DateTime lockAt;
  final bool isAcceptingSubmissions;
  final int pointsPerCorrectPick;
  final DateTime? updatedAt;
  final String? updatedBy;

  bool get isLocked => DateTime.now().isAfter(lockAt);

  /// True when users can still save and submit brackets.
  bool get areSubmissionsOpen => isAcceptingSubmissions && !isLocked;

  /// True when bracket picks should be read-only in the UI.
  bool get isBracketEditingLocked => !areSubmissionsOpen;

  factory GlobalContestConfig.fromMap(Map<String, Object?> map) {
    return GlobalContestConfig(
      lockAt:
          DateTime.tryParse(map['lockAt'] as String? ?? '') ??
          DateTime(2026, 6, 11),
      isAcceptingSubmissions: map['isAcceptingSubmissions'] as bool? ?? true,
      pointsPerCorrectPick: (map['pointsPerCorrectPick'] as num?)?.toInt() ?? 1,
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? ''),
      updatedBy: map['updatedBy'] as String?,
    );
  }

  Map<String, Object?> toMap() => {
    'lockAt': lockAt.toUtc().toIso8601String(),
    'isAcceptingSubmissions': isAcceptingSubmissions,
    'pointsPerCorrectPick': pointsPerCorrectPick,
    'updatedAt': updatedAt?.toIso8601String(),
    'updatedBy': updatedBy,
  };

  GlobalContestConfig copyWith({
    DateTime? lockAt,
    bool? isAcceptingSubmissions,
    int? pointsPerCorrectPick,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return GlobalContestConfig(
      lockAt: lockAt ?? this.lockAt,
      isAcceptingSubmissions:
          isAcceptingSubmissions ?? this.isAcceptingSubmissions,
      pointsPerCorrectPick: pointsPerCorrectPick ?? this.pointsPerCorrectPick,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.userId,
    required this.username,
    required this.score,
    required this.tiebreakerDistance,
    required this.rank,
    this.groupScore = 0,
    this.knockoutScore = 0,
    this.updatedAt,
  });

  final String userId;
  final String username;
  final int score;
  final int tiebreakerDistance;
  final int rank;
  final int groupScore;
  final int knockoutScore;
  final DateTime? updatedAt;

  factory LeaderboardEntry.fromMap(String userId, Map<String, Object?> map) {
    return LeaderboardEntry(
      userId: userId,
      username: map['username'] as String? ?? '',
      score: (map['score'] as num?)?.toInt() ?? 0,
      tiebreakerDistance: (map['tiebreakerDistance'] as num?)?.toInt() ?? 0,
      rank: (map['rank'] as num?)?.toInt() ?? 0,
      groupScore: (map['groupScore'] as num?)?.toInt() ?? 0,
      knockoutScore: (map['knockoutScore'] as num?)?.toInt() ?? 0,
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? ''),
    );
  }

  Map<String, Object?> toMap() => {
    'username': username,
    'score': score,
    'groupScore': groupScore,
    'knockoutScore': knockoutScore,
    'tiebreakerDistance': tiebreakerDistance,
    'rank': rank,
    'updatedAt': updatedAt?.toIso8601String(),
  };
}

class StandingRow {
  const StandingRow({
    required this.countryId,
    required this.rank,
    required this.played,
    required this.won,
    required this.drawn,
    required this.lost,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.goalDifference,
    required this.points,
    this.form = '',
  });

  final String countryId;
  final int rank;
  final int played;
  final int won;
  final int drawn;
  final int lost;
  final int goalsFor;
  final int goalsAgainst;
  final int goalDifference;
  final int points;
  /// Recent results in chronological order, e.g. `W,D,L` (last five games).
  final String form;

  factory StandingRow.empty(String countryId, int rank) => StandingRow(
    countryId: countryId,
    rank: rank,
    played: 0,
    won: 0,
    drawn: 0,
    lost: 0,
    goalsFor: 0,
    goalsAgainst: 0,
    goalDifference: 0,
    points: 0,
    form: '',
  );

  factory StandingRow.fromMap(Map<String, Object?> map) {
    return StandingRow(
      countryId: map['countryId'] as String? ?? '',
      rank: (map['rank'] as num?)?.toInt() ?? 0,
      played: (map['played'] as num?)?.toInt() ?? 0,
      won: (map['won'] as num?)?.toInt() ?? 0,
      drawn: (map['drawn'] as num?)?.toInt() ?? 0,
      lost: (map['lost'] as num?)?.toInt() ?? 0,
      goalsFor: (map['goalsFor'] as num?)?.toInt() ?? 0,
      goalsAgainst: (map['goalsAgainst'] as num?)?.toInt() ?? 0,
      goalDifference: (map['goalDifference'] as num?)?.toInt() ?? 0,
      points: (map['points'] as num?)?.toInt() ?? 0,
      form: map['form'] as String? ?? '',
    );
  }

  Map<String, Object?> toMap() => {
    'countryId': countryId,
    'rank': rank,
    'played': played,
    'won': won,
    'drawn': drawn,
    'lost': lost,
    'goalsFor': goalsFor,
    'goalsAgainst': goalsAgainst,
    'goalDifference': goalDifference,
    'points': points,
    'form': form,
  };

  StandingRow copyWith({int? rank}) {
    return StandingRow(
      countryId: countryId,
      rank: rank ?? this.rank,
      played: played,
      won: won,
      drawn: drawn,
      lost: lost,
      goalsFor: goalsFor,
      goalsAgainst: goalsAgainst,
      goalDifference: goalDifference,
      points: points,
      form: form,
    );
  }
}

class GroupStanding {
  const GroupStanding({
    required this.groupId,
    required this.rows,
    this.overrideOrderCountryIds = const [],
    this.updatedAt,
    this.updatedBy,
  });

  final String groupId;
  final List<StandingRow> rows;
  final List<String> overrideOrderCountryIds;
  final DateTime? updatedAt;
  final String? updatedBy;

  factory GroupStanding.fromMap(String groupId, Map<String, Object?> map) {
    return GroupStanding(
      groupId: map['groupId'] as String? ?? groupId,
      rows:
          (map['rows'] as List<dynamic>? ?? const [])
              .whereType<Map>()
              .map((item) => StandingRow.fromMap(item.cast<String, Object?>()))
              .toList(),
      overrideOrderCountryIds:
          (map['overrideOrderCountryIds'] as List<dynamic>? ?? const [])
              .whereType<String>()
              .toList(),
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? ''),
      updatedBy: map['updatedBy'] as String?,
    );
  }

  Map<String, Object?> toMap() => {
    'groupId': groupId,
    'rows': rows.map((row) => row.toMap()).toList(),
    'overrideOrderCountryIds': overrideOrderCountryIds,
    'updatedAt': updatedAt?.toIso8601String(),
    'updatedBy': updatedBy,
  };
}

class StandingsRecalculationSummary {
  const StandingsRecalculationSummary({
    required this.groupsUpdated,
    required this.recalculatedAt,
  });

  final int groupsUpdated;
  final DateTime recalculatedAt;
}

class ApiFootballSyncState {
  const ApiFootballSyncState({
    this.lastSyncAt,
    this.lastError,
    this.fixturesUpdated = 0,
    this.skippedAdmin = 0,
    this.skippedUnmatched = 0,
    this.skippedUnchanged = 0,
    this.knockoutResultsUpdated = 0,
    this.apiFixturesReceived = 0,
    this.localFixturesLoaded = 0,
    this.countriesWithApiId = 0,
    this.countriesEnrichedFromApi = 0,
    this.source,
  });

  final DateTime? lastSyncAt;
  final String? lastError;
  final int fixturesUpdated;
  final int skippedAdmin;
  final int skippedUnmatched;
  final int skippedUnchanged;
  final int knockoutResultsUpdated;
  final int apiFixturesReceived;
  final int localFixturesLoaded;
  final int countriesWithApiId;
  final int countriesEnrichedFromApi;
  final String? source;

  factory ApiFootballSyncState.fromMap(Map<String, Object?> map) {
    return ApiFootballSyncState(
      lastSyncAt: _timestampFromDynamic(map['lastSyncAt']),
      lastError: map['lastError'] as String?,
      fixturesUpdated: (map['fixturesUpdated'] as num?)?.toInt() ?? 0,
      skippedAdmin: (map['skippedAdmin'] as num?)?.toInt() ?? 0,
      skippedUnmatched: (map['skippedUnmatched'] as num?)?.toInt() ?? 0,
      skippedUnchanged: (map['skippedUnchanged'] as num?)?.toInt() ?? 0,
      knockoutResultsUpdated:
          (map['knockoutResultsUpdated'] as num?)?.toInt() ?? 0,
      apiFixturesReceived: (map['apiFixturesReceived'] as num?)?.toInt() ?? 0,
      localFixturesLoaded: (map['localFixturesLoaded'] as num?)?.toInt() ?? 0,
      countriesWithApiId: (map['countriesWithApiId'] as num?)?.toInt() ?? 0,
      countriesEnrichedFromApi:
          (map['countriesEnrichedFromApi'] as num?)?.toInt() ?? 0,
      source: map['source'] as String?,
    );
  }
}

class ApiFootballSyncSummary {
  const ApiFootballSyncSummary({
    required this.fixturesUpdated,
    required this.skippedAdmin,
    required this.skippedUnmatched,
    required this.skippedUnchanged,
    required this.knockoutResultsUpdated,
    required this.apiFixturesReceived,
    required this.localFixturesLoaded,
    required this.countriesWithApiId,
    required this.countriesEnrichedFromApi,
    required this.source,
  });

  final int fixturesUpdated;
  final int skippedAdmin;
  final int skippedUnmatched;
  final int skippedUnchanged;
  final int knockoutResultsUpdated;
  final int apiFixturesReceived;
  final int localFixturesLoaded;
  final int countriesWithApiId;
  final int countriesEnrichedFromApi;
  final String source;

  factory ApiFootballSyncSummary.fromMap(Map<String, Object?> map) {
    return ApiFootballSyncSummary(
      fixturesUpdated: (map['fixturesUpdated'] as num?)?.toInt() ?? 0,
      skippedAdmin: (map['skippedAdmin'] as num?)?.toInt() ?? 0,
      skippedUnmatched: (map['skippedUnmatched'] as num?)?.toInt() ?? 0,
      skippedUnchanged: (map['skippedUnchanged'] as num?)?.toInt() ?? 0,
      knockoutResultsUpdated:
          (map['knockoutResultsUpdated'] as num?)?.toInt() ?? 0,
      apiFixturesReceived: (map['apiFixturesReceived'] as num?)?.toInt() ?? 0,
      localFixturesLoaded: (map['localFixturesLoaded'] as num?)?.toInt() ?? 0,
      countriesWithApiId: (map['countriesWithApiId'] as num?)?.toInt() ?? 0,
      countriesEnrichedFromApi:
          (map['countriesEnrichedFromApi'] as num?)?.toInt() ?? 0,
      source: map['source'] as String? ?? 'manual',
    );
  }
}

DateTime? _timestampFromDynamic(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  final seconds = (value as dynamic).seconds;
  if (seconds is int) {
    return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
  }
  return null;
}

enum AdminAuditOperation {
  fixtureResult,
  groupAdvancers,
  leaderboardRecalculation,
  contestSettings,
  standingsRecalculation,
  standingsOverride,
}

class OfficialGroupPlacements {
  const OfficialGroupPlacements({
    required this.groupPicks,
    required this.bestThirdGroupIds,
  });

  final List<GroupPick> groupPicks;
  final List<String> bestThirdGroupIds;

  Set<String> get advancingCountryIds {
    final bestThirdGroups = bestThirdGroupIds.toSet();
    return {
      for (final pick in groupPicks) pick.firstCountryId,
      for (final pick in groupPicks) pick.secondCountryId,
      for (final pick in groupPicks)
        if (bestThirdGroups.contains(pick.groupId) &&
            pick.thirdCountryId != null &&
            pick.thirdCountryId!.isNotEmpty)
          pick.thirdCountryId!,
    };
  }

  factory OfficialGroupPlacements.fromMap(Map<String, Object?> map) {
    return OfficialGroupPlacements(
      groupPicks:
          (map['groupPicks'] as List<dynamic>? ?? const [])
              .whereType<Map>()
              .map((item) => GroupPick.fromMap(item.cast<String, Object?>()))
              .toList(),
      bestThirdGroupIds:
          (map['bestThirdGroupIds'] as List<dynamic>? ?? const [])
              .whereType<String>()
              .toList(),
    );
  }

  Map<String, Object?> toMap() => {
    'groupPicks': groupPicks.map((pick) => pick.toMap()).toList(),
    'bestThirdGroupIds': bestThirdGroupIds,
  };
}

class OfficialResults {
  const OfficialResults({
    this.advancingCountryIds = const {},
    this.knockoutWinnersBySlot = const {},
    this.finalChampionScore,
    this.finalRunnerUpScore,
    this.groupPlacements,
    this.updatedAt,
    this.updatedBy,
    this.leaderboardUpdatedAt,
  });

  final Set<String> advancingCountryIds;
  final Map<String, String> knockoutWinnersBySlot;
  final int? finalChampionScore;
  final int? finalRunnerUpScore;
  final OfficialGroupPlacements? groupPlacements;
  final DateTime? updatedAt;
  final String? updatedBy;
  final DateTime? leaderboardUpdatedAt;

  factory OfficialResults.fromMap(Map<String, Object?> map) {
    final placementsRaw = map['groupPlacements'] as Map<dynamic, dynamic>?;
    final winnersRaw = map['knockoutWinnersBySlot'] as Map<dynamic, dynamic>?;
    return OfficialResults(
      advancingCountryIds:
          (map['advancingCountryIds'] as List<dynamic>? ?? const [])
              .whereType<String>()
              .toSet(),
      knockoutWinnersBySlot:
          winnersRaw?.map((key, value) => MapEntry('$key', '$value')) ??
          const {},
      finalChampionScore: (map['finalChampionScore'] as num?)?.toInt(),
      finalRunnerUpScore: (map['finalRunnerUpScore'] as num?)?.toInt(),
      groupPlacements:
          placementsRaw == null
              ? null
              : OfficialGroupPlacements.fromMap(
                placementsRaw.cast<String, Object?>(),
              ),
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? ''),
      updatedBy: map['updatedBy'] as String?,
      leaderboardUpdatedAt: DateTime.tryParse(
        map['leaderboardUpdatedAt'] as String? ?? '',
      ),
    );
  }

  Map<String, Object?> toMap() => {
    'advancingCountryIds': advancingCountryIds.toList()..sort(),
    'knockoutWinnersBySlot': knockoutWinnersBySlot,
    'finalChampionScore': finalChampionScore,
    'finalRunnerUpScore': finalRunnerUpScore,
    'groupPlacements': groupPlacements?.toMap(),
    'updatedAt': updatedAt?.toIso8601String(),
    'updatedBy': updatedBy,
    'leaderboardUpdatedAt': leaderboardUpdatedAt?.toIso8601String(),
  };

  OfficialResults copyWith({
    Set<String>? advancingCountryIds,
    Map<String, String>? knockoutWinnersBySlot,
    int? finalChampionScore,
    int? finalRunnerUpScore,
    OfficialGroupPlacements? groupPlacements,
    DateTime? updatedAt,
    String? updatedBy,
    DateTime? leaderboardUpdatedAt,
  }) {
    return OfficialResults(
      advancingCountryIds: advancingCountryIds ?? this.advancingCountryIds,
      knockoutWinnersBySlot:
          knockoutWinnersBySlot ?? this.knockoutWinnersBySlot,
      finalChampionScore: finalChampionScore ?? this.finalChampionScore,
      finalRunnerUpScore: finalRunnerUpScore ?? this.finalRunnerUpScore,
      groupPlacements: groupPlacements ?? this.groupPlacements,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      leaderboardUpdatedAt: leaderboardUpdatedAt ?? this.leaderboardUpdatedAt,
    );
  }
}

class AdminAuditLog {
  const AdminAuditLog({
    required this.id,
    required this.operationType,
    required this.after,
    required this.adminUserId,
    required this.adminEmail,
    required this.createdAt,
    this.before,
    this.note,
  });

  final String id;
  final AdminAuditOperation operationType;
  final Map<String, Object?>? before;
  final Map<String, Object?> after;
  final String adminUserId;
  final String adminEmail;
  final DateTime createdAt;
  final String? note;

  factory AdminAuditLog.fromMap(String id, Map<String, Object?> map) {
    return AdminAuditLog(
      id: id,
      operationType: _enumFromName(
        AdminAuditOperation.values,
        map['operationType'] as String?,
        AdminAuditOperation.fixtureResult,
      ),
      before:
          (map['before'] as Map<dynamic, dynamic>?)?.cast<String, Object?>(),
      after:
          (map['after'] as Map<dynamic, dynamic>? ?? const {})
              .cast<String, Object?>(),
      adminUserId: map['adminUserId'] as String? ?? '',
      adminEmail: map['adminEmail'] as String? ?? '',
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      note: map['note'] as String?,
    );
  }

  Map<String, Object?> toMap() => {
    'operationType': operationType.name,
    'before': before,
    'after': after,
    'adminUserId': adminUserId,
    'adminEmail': adminEmail,
    'createdAt': createdAt.toIso8601String(),
    'note': note,
  };
}

class LeaderboardRecalculationSummary {
  const LeaderboardRecalculationSummary({
    required this.entriesUpdated,
    required this.recalculatedAt,
  });

  final int entriesUpdated;
  final DateTime recalculatedAt;
}

class ModerationReport {
  const ModerationReport({
    required this.id,
    required this.reporterId,
    required this.targetType,
    required this.targetId,
    required this.reason,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String reporterId;
  final ReportTargetType targetType;
  final String targetId;
  final String reason;
  final ReportStatus status;
  final DateTime createdAt;

  Map<String, Object?> toMap() => {
    'reporterId': reporterId,
    'targetType': targetType.name,
    'targetId': targetId,
    'reason': reason,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
  };
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
  });

  final String id;
  final NotificationKind kind;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.userId,
    required this.username,
    required this.text,
    required this.createdAt,
    required this.updatedAt,
    this.reactionsByUser = const {},
    this.isEdited = false,
    this.isDeleted = false,
  });

  static const maxTextLength = 1000;
  static const quickReactionEmojis = ['⚽', '🔥', '👏', '🏆'];

  final String id;
  final String userId;
  final String username;
  final String text;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, List<String>> reactionsByUser;
  final bool isEdited;
  final bool isDeleted;

  bool canBeChangedBy(String currentUserId) => userId == currentUserId;

  bool hasUserReacted(String currentUserId, String emoji) {
    return reactionsByUser[currentUserId]?.contains(emoji) ?? false;
  }

  Map<String, int> reactionCounts() {
    final counts = <String, int>{};
    for (final emojis in reactionsByUser.values) {
      for (final emoji in emojis) {
        counts[emoji] = (counts[emoji] ?? 0) + 1;
      }
    }
    return counts;
  }

  factory ChatMessage.fromMap(String id, Map<String, Object?> map) {
    final rawReactionsByUser =
        map['reactionsByUser'] as Map<dynamic, dynamic>? ?? const {};
    return ChatMessage(
      id: id,
      userId: map['userId'] as String? ?? '',
      username: map['username'] as String? ?? '',
      text: map['text'] as String? ?? '',
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      reactionsByUser: rawReactionsByUser.map(
        (userId, emojis) => MapEntry(
          '$userId',
          (emojis as List<dynamic>? ?? const [])
              .map((emoji) => '$emoji')
              .toList(),
        ),
      ),
      isEdited: map['isEdited'] as bool? ?? false,
      isDeleted: map['isDeleted'] as bool? ?? false,
    );
  }

  Map<String, Object?> toMap() => {
    'userId': userId,
    'username': username,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'reactionsByUser': reactionsByUser,
    'isEdited': isEdited,
    'isDeleted': isDeleted,
    'expiresAt': createdAt.add(const Duration(days: 30)).toIso8601String(),
  };

  ChatMessage copyWith({
    String? text,
    DateTime? updatedAt,
    Map<String, List<String>>? reactionsByUser,
    bool? isEdited,
    bool? isDeleted,
  }) {
    return ChatMessage(
      id: id,
      userId: userId,
      username: username,
      text: text ?? this.text,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reactionsByUser: reactionsByUser ?? this.reactionsByUser,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

T _enumFromName<T extends Enum>(List<T> values, String? name, T fallback) {
  return values.firstWhereOrNull((value) => value.name == name) ?? fallback;
}
