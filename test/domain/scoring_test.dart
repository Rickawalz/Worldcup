import 'package:flutter_test/flutter_test.dart';
import 'package:world_cup_bracket/src/domain/models.dart';
import 'package:world_cup_bracket/src/domain/scoring.dart';

void main() {
  test('scores exact and partial group placements with model 1 rules', () {
    final bracket = Bracket.empty('user').copyWith(
      groupPicks: const [
        GroupPick(
          groupId: 'A',
          firstCountryId: 'mexico',
          secondCountryId: 'south_korea',
          thirdCountryId: 'czech_republic',
        ),
      ],
      knockoutPicks: const [
        KnockoutPick(
          slotId: 'm73',
          stage: TournamentStage.roundOf32,
          winnerCountryId: 'mexico',
        ),
      ],
    );

    final score = const BracketScorer().score(
      bracket: bracket,
      results: ActualResults(
        groupPlacements: OfficialGroupPlacements(
          groupPicks: const [
            GroupPick(
              groupId: 'A',
              firstCountryId: 'mexico',
              secondCountryId: 'south_africa',
              thirdCountryId: 'south_korea',
            ),
          ],
          bestThirdGroupIds: const ['A'],
        ),
        knockoutWinnersBySlot: const {'m73': 'mexico'},
      ),
      pointsPerCorrectPick: 1,
    );

    expect(score.groupScore, 4);
    expect(score.knockoutScore, 1);
    expect(score.totalScore, 5);
  });

  test('awards exact placement bonus only once per pick', () {
    final score = const BracketScorer().score(
      bracket: Bracket.empty('user').copyWith(
        groupPicks: const [
          GroupPick(
            groupId: 'A',
            firstCountryId: 'mexico',
            secondCountryId: 'south_africa',
            thirdCountryId: 'south_korea',
          ),
        ],
      ),
      results: ActualResults(
        groupPlacements: OfficialGroupPlacements(
          groupPicks: const [
            GroupPick(
              groupId: 'A',
              firstCountryId: 'mexico',
              secondCountryId: 'south_africa',
              thirdCountryId: 'south_korea',
            ),
          ],
          bestThirdGroupIds: const ['A'],
        ),
        knockoutWinnersBySlot: const {},
      ),
      pointsPerCorrectPick: 1,
    );

    expect(score.groupScore, 9);
  });

  test('returns zero group score when official placements are missing', () {
    final score = const BracketScorer().score(
      bracket: Bracket.empty('user').copyWith(
        groupPicks: const [
          GroupPick(
            groupId: 'A',
            firstCountryId: 'mexico',
            secondCountryId: 'south_korea',
            thirdCountryId: 'czech_republic',
          ),
        ],
      ),
      results: const ActualResults(knockoutWinnersBySlot: {}),
      pointsPerCorrectPick: 1,
    );

    expect(score.groupScore, 0);
  });

  test('uses doubling knockout ladder for correct winners', () {
    final score = const BracketScorer().score(
      bracket: Bracket.empty('user').copyWith(
        knockoutPicks: const [
          KnockoutPick(
            slotId: 'm73',
            stage: TournamentStage.roundOf32,
            winnerCountryId: 'mexico',
          ),
          KnockoutPick(
            slotId: 'm89',
            stage: TournamentStage.roundOf16,
            winnerCountryId: 'brazil',
          ),
          KnockoutPick(
            slotId: 'm104',
            stage: TournamentStage.finalMatch,
            winnerCountryId: 'argentina',
          ),
        ],
      ),
      results: const ActualResults(
        knockoutWinnersBySlot: {
          'm73': 'mexico',
          'm89': 'brazil',
          'm104': 'argentina',
        },
      ),
      pointsPerCorrectPick: 1,
    );

    expect(score.knockoutScore, 19);
    expect(BracketScorer.knockoutPointsForStage(TournamentStage.roundOf32), 1);
    expect(BracketScorer.knockoutPointsForStage(TournamentStage.finalMatch), 16);
  });

  test('computes tiebreaker distance from final score prediction', () {
    final score = const BracketScorer().score(
      bracket: Bracket.empty('user').copyWith(
        finalScoreTiebreaker: const FinalScoreTiebreaker(
          championScore: 2,
          runnerUpScore: 1,
        ),
      ),
      results: const ActualResults(
        knockoutWinnersBySlot: {},
        finalChampionScore: 3,
        finalRunnerUpScore: 1,
      ),
      pointsPerCorrectPick: 1,
    );

    expect(score.tiebreakerDistance, 1);
  });
}
