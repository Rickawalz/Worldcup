import 'package:flutter_test/flutter_test.dart';
import 'package:world_cup_bracket/src/data/api_football_mapper.dart';
import 'package:world_cup_bracket/src/domain/models.dart';

void main() {
  test('maps API-Football fixture response into app fixture', () {
    final fixture = const ApiFootballMapper().fixtureFromResponse({
      'fixture': {
        'id': 73,
        'date': '2026-06-28T19:00:00+00:00',
        'status': {'short': 'FT'},
      },
      'league': {'round': 'Round of 32'},
      'teams': {
        'home': {'id': 1, 'winner': true},
        'away': {'id': 2, 'winner': false},
      },
      'goals': {'home': 2, 'away': 0},
    });

    expect(fixture.id, '73');
    expect(fixture.stage, TournamentStage.roundOf32);
    expect(fixture.status, FixtureStatus.finished);
    expect(fixture.winnerCountryId, 'api_1');
  });
}
