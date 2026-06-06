import 'models.dart';
import 'bracket_rules.dart';

class ActualResults {
  const ActualResults({
    required this.advancingCountryIds,
    required this.knockoutWinnersBySlot,
    this.finalChampionScore,
    this.finalRunnerUpScore,
  });

  final Set<String> advancingCountryIds;
  final Map<String, String> knockoutWinnersBySlot;
  final int? finalChampionScore;
  final int? finalRunnerUpScore;
}

class ScoreBreakdown {
  const ScoreBreakdown({
    required this.groupScore,
    required this.knockoutScore,
    required this.totalScore,
    required this.tiebreakerDistance,
  });

  final int groupScore;
  final int knockoutScore;
  final int totalScore;
  final int tiebreakerDistance;
}

class BracketScorer {
  const BracketScorer();

  ScoreBreakdown score({
    required Bracket bracket,
    required ActualResults results,
    required int pointsPerCorrectPick,
  }) {
    final groupScore = _scoreGroupAdvancers(
      BracketRules.predictedAdvancingCountryIds(bracket),
      results.advancingCountryIds,
      pointsPerCorrectPick,
    );
    final knockoutScore = bracket.knockoutPicks.fold<int>(0, (score, pick) {
      final actualWinner = results.knockoutWinnersBySlot[pick.slotId];
      if (actualWinner == null || actualWinner != pick.winnerCountryId) {
        return score;
      }
      return score + pointsPerCorrectPick;
    });

    final tiebreakerDistance = _tiebreakerDistance(bracket, results);
    return ScoreBreakdown(
      groupScore: groupScore,
      knockoutScore: knockoutScore,
      totalScore: groupScore + knockoutScore,
      tiebreakerDistance: tiebreakerDistance,
    );
  }

  int _scoreGroupAdvancers(
    Set<String> predictedAdvancers,
    Set<String> actualAdvancers,
    int pointsPerCorrectPick,
  ) {
    return predictedAdvancers
            .where((countryId) => actualAdvancers.contains(countryId))
            .length *
        pointsPerCorrectPick;
  }

  int _tiebreakerDistance(Bracket bracket, ActualResults results) {
    final championScore = results.finalChampionScore;
    final runnerUpScore = results.finalRunnerUpScore;
    if (championScore == null || runnerUpScore == null) {
      return 0;
    }
    return bracket.finalScoreTiebreaker.distanceFrom(
      championScore,
      runnerUpScore,
    );
  }
}
