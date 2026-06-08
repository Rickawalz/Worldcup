import 'bracket_rules.dart';
import 'models.dart';

class AdminValidators {
  const AdminValidators._();

  static String? validateFixtureResult(Fixture fixture) {
    if (fixture.homeCountryId == null || fixture.homeCountryId!.isEmpty) {
      return 'Select the home team.';
    }
    if (fixture.awayCountryId == null || fixture.awayCountryId!.isEmpty) {
      return 'Select the away team.';
    }
    if (fixture.homeCountryId == fixture.awayCountryId) {
      return 'Home and away teams must be different.';
    }
    final homeScore = fixture.homeScore;
    final awayScore = fixture.awayScore;
    if (fixture.status == FixtureStatus.finished) {
      if (homeScore == null || awayScore == null) {
        return 'Enter both scores before marking a fixture finished.';
      }
      if (homeScore < 0 || awayScore < 0) {
        return 'Scores cannot be negative.';
      }
      if (fixture.winnerCountryId == null || fixture.winnerCountryId!.isEmpty) {
        return 'Select the winner.';
      }
    }
    final winner = fixture.winnerCountryId;
    if (winner != null &&
        winner.isNotEmpty &&
        winner != fixture.homeCountryId &&
        winner != fixture.awayCountryId) {
      return 'Winner must be one of the two teams.';
    }
    return null;
  }

  static String? validateGroupPlacements(OfficialGroupPlacements placements) {
    final picksByGroup = {
      for (final pick in placements.groupPicks) pick.groupId: pick,
    };
    for (final groupId in BracketRules.groupIds) {
      final pick = picksByGroup[groupId];
      if (pick == null) {
        return 'Select placements for Group $groupId.';
      }
      final selected =
          [
            pick.firstCountryId,
            pick.secondCountryId,
            pick.thirdCountryId,
          ].whereType<String>().where((id) => id.isNotEmpty).toList();
      if (selected.length != 3 || selected.toSet().length != 3) {
        return 'Group $groupId needs three different teams.';
      }
      final allowed = BracketRules.groupCountryIds[groupId] ?? const [];
      if (!selected.every(allowed.contains)) {
        return 'Group $groupId includes a team outside that group.';
      }
    }
    final bestThirdGroups = placements.bestThirdGroupIds.toSet();
    if (bestThirdGroups.length != 8) {
      return 'Select exactly 8 best third-place teams.';
    }
    if (!bestThirdGroups.every(BracketRules.groupIds.contains)) {
      return 'Best third-place selections must be valid groups.';
    }
    if (placements.advancingCountryIds.length != 32) {
      return 'Official advancers must total exactly 32 teams.';
    }
    return null;
  }
}
