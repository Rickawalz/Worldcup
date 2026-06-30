import 'group_placements.dart';
import 'models.dart';
import 'standings_calculator.dart';

class TournamentReconciliationResult {
  const TournamentReconciliationResult({
    required this.standings,
    required this.officialResultsForScoring,
    this.officialResultsToPersist,
  });

  final List<GroupStanding> standings;
  final OfficialResults officialResultsForScoring;
  final OfficialResults? officialResultsToPersist;
}

class TournamentReconciler {
  const TournamentReconciler({
    this.standingsCalculator = const StandingsCalculator(),
  });

  final StandingsCalculator standingsCalculator;

  TournamentReconciliationResult reconcile({
    required List<Fixture> fixtures,
    required List<GroupStanding> existingStandings,
    required OfficialResults officialResults,
    required DateTime updatedAt,
    required String updatedBy,
  }) {
    final overrideOrdersByGroup = {
      for (final standing in existingStandings)
        standing.groupId: standing.overrideOrderCountryIds,
    };
    final standings = standingsCalculator.calculate(
      fixtures: fixtures,
      overrideOrdersByGroup: overrideOrdersByGroup,
      updatedAt: updatedAt,
      updatedBy: updatedBy,
    );

    final scoringResults = officialResultsForScoring(
      stored: officialResults,
      standings: standings,
    );

    OfficialResults? officialResultsToPersist;
    final fullPlacements = officialPlacementsFromStandings(standings);
    if (fullPlacements != null &&
        shouldAutoUpdateGroupPlacements(officialResults.updatedBy)) {
      officialResultsToPersist = officialResults.copyWith(
        groupPlacements: fullPlacements,
        advancingCountryIds: fullPlacements.advancingCountryIds,
        updatedAt: updatedAt,
        updatedBy: 'leaderboard-recalc',
      );
    }

    return TournamentReconciliationResult(
      standings: standings,
      officialResultsForScoring: scoringResults,
      officialResultsToPersist: officialResultsToPersist,
    );
  }
}
