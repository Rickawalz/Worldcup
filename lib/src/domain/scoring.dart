import 'models.dart';

class ActualResults {
  const ActualResults({
    required this.knockoutWinnersBySlot,
    this.groupPlacements,
    this.finalChampionScore,
    this.finalRunnerUpScore,
  });

  final OfficialGroupPlacements? groupPlacements;
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

  /// Points when a picked team finishes in the group's top three.
  static const groupTopThreePoints = 1;

  /// Extra points when the team finishes in the exact position you picked.
  static const groupExactPlacementBonus = 2;

  /// Knockout ladder: each round doubles (R32 = 1 pt, Final = 16 pts).
  static const knockoutPointsByStage = {
    TournamentStage.roundOf32: 1,
    TournamentStage.roundOf16: 2,
    TournamentStage.quarterfinal: 4,
    TournamentStage.semifinal: 8,
    TournamentStage.finalMatch: 16,
  };

  static int knockoutPointsForStage(TournamentStage stage) {
    return knockoutPointsByStage[stage] ?? 0;
  }

  ScoreBreakdown score({
    required Bracket bracket,
    required ActualResults results,
    required int pointsPerCorrectPick,
  }) {
    final groupScore = _scoreGroupPlacements(
      bracket.groupPicks,
      results.groupPlacements,
    );
    final knockoutScore = bracket.knockoutPicks.fold<int>(0, (score, pick) {
      final actualWinner = results.knockoutWinnersBySlot[pick.slotId];
      if (actualWinner == null || actualWinner != pick.winnerCountryId) {
        return score;
      }
      return score + knockoutPointsForStage(pick.stage);
    });

    final tiebreakerDistance = _tiebreakerDistance(bracket, results);
    return ScoreBreakdown(
      groupScore: groupScore,
      knockoutScore: knockoutScore,
      totalScore: groupScore + knockoutScore,
      tiebreakerDistance: tiebreakerDistance,
    );
  }

  int _scoreGroupPlacements(
    List<GroupPick> predictedPicks,
    OfficialGroupPlacements? actualPlacements,
  ) {
    if (actualPlacements == null) {
      return 0;
    }

    var score = 0;
    for (final predicted in predictedPicks) {
      final actual = _officialGroupPick(actualPlacements, predicted.groupId);
      if (actual == null) {
        continue;
      }
      score += _scorePredictedSlot(
        predictedCountryId: predicted.firstCountryId,
        predictedRank: 1,
        actual: actual,
      );
      score += _scorePredictedSlot(
        predictedCountryId: predicted.secondCountryId,
        predictedRank: 2,
        actual: actual,
      );
      score += _scorePredictedSlot(
        predictedCountryId: predicted.thirdCountryId ?? '',
        predictedRank: 3,
        actual: actual,
      );
    }
    return score;
  }

  int _scorePredictedSlot({
    required String predictedCountryId,
    required int predictedRank,
    required GroupPick actual,
  }) {
    if (predictedCountryId.isEmpty) {
      return 0;
    }
    if (!_topThreeCountryIds(actual).contains(predictedCountryId)) {
      return 0;
    }
    if (predictedCountryId == _countryIdAtRank(actual, predictedRank)) {
      return groupTopThreePoints + groupExactPlacementBonus;
    }
    return groupTopThreePoints;
  }

  GroupPick? _officialGroupPick(
    OfficialGroupPlacements placements,
    String groupId,
  ) {
    for (final pick in placements.groupPicks) {
      if (pick.groupId == groupId) {
        return pick;
      }
    }
    return null;
  }

  Set<String> _topThreeCountryIds(GroupPick pick) {
    return {
      pick.firstCountryId,
      pick.secondCountryId,
      if (pick.thirdCountryId != null && pick.thirdCountryId!.isNotEmpty)
        pick.thirdCountryId!,
    };
  }

  String _countryIdAtRank(GroupPick pick, int rank) {
    switch (rank) {
      case 1:
        return pick.firstCountryId;
      case 2:
        return pick.secondCountryId;
      case 3:
        return pick.thirdCountryId ?? '';
      default:
        return '';
    }
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
