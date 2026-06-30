import 'models.dart';

class RankedPlayerProfile {
  const RankedPlayerProfile({
    required this.profile,
    required this.rank,
    required this.totalScore,
    required this.groupScore,
    required this.knockoutScore,
    required this.tiebreakerDistance,
  });

  final PublicBracketProfile profile;
  final int rank;
  final int totalScore;
  final int groupScore;
  final int knockoutScore;
  final int tiebreakerDistance;
}

List<RankedPlayerProfile> rankPublicBracketProfiles({
  required List<PublicBracketProfile> profiles,
  required List<LeaderboardEntry> leaderboard,
}) {
  final leaderboardByUserId = {
    for (final entry in leaderboard) entry.userId: entry,
  };
  final rankByUserId = {
    for (final entry in leaderboard)
      if (entry.rank > 0) entry.userId: entry.rank,
  };

  final sorted =
      [...profiles]..sort(
        (a, b) => _compareProfiles(
          a,
          b,
          rankByUserId,
          leaderboardByUserId,
        ),
      );

  return [
    for (var index = 0; index < sorted.length; index++)
      _buildRankedProfile(
        profile: sorted[index],
        fallbackRank: index + 1,
        leaderboardEntry: leaderboardByUserId[sorted[index].user.id],
      ),
  ];
}

RankedPlayerProfile _buildRankedProfile({
  required PublicBracketProfile profile,
  required int fallbackRank,
  required LeaderboardEntry? leaderboardEntry,
}) {
  return RankedPlayerProfile(
    profile: profile,
    rank: leaderboardEntry?.rank ?? fallbackRank,
    totalScore: leaderboardEntry?.score ?? profile.bracket.totalScore,
    groupScore: leaderboardEntry?.groupScore ?? profile.bracket.groupScore,
    knockoutScore:
        leaderboardEntry?.knockoutScore ?? profile.bracket.knockoutScore,
    tiebreakerDistance:
        leaderboardEntry?.tiebreakerDistance ??
        profile.bracket.tiebreakerDistance,
  );
}

int _compareProfiles(
  PublicBracketProfile a,
  PublicBracketProfile b,
  Map<String, int> rankByUserId,
  Map<String, LeaderboardEntry> leaderboardByUserId,
) {
  final rankA = rankByUserId[a.user.id];
  final rankB = rankByUserId[b.user.id];
  if (rankA != null && rankB != null && rankA != rankB) {
    return rankA.compareTo(rankB);
  }
  if (rankA != null && rankB == null) {
    return -1;
  }
  if (rankA == null && rankB != null) {
    return 1;
  }

  final scoreA =
      leaderboardByUserId[a.user.id]?.score ?? a.bracket.totalScore;
  final scoreB =
      leaderboardByUserId[b.user.id]?.score ?? b.bracket.totalScore;
  if (scoreB != scoreA) {
    return scoreB.compareTo(scoreA);
  }

  final tieA =
      leaderboardByUserId[a.user.id]?.tiebreakerDistance ??
      a.bracket.tiebreakerDistance;
  final tieB =
      leaderboardByUserId[b.user.id]?.tiebreakerDistance ??
      b.bracket.tiebreakerDistance;
  if (tieA != tieB) {
    return tieA.compareTo(tieB);
  }
  return a.user.username.toLowerCase().compareTo(b.user.username.toLowerCase());
}
