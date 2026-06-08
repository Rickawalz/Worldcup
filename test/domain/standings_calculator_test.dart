import 'package:flutter_test/flutter_test.dart';
import 'package:world_cup_bracket/src/domain/models.dart';
import 'package:world_cup_bracket/src/domain/standings_calculator.dart';

void main() {
  test('calculates group table stats from finished group fixtures', () {
    final standings = const StandingsCalculator().calculate(
      fixtures: [
        Fixture(
          id: 'm1',
          externalId: '1',
          stage: TournamentStage.group,
          roundLabel: 'Group A',
          kickoff: DateTime.utc(2026, 6, 11),
          status: FixtureStatus.finished,
          homeCountryId: 'mexico',
          awayCountryId: 'south_africa',
          homeScore: 2,
          awayScore: 1,
          winnerCountryId: 'mexico',
        ),
        Fixture(
          id: 'm2',
          externalId: '2',
          stage: TournamentStage.group,
          roundLabel: 'Group A',
          kickoff: DateTime.utc(2026, 6, 12),
          status: FixtureStatus.finished,
          homeCountryId: 'south_korea',
          awayCountryId: 'czech_republic',
          homeScore: 0,
          awayScore: 0,
        ),
      ],
      overrideOrdersByGroup: const {},
    );

    final groupA = standings.firstWhere((standing) => standing.groupId == 'A');

    expect(groupA.rows.first.countryId, 'mexico');
    expect(groupA.rows.first.points, 3);
    expect(groupA.rows.first.goalDifference, 1);
    expect(groupA.rows.first.played, 1);
    expect(
      groupA.rows.firstWhere((row) => row.countryId == 'south_africa').lost,
      1,
    );
  });

  test('override order changes rank without changing calculated stats', () {
    final standings = const StandingsCalculator().calculate(
      fixtures: [
        Fixture(
          id: 'm1',
          externalId: '1',
          stage: TournamentStage.group,
          roundLabel: 'Group A',
          kickoff: DateTime.utc(2026, 6, 11),
          status: FixtureStatus.finished,
          homeCountryId: 'mexico',
          awayCountryId: 'south_africa',
          homeScore: 2,
          awayScore: 1,
          winnerCountryId: 'mexico',
        ),
      ],
      overrideOrdersByGroup: const {
        'A': ['south_africa', 'mexico', 'south_korea', 'czech_republic'],
      },
    );

    final groupA = standings.firstWhere((standing) => standing.groupId == 'A');

    expect(groupA.rows[0].countryId, 'south_africa');
    expect(groupA.rows[0].points, 0);
    expect(groupA.rows[1].countryId, 'mexico');
    expect(groupA.rows[1].points, 3);
  });
}
