import 'models.dart';
import 'scoring.dart';

class LeaderboardRecalculator {
  const LeaderboardRecalculator({this.scorer = const BracketScorer()});

  final BracketScorer scorer;

  List<ScoredBracket> scoreBrackets({
    required Iterable<Bracket> brackets,
    required OfficialResults officialResults,
    required int pointsPerCorrectPick,
  }) {
    final actualResults = ActualResults(
      groupPlacements: officialResults.groupPlacements,
      knockoutWinnersBySlot: officialResults.knockoutWinnersBySlot,
      finalChampionScore: officialResults.finalChampionScore,
      finalRunnerUpScore: officialResults.finalRunnerUpScore,
    );
    return [
      for (final bracket in brackets)
        ScoredBracket(
          bracket: bracket,
          breakdown: scorer.score(
            bracket: bracket,
            results: actualResults,
            pointsPerCorrectPick: pointsPerCorrectPick,
          ),
        ),
    ];
  }

  List<LeaderboardEntry> buildEntries({
    required Iterable<ScoredBracket> scoredBrackets,
    required Map<String, AppUser> usersById,
    required DateTime updatedAt,
  }) {
    final rows = [
      for (final scored in scoredBrackets)
        if (usersById[scored.bracket.userId] != null &&
            !usersById[scored.bracket.userId]!.isHidden)
          LeaderboardEntry(
            userId: scored.bracket.userId,
            username: usersById[scored.bracket.userId]!.username,
            score: scored.breakdown.totalScore,
            groupScore: scored.breakdown.groupScore,
            knockoutScore: scored.breakdown.knockoutScore,
            tiebreakerDistance: scored.breakdown.tiebreakerDistance,
            rank: 0,
            updatedAt: updatedAt,
          ),
    ];
    rows.sort((a, b) {
      if (b.score != a.score) {
        return b.score - a.score;
      }
      if (a.tiebreakerDistance != b.tiebreakerDistance) {
        return a.tiebreakerDistance - b.tiebreakerDistance;
      }
      return a.username.toLowerCase().compareTo(b.username.toLowerCase());
    });

    return [
      for (var index = 0; index < rows.length; index++)
        LeaderboardEntry(
          userId: rows[index].userId,
          username: rows[index].username,
          score: rows[index].score,
          groupScore: rows[index].groupScore,
          knockoutScore: rows[index].knockoutScore,
          tiebreakerDistance: rows[index].tiebreakerDistance,
          rank: index + 1,
          updatedAt: rows[index].updatedAt,
        ),
    ];
  }
}

class ScoredBracket {
  const ScoredBracket({required this.bracket, required this.breakdown});

  final Bracket bracket;
  final ScoreBreakdown breakdown;

  Bracket toUpdatedBracket() {
    return bracket.copyWith(
      totalScore: breakdown.totalScore,
      groupScore: breakdown.groupScore,
      knockoutScore: breakdown.knockoutScore,
      tiebreakerDistance: breakdown.tiebreakerDistance,
      updatedAt: DateTime.now(),
    );
  }
}
