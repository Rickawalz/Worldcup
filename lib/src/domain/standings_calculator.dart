import 'bracket_rules.dart';
import 'models.dart';

class StandingsCalculator {
  const StandingsCalculator();

  static const _maxFormLength = 5;

  List<GroupStanding> calculate({
    required Iterable<Fixture> fixtures,
    required Map<String, List<String>> overrideOrdersByGroup,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return [
      for (final groupId in BracketRules.groupIds)
        _calculateGroup(
          groupId: groupId,
          fixtures: fixtures,
          overrideOrderCountryIds: overrideOrdersByGroup[groupId] ?? const [],
          updatedAt: updatedAt,
          updatedBy: updatedBy,
        ),
    ];
  }

  GroupStanding _calculateGroup({
    required String groupId,
    required Iterable<Fixture> fixtures,
    required List<String> overrideOrderCountryIds,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    final countryIds = BracketRules.groupCountryIds[groupId] ?? const [];
    final stats = {
      for (final countryId in countryIds)
        countryId: _MutableStanding(countryId),
    };
    final groupFixtures =
        fixtures
            .where(
              (fixture) =>
                  fixture.stage == TournamentStage.group &&
                  fixture.status == FixtureStatus.finished &&
                  fixture.roundLabel.trim().toUpperCase() == 'GROUP $groupId' &&
                  fixture.homeCountryId != null &&
                  fixture.awayCountryId != null &&
                  fixture.homeScore != null &&
                  fixture.awayScore != null,
            )
            .toList()
          ..sort((a, b) => a.kickoff.compareTo(b.kickoff));

    for (final fixture in groupFixtures) {
      final home = stats[fixture.homeCountryId];
      final away = stats[fixture.awayCountryId];
      if (home == null || away == null) {
        continue;
      }
      home.apply(
        goalsFor: fixture.homeScore!,
        goalsAgainst: fixture.awayScore!,
      );
      away.apply(
        goalsFor: fixture.awayScore!,
        goalsAgainst: fixture.homeScore!,
      );
    }

    final rows =
        stats.values.map((standing) => standing.toRow()).toList()
          ..sort(_defaultCompare);
    final orderedRows = _applyOverride(rows, overrideOrderCountryIds);
    return GroupStanding(
      groupId: groupId,
      rows: [
        for (var index = 0; index < orderedRows.length; index++)
          orderedRows[index].copyWith(rank: index + 1),
      ],
      overrideOrderCountryIds: overrideOrderCountryIds,
      updatedAt: updatedAt,
      updatedBy: updatedBy,
    );
  }

  int _defaultCompare(StandingRow a, StandingRow b) {
    if (b.points != a.points) return b.points - a.points;
    if (b.goalDifference != a.goalDifference) {
      return b.goalDifference - a.goalDifference;
    }
    if (b.goalsFor != a.goalsFor) return b.goalsFor - a.goalsFor;
    return a.countryId.compareTo(b.countryId);
  }

  List<StandingRow> _applyOverride(
    List<StandingRow> rows,
    List<String> overrideOrderCountryIds,
  ) {
    if (overrideOrderCountryIds.isEmpty) {
      return rows;
    }
    final byCountryId = {for (final row in rows) row.countryId: row};
    return [
      for (final countryId in overrideOrderCountryIds)
        if (byCountryId[countryId] != null) byCountryId.remove(countryId)!,
      ...byCountryId.values,
    ];
  }
}

class _MutableStanding {
  _MutableStanding(this.countryId);

  final String countryId;
  int played = 0;
  int won = 0;
  int drawn = 0;
  int lost = 0;
  int goalsFor = 0;
  int goalsAgainst = 0;
  final List<String> _recentResults = [];

  int get goalDifference => goalsFor - goalsAgainst;
  int get points => won * 3 + drawn;

  void apply({required int goalsFor, required int goalsAgainst}) {
    played++;
    this.goalsFor += goalsFor;
    this.goalsAgainst += goalsAgainst;
    if (goalsFor > goalsAgainst) {
      won++;
      _recentResults.add('W');
    } else if (goalsFor < goalsAgainst) {
      lost++;
      _recentResults.add('L');
    } else {
      drawn++;
      _recentResults.add('D');
    }
    while (_recentResults.length > StandingsCalculator._maxFormLength) {
      _recentResults.removeAt(0);
    }
  }

  String get form {
    if (_recentResults.isEmpty) {
      return '';
    }
    return _recentResults.join(',');
  }

  StandingRow toRow() {
    return StandingRow(
      countryId: countryId,
      rank: 0,
      played: played,
      won: won,
      drawn: drawn,
      lost: lost,
      goalsFor: goalsFor,
      goalsAgainst: goalsAgainst,
      goalDifference: goalDifference,
      points: points,
      form: form,
    );
  }
}
