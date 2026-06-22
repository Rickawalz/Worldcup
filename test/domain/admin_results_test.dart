import 'package:flutter_test/flutter_test.dart';
import 'package:world_cup_bracket/src/domain/admin_validators.dart';
import 'package:world_cup_bracket/src/domain/bracket_rules.dart';
import 'package:world_cup_bracket/src/domain/leaderboard_recalculator.dart';
import 'package:world_cup_bracket/src/domain/models.dart';

void main() {
  group('OfficialResults', () {
    test('round trips scoring inputs and metadata', () {
      final updatedAt = DateTime.utc(2026, 7, 19, 22);
      final results = OfficialResults(
        advancingCountryIds: const {'usa', 'mexico'},
        knockoutWinnersBySlot: const {'m73': 'usa'},
        finalChampionScore: 3,
        finalRunnerUpScore: 2,
        updatedAt: updatedAt,
        updatedBy: 'admin',
      );

      final copy = OfficialResults.fromMap(results.toMap());

      expect(copy.advancingCountryIds, {'usa', 'mexico'});
      expect(copy.knockoutWinnersBySlot, {'m73': 'usa'});
      expect(copy.finalChampionScore, 3);
      expect(copy.finalRunnerUpScore, 2);
      expect(copy.updatedAt, updatedAt);
      expect(copy.updatedBy, 'admin');
    });
  });

  group('Fixture', () {
    test('round trips venue metadata and formats partial labels', () {
      final fixture = Fixture(
        id: 'm1',
        externalId: '1',
        stage: TournamentStage.group,
        roundLabel: 'Group A',
        kickoff: DateTime.utc(2026, 6, 11, 19),
        status: FixtureStatus.scheduled,
        homeCountryId: 'mexico',
        awayCountryId: 'south_korea',
        venueName: 'Estadio Azteca',
        venueCity: 'Mexico City',
      );

      final copy = Fixture.fromMap(fixture.id, fixture.toMap());

      expect(copy.venueName, 'Estadio Azteca');
      expect(copy.venueCity, 'Mexico City');
      expect(copy.venueLabel, 'Estadio Azteca, Mexico City');
      expect(copy.copyWith(venueName: '').venueLabel, 'Mexico City');
    });
  });

  group('AdminValidators', () {
    test('requires knockout winner to be one of the fixture teams', () {
      final fixture = Fixture(
        id: 'm73',
        externalId: '73',
        stage: TournamentStage.roundOf32,
        roundLabel: 'Round of 32',
        kickoff: DateTime.utc(2026, 6, 28),
        status: FixtureStatus.finished,
        homeCountryId: 'usa',
        awayCountryId: 'mexico',
        homeScore: 1,
        awayScore: 1,
        winnerCountryId: 'brazil',
      );

      expect(
        AdminValidators.validateFixtureResult(fixture),
        'Winner must be one of the two teams.',
      );
    });

    test('accepts exactly 32 official group advancers', () {
      final placements = _validGroupPlacements();

      expect(AdminValidators.validateGroupPlacements(placements), isNull);
      expect(placements.advancingCountryIds, hasLength(32));
    });
  });

  group('LeaderboardRecalculator', () {
    test('builds ranked entries with score breakdowns', () {
      final users = {
        'u1': AppUser(
          id: 'u1',
          username: 'Ricky',
          createdAt: DateTime.utc(2026),
        ),
        'u2': AppUser(
          id: 'u2',
          username: 'Guest',
          createdAt: DateTime.utc(2026),
        ),
      };
      final bracket = Bracket.empty('u1').copyWith(
        status: BracketStatus.submitted,
        groupPicks: const [
          GroupPick(
            groupId: 'A',
            firstCountryId: 'usa',
            secondCountryId: 'mexico',
            thirdCountryId: 'canada',
          ),
        ],
        bestThirdGroupIds: const ['A'],
        knockoutPicks: const [
          KnockoutPick(
            slotId: 'm73',
            stage: TournamentStage.roundOf32,
            winnerCountryId: 'usa',
          ),
        ],
      );
      final updatedAt = DateTime.utc(2026, 7, 1);
      final recalculator = const LeaderboardRecalculator();
      final scored = recalculator.scoreBrackets(
        brackets: [bracket],
        officialResults: OfficialResults(
          advancingCountryIds: const {'usa', 'canada'},
          knockoutWinnersBySlot: const {'m73': 'usa'},
          groupPlacements: OfficialGroupPlacements(
            groupPicks: const [
              GroupPick(
                groupId: 'A',
                firstCountryId: 'usa',
                secondCountryId: 'mexico',
                thirdCountryId: 'canada',
              ),
            ],
            bestThirdGroupIds: const ['A'],
          ),
        ),
        pointsPerCorrectPick: 1,
      );

      final entries = recalculator.buildEntries(
        scoredBrackets: scored,
        usersById: users,
        updatedAt: updatedAt,
      );

      expect(entries, hasLength(1));
      expect(entries.single.rank, 1);
      expect(entries.single.score, 10);
      expect(entries.single.groupScore, 9);
      expect(entries.single.knockoutScore, 1);
      expect(entries.single.updatedAt, updatedAt);
    });
  });
}

OfficialGroupPlacements _validGroupPlacements() {
  return OfficialGroupPlacements(
    groupPicks: [
      for (final groupId in BracketRules.groupIds)
        GroupPick(
          groupId: groupId,
          firstCountryId: BracketRules.groupCountryIds[groupId]![0],
          secondCountryId: BracketRules.groupCountryIds[groupId]![1],
          thirdCountryId: BracketRules.groupCountryIds[groupId]![2],
        ),
    ],
    bestThirdGroupIds: BracketRules.groupIds.take(8).toList(),
  );
}
