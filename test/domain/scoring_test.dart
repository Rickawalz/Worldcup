import 'package:flutter_test/flutter_test.dart';
import 'package:world_cup_bracket/src/domain/models.dart';
import 'package:world_cup_bracket/src/domain/scoring.dart';

void main() {
  test('scores group advancement and knockout picks with flat points', () {
    final bracket = Bracket.empty('user').copyWith(
      groupPicks: const [
        GroupPick(
          groupId: 'A',
          firstCountryId: 'usa',
          secondCountryId: 'mex',
          thirdCountryId: 'can',
        ),
      ],
      bestThirdGroupIds: const ['A'],
      knockoutPicks: const [
        KnockoutPick(
          slotId: 'm73',
          stage: TournamentStage.roundOf32,
          winnerCountryId: 'usa',
        ),
        KnockoutPick(
          slotId: 'finalMatch-1',
          stage: TournamentStage.finalMatch,
          winnerCountryId: 'arg',
        ),
      ],
      finalScoreTiebreaker: const FinalScoreTiebreaker(
        championScore: 2,
        runnerUpScore: 1,
      ),
    );

    final score = const BracketScorer().score(
      bracket: bracket,
      results: const ActualResults(
        advancingCountryIds: {'usa', 'can'},
        knockoutWinnersBySlot: {'m73': 'usa', 'finalMatch-1': 'bra'},
        finalChampionScore: 3,
        finalRunnerUpScore: 1,
      ),
      pointsPerCorrectPick: 1,
    );

    expect(score.groupScore, 2);
    expect(score.knockoutScore, 1);
    expect(score.totalScore, 3);
    expect(score.tiebreakerDistance, 1);
  });
}
