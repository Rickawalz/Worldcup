import '../domain/models.dart';

class ApiFootballMapper {
  const ApiFootballMapper();

  Fixture fixtureFromResponse(Map<String, Object?> response) {
    final fixture = _map(response['fixture']);
    final league = _map(response['league']);
    final teams = _map(response['teams']);
    final goals = _map(response['goals']);
    final home = _map(teams['home']);
    final away = _map(teams['away']);
    final status = _map(fixture['status']);

    final externalId = '${fixture['id'] ?? ''}';
    return Fixture(
      id: externalId,
      externalId: externalId,
      stage: _stageFromRound(league['round'] as String? ?? ''),
      roundLabel: league['round'] as String? ?? '',
      kickoff:
          DateTime.tryParse(fixture['date'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      status: _statusFromApi(status['short'] as String? ?? 'NS'),
      homeCountryId: _countryIdFromApi(home['id']),
      awayCountryId: _countryIdFromApi(away['id']),
      homeScore: (goals['home'] as num?)?.toInt(),
      awayScore: (goals['away'] as num?)?.toInt(),
      winnerCountryId:
          home['winner'] == true
              ? _countryIdFromApi(home['id'])
              : away['winner'] == true
              ? _countryIdFromApi(away['id'])
              : null,
    );
  }

  List<Map<String, Object?>> standingsRowsFromResponse(
    Map<String, Object?> response,
  ) {
    final team = _map(response['team']);
    final all = _map(response['all']);
    final goals = _map(all['goals']);
    return [
      {
        'rank': response['rank'],
        'apiFootballTeamId': team['id'],
        'teamName': team['name'],
        'flagUrl': team['logo'],
        'points': response['points'],
        'goalDifference': response['goalsDiff'],
        'played': all['played'],
        'won': all['win'],
        'drawn': all['draw'],
        'lost': all['lose'],
        'goalsFor': goals['for'],
        'goalsAgainst': goals['against'],
      },
    ];
  }

  TournamentStage _stageFromRound(String round) {
    final normalized = round.toLowerCase();
    if (normalized.contains('round of 32')) return TournamentStage.roundOf32;
    if (normalized.contains('round of 16')) return TournamentStage.roundOf16;
    if (normalized.contains('quarter')) return TournamentStage.quarterfinal;
    if (normalized.contains('semi')) return TournamentStage.semifinal;
    if (normalized.contains('final')) return TournamentStage.finalMatch;
    return TournamentStage.group;
  }

  FixtureStatus _statusFromApi(String status) {
    if (['1H', 'HT', '2H', 'ET', 'P', 'BT'].contains(status)) {
      return FixtureStatus.live;
    }
    if (['FT', 'AET', 'PEN'].contains(status)) {
      return FixtureStatus.finished;
    }
    if (['PST', 'CANC', 'ABD'].contains(status)) {
      return FixtureStatus.postponed;
    }
    return FixtureStatus.scheduled;
  }

  String? _countryIdFromApi(Object? id) {
    if (id == null) return null;
    return 'api_$id';
  }

  Map<String, Object?> _map(Object? value) {
    return (value as Map<dynamic, dynamic>? ?? const {})
        .cast<String, Object?>();
  }
}
