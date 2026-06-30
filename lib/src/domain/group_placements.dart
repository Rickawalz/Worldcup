import 'bracket_rules.dart';
import 'models.dart';

const automatedGroupPlacementUpdatedBy = {
  'score-bracket-trigger',
  'football-data-sync',
  'standings-auto',
  'leaderboard-recalc',
};

bool isGroupStandingComplete(GroupStanding standing) {
  return standing.rows.length >= 3 &&
      standing.rows.every((row) => row.played == 3);
}

bool areAllStandingsComplete(List<GroupStanding> standings) {
  return BracketRules.groupIds.every((groupId) {
    final standing = _standingForGroup(standings, groupId);
    return standing != null && isGroupStandingComplete(standing);
  });
}

/// Derives official group placements from standings.
///
/// When [requireAllGroups] is true, returns null unless every group has finished
/// all three games. Otherwise returns placements for every completed group.
OfficialGroupPlacements? officialPlacementsFromStandings(
  List<GroupStanding> standings, {
  bool requireAllGroups = true,
}) {
  final completeStandings = <GroupStanding>[];
  for (final groupId in BracketRules.groupIds) {
    final standing = _standingForGroup(standings, groupId);
    if (standing == null || !isGroupStandingComplete(standing)) {
      if (requireAllGroups) {
        return null;
      }
      continue;
    }
    completeStandings.add(standing);
  }

  if (completeStandings.isEmpty) {
    return null;
  }

  final groupPicks = <GroupPick>[];
  for (final standing in completeStandings) {
    final rows = standing.rows;
    groupPicks.add(
      GroupPick(
        groupId: standing.groupId,
        firstCountryId: rows[0].countryId,
        secondCountryId: rows[1].countryId,
        thirdCountryId: rows[2].countryId,
      ),
    );
  }

  return OfficialGroupPlacements(
    groupPicks: groupPicks,
    bestThirdGroupIds: _bestThirdGroupIds(completeStandings),
  );
}

bool shouldAutoUpdateGroupPlacements(String? existingUpdatedBy) {
  if (existingUpdatedBy == null || existingUpdatedBy.isEmpty) {
    return true;
  }
  return automatedGroupPlacementUpdatedBy.contains(existingUpdatedBy);
}

OfficialResults officialResultsForScoring({
  required OfficialResults stored,
  required List<GroupStanding> standings,
}) {
  final derived = officialPlacementsFromStandings(
    standings,
    requireAllGroups: false,
  );
  if (derived == null) {
    return stored;
  }
  return stored.copyWith(groupPlacements: derived);
}

GroupStanding? _standingForGroup(
  List<GroupStanding> standings,
  String groupId,
) {
  for (final standing in standings) {
    if (standing.groupId == groupId) {
      return standing;
    }
  }
  return null;
}

List<String> _bestThirdGroupIds(List<GroupStanding> completeStandings) {
  if (completeStandings.length < 8) {
    return const [];
  }

  final thirdRows =
      completeStandings
          .where((standing) => standing.rows.length >= 3)
          .map(
            (standing) => (
              groupId: standing.groupId,
              row: standing.rows[2],
            ),
          )
          .toList();
  if (thirdRows.length < 8) {
    return const [];
  }

  thirdRows.sort(
    (a, b) => _compareStandingRows(a.row, b.row),
  );
  return thirdRows.take(8).map((entry) => entry.groupId).toList()..sort();
}

int _compareStandingRows(StandingRow a, StandingRow b) {
  if (b.points != a.points) {
    return b.points.compareTo(a.points);
  }
  if (b.goalDifference != a.goalDifference) {
    return b.goalDifference.compareTo(a.goalDifference);
  }
  if (b.goalsFor != a.goalsFor) {
    return b.goalsFor.compareTo(a.goalsFor);
  }
  return a.countryId.compareTo(b.countryId);
}
