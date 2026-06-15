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
    expect(groupA.rows.first.form, 'W');
    expect(
      groupA.rows.firstWhere((row) => row.countryId == 'south_africa').lost,
      1,
    );
    expect(
      groupA.rows.firstWhere((row) => row.countryId == 'south_africa').form,
      'L',
    );
    expect(
      groupA.rows.firstWhere((row) => row.countryId == 'south_korea').form,
      'D',
    );
  });

  test('form keeps only the last five results in chronological order', () {
    final standings = const StandingsCalculator().calculate(
      fixtures: [
        for (var index = 0; index < 6; index++)
          Fixture(
            id: 'm$index',
            externalId: '$index',
            stage: TournamentStage.group,
            roundLabel: 'Group A',
            kickoff: DateTime.utc(2026, 6, 11 + index),
            status: FixtureStatus.finished,
            homeCountryId: 'mexico',
            awayCountryId: 'south_africa',
            homeScore: index.isEven ? 1 : 0,
            awayScore: index.isEven ? 0 : 1,
          ),
      ],
      overrideOrdersByGroup: const {},
    );

    final mexico = standings
        .firstWhere((standing) => standing.groupId == 'A')
        .rows
        .firstWhere((row) => row.countryId == 'mexico');

    expect(mexico.form.split(','), ['L', 'W', 'L', 'W', 'L']);
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
