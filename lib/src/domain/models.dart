import 'package:collection/collection.dart';

enum TournamentStage {
  group,
  roundOf32,
  roundOf16,
  quarterfinal,
  semifinal,
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
  };
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
    );
  }
}

class GlobalContestConfig {
  const GlobalContestConfig({
    required this.lockAt,
    this.isAcceptingSubmissions = true,
    this.pointsPerCorrectPick = 1,
  });

  final DateTime lockAt;
  final bool isAcceptingSubmissions;
  final int pointsPerCorrectPick;

  bool get isLocked => DateTime.now().isAfter(lockAt);

  factory GlobalContestConfig.fromMap(Map<String, Object?> map) {
    return GlobalContestConfig(
      lockAt:
          DateTime.tryParse(map['lockAt'] as String? ?? '') ??
          DateTime(2026, 6, 11),
      isAcceptingSubmissions: map['isAcceptingSubmissions'] as bool? ?? true,
      pointsPerCorrectPick: (map['pointsPerCorrectPick'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, Object?> toMap() => {
    'lockAt': lockAt.toIso8601String(),
    'isAcceptingSubmissions': isAcceptingSubmissions,
    'pointsPerCorrectPick': pointsPerCorrectPick,
  };
}

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.userId,
    required this.username,
    required this.score,
    required this.tiebreakerDistance,
    required this.rank,
  });

  final String userId;
  final String username;
  final int score;
  final int tiebreakerDistance;
  final int rank;

  factory LeaderboardEntry.fromMap(String userId, Map<String, Object?> map) {
    return LeaderboardEntry(
      userId: userId,
      username: map['username'] as String? ?? '',
      score: (map['score'] as num?)?.toInt() ?? 0,
      tiebreakerDistance: (map['tiebreakerDistance'] as num?)?.toInt() ?? 0,
      rank: (map['rank'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, Object?> toMap() => {
    'username': username,
    'score': score,
    'tiebreakerDistance': tiebreakerDistance,
    'rank': rank,
  };
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
    this.reactions = const {},
    this.isEdited = false,
    this.isDeleted = false,
  });

  static const maxTextLength = 1000;

  final String id;
  final String userId;
  final String username;
  final String text;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, int> reactions;
  final bool isEdited;
  final bool isDeleted;

  bool canBeChangedBy(String currentUserId) => userId == currentUserId;

  factory ChatMessage.fromMap(String id, Map<String, Object?> map) {
    final rawReactions = map['reactions'] as Map<dynamic, dynamic>? ?? const {};
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
      reactions: rawReactions.map(
        (key, value) => MapEntry('$key', (value as num?)?.toInt() ?? 0),
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
    'reactions': reactions,
    'isEdited': isEdited,
    'isDeleted': isDeleted,
    'expiresAt': createdAt.add(const Duration(days: 30)).toIso8601String(),
  };

  ChatMessage copyWith({
    String? text,
    DateTime? updatedAt,
    Map<String, int>? reactions,
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
      reactions: reactions ?? this.reactions,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

T _enumFromName<T extends Enum>(List<T> values, String? name, T fallback) {
  return values.firstWhereOrNull((value) => value.name == name) ?? fallback;
}
