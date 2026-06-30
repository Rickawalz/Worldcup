import 'package:flutter_test/flutter_test.dart';
import 'package:world_cup_bracket/src/domain/bracket_rules.dart';
import 'package:world_cup_bracket/src/domain/group_placements.dart';
import 'package:world_cup_bracket/src/domain/models.dart';

void main() {
  test('derives official placements from complete standings', () {
    final standings = [
      for (final groupId in BracketRules.groupIds)
        GroupStanding(
          groupId: groupId,
          rows: [
            StandingRow(
              countryId: 'first_$groupId',
              rank: 1,
              played: 3,
              won: 2,
              drawn: 1,
              lost: 0,
              goalsFor: 5,
              goalsAgainst: 2,
              goalDifference: 3,
              points: 7,
              form: 'W,W,D',
            ),
            StandingRow(
              countryId: 'second_$groupId',
              rank: 2,
              played: 3,
              won: 1,
              drawn: 2,
              lost: 0,
              goalsFor: 4,
              goalsAgainst: 3,
              goalDifference: 1,
              points: 5,
              form: 'D,W,D',
            ),
            StandingRow(
              countryId: 'third_$groupId',
              rank: 3,
              played: 3,
              won: 1,
              drawn: 0,
              lost: 2,
              goalsFor: 2,
              goalsAgainst: 4,
              goalDifference: -2,
              points: 3,
              form: 'L,L,W',
            ),
            StandingRow(
              countryId: 'fourth_$groupId',
              rank: 4,
              played: 3,
              won: 0,
              drawn: 0,
              lost: 3,
              goalsFor: 1,
              goalsAgainst: 6,
              goalDifference: -5,
              points: 0,
              form: 'L,L,L',
            ),
          ],
        ),
    ];

    final placements = officialPlacementsFromStandings(standings);

    expect(placements, isNotNull);
    expect(placements!.groupPicks, hasLength(12));
    expect(placements.bestThirdGroupIds, hasLength(8));
    expect(placements.advancingCountryIds, hasLength(32));
  });

  test('derives partial placements for completed groups only', () {
    final standings = [
      GroupStanding(
        groupId: 'A',
        rows: [
          _row(countryId: 'mexico', rank: 1, points: 7),
          _row(countryId: 'south_africa', rank: 2, points: 4),
          _row(countryId: 'south_korea', rank: 3, points: 3),
          _row(countryId: 'czech_republic', rank: 4, points: 0),
        ],
      ),
    ];

    final partial = officialPlacementsFromStandings(
      standings,
      requireAllGroups: false,
    );
    final full = officialPlacementsFromStandings(standings);

    expect(partial, isNotNull);
    expect(partial!.groupPicks, hasLength(1));
    expect(partial.groupPicks.single.groupId, 'A');
    expect(full, isNull);
  });

  test('uses derived placements for scoring when stored placements are missing', () {
    final standings = [
      GroupStanding(
        groupId: 'A',
        rows: [
          _row(countryId: 'mexico', rank: 1, points: 7),
          _row(countryId: 'south_africa', rank: 2, points: 4),
          _row(countryId: 'south_korea', rank: 3, points: 3),
          _row(countryId: 'czech_republic', rank: 4, points: 0),
        ],
      ),
    ];

    final effective = officialResultsForScoring(
      stored: const OfficialResults(updatedBy: 'admin-user-id'),
      standings: standings,
    );

    expect(effective.groupPlacements, isNotNull);
    expect(effective.groupPlacements!.groupPicks.single.firstCountryId, 'mexico');
  });

  test('blocks auto update after admin override', () {
    expect(shouldAutoUpdateGroupPlacements(null), isTrue);
    expect(shouldAutoUpdateGroupPlacements('leaderboard-recalc'), isTrue);
    expect(shouldAutoUpdateGroupPlacements('admin-user-id'), isFalse);
  });
}

StandingRow _row({
  required String countryId,
  required int rank,
  required int points,
}) {
  return StandingRow(
    countryId: countryId,
    rank: rank,
    played: 3,
    won: points ~/ 3,
    drawn: points % 3,
    lost: 3 - (points ~/ 3) - (points % 3),
    goalsFor: 4,
    goalsAgainst: 2,
    goalDifference: 2,
    points: points,
    form: 'W,D,L',
  );
}
