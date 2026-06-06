import 'models.dart';
import 'third_place_mapping.dart';

class BracketSlot {
  const BracketSlot({
    required this.id,
    required this.stage,
    required this.label,
    required this.sourceA,
    required this.sourceB,
  });

  final String id;
  final TournamentStage stage;
  final String label;
  final String sourceA;
  final String sourceB;
}

class BracketRules {
  static const groupIds = [
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
  ];

  static const roundOf32Slots = [
    BracketSlot(
      id: 'm73',
      stage: TournamentStage.roundOf32,
      label: 'Match 73',
      sourceA: '2A',
      sourceB: '2B',
    ),
    BracketSlot(
      id: 'm76',
      stage: TournamentStage.roundOf32,
      label: 'Match 76',
      sourceA: '1C',
      sourceB: '2F',
    ),
    BracketSlot(
      id: 'm74',
      stage: TournamentStage.roundOf32,
      label: 'Match 74',
      sourceA: '1E',
      sourceB: '3rd A/B/C/D/F',
    ),
    BracketSlot(
      id: 'm75',
      stage: TournamentStage.roundOf32,
      label: 'Match 75',
      sourceA: '1F',
      sourceB: '2C',
    ),
    BracketSlot(
      id: 'm78',
      stage: TournamentStage.roundOf32,
      label: 'Match 78',
      sourceA: '2E',
      sourceB: '2I',
    ),
    BracketSlot(
      id: 'm77',
      stage: TournamentStage.roundOf32,
      label: 'Match 77',
      sourceA: '1I',
      sourceB: '3rd C/D/F/G/H',
    ),
    BracketSlot(
      id: 'm79',
      stage: TournamentStage.roundOf32,
      label: 'Match 79',
      sourceA: '1A',
      sourceB: '3rd C/E/F/H/I',
    ),
    BracketSlot(
      id: 'm80',
      stage: TournamentStage.roundOf32,
      label: 'Match 80',
      sourceA: '1L',
      sourceB: '3rd E/H/I/J/K',
    ),
    BracketSlot(
      id: 'm82',
      stage: TournamentStage.roundOf32,
      label: 'Match 82',
      sourceA: '1G',
      sourceB: '3rd A/E/H/I/J',
    ),
    BracketSlot(
      id: 'm81',
      stage: TournamentStage.roundOf32,
      label: 'Match 81',
      sourceA: '1D',
      sourceB: '3rd B/E/F/I/J',
    ),
    BracketSlot(
      id: 'm84',
      stage: TournamentStage.roundOf32,
      label: 'Match 84',
      sourceA: '1H',
      sourceB: '2J',
    ),
    BracketSlot(
      id: 'm83',
      stage: TournamentStage.roundOf32,
      label: 'Match 83',
      sourceA: '2K',
      sourceB: '2L',
    ),
    BracketSlot(
      id: 'm85',
      stage: TournamentStage.roundOf32,
      label: 'Match 85',
      sourceA: '1B',
      sourceB: '3rd E/F/G/I/J',
    ),
    BracketSlot(
      id: 'm88',
      stage: TournamentStage.roundOf32,
      label: 'Match 88',
      sourceA: '2D',
      sourceB: '2G',
    ),
    BracketSlot(
      id: 'm86',
      stage: TournamentStage.roundOf32,
      label: 'Match 86',
      sourceA: '1J',
      sourceB: '2H',
    ),
    BracketSlot(
      id: 'm87',
      stage: TournamentStage.roundOf32,
      label: 'Match 87',
      sourceA: '1K',
      sourceB: '3rd D/E/I/J/L',
    ),
  ];

  static const laterRoundSlots = [
    BracketSlot(
      id: 'm89',
      stage: TournamentStage.roundOf16,
      label: 'Match 89',
      sourceA: 'W74',
      sourceB: 'W77',
    ),
    BracketSlot(
      id: 'm90',
      stage: TournamentStage.roundOf16,
      label: 'Match 90',
      sourceA: 'W73',
      sourceB: 'W75',
    ),
    BracketSlot(
      id: 'm91',
      stage: TournamentStage.roundOf16,
      label: 'Match 91',
      sourceA: 'W76',
      sourceB: 'W78',
    ),
    BracketSlot(
      id: 'm92',
      stage: TournamentStage.roundOf16,
      label: 'Match 92',
      sourceA: 'W79',
      sourceB: 'W80',
    ),
    BracketSlot(
      id: 'm93',
      stage: TournamentStage.roundOf16,
      label: 'Match 93',
      sourceA: 'W83',
      sourceB: 'W84',
    ),
    BracketSlot(
      id: 'm94',
      stage: TournamentStage.roundOf16,
      label: 'Match 94',
      sourceA: 'W81',
      sourceB: 'W82',
    ),
    BracketSlot(
      id: 'm95',
      stage: TournamentStage.roundOf16,
      label: 'Match 95',
      sourceA: 'W86',
      sourceB: 'W88',
    ),
    BracketSlot(
      id: 'm96',
      stage: TournamentStage.roundOf16,
      label: 'Match 96',
      sourceA: 'W85',
      sourceB: 'W87',
    ),
    BracketSlot(
      id: 'm97',
      stage: TournamentStage.quarterfinal,
      label: 'Match 97',
      sourceA: 'W89',
      sourceB: 'W90',
    ),
    BracketSlot(
      id: 'm98',
      stage: TournamentStage.quarterfinal,
      label: 'Match 98',
      sourceA: 'W93',
      sourceB: 'W94',
    ),
    BracketSlot(
      id: 'm99',
      stage: TournamentStage.quarterfinal,
      label: 'Match 99',
      sourceA: 'W91',
      sourceB: 'W92',
    ),
    BracketSlot(
      id: 'm100',
      stage: TournamentStage.quarterfinal,
      label: 'Match 100',
      sourceA: 'W95',
      sourceB: 'W96',
    ),
    BracketSlot(
      id: 'm101',
      stage: TournamentStage.semifinal,
      label: 'Match 101',
      sourceA: 'W97',
      sourceB: 'W98',
    ),
    BracketSlot(
      id: 'm102',
      stage: TournamentStage.semifinal,
      label: 'Match 102',
      sourceA: 'W99',
      sourceB: 'W100',
    ),
    BracketSlot(
      id: 'm104',
      stage: TournamentStage.finalMatch,
      label: 'Final',
      sourceA: 'W101',
      sourceB: 'W102',
    ),
  ];

  static List<BracketSlot> knockoutSlots() => [
    ...roundOf32Slots,
    ...laterRoundSlots,
  ];

  static bool hasCompleteGroupPicks(Bracket bracket) {
    final picksByGroup = {
      for (final pick in bracket.groupPicks) pick.groupId: pick,
    };
    return groupIds.every((groupId) {
      final pick = picksByGroup[groupId];
      if (pick == null ||
          pick.firstCountryId.isEmpty ||
          pick.secondCountryId.isEmpty ||
          pick.thirdCountryId == null ||
          pick.thirdCountryId!.isEmpty) {
        return false;
      }
      return {
            pick.firstCountryId,
            pick.secondCountryId,
            pick.thirdCountryId,
          }.length ==
          3;
    });
  }

  static bool hasCompleteBestThirdPicks(Bracket bracket) {
    final selectedGroups = bracket.bestThirdGroupIds.toSet();
    if (selectedGroups.length != 8) {
      return false;
    }
    final groupsWithThirds = {
      for (final pick in bracket.groupPicks)
        if (pick.thirdCountryId != null && pick.thirdCountryId!.isNotEmpty)
          pick.groupId,
    };
    return selectedGroups.every(groupsWithThirds.contains);
  }

  static bool hasCompleteKnockoutPicks(Bracket bracket) {
    final pickedSlots =
        bracket.knockoutPicks.map((pick) => pick.slotId).toSet();
    return knockoutSlots().every((slot) => pickedSlots.contains(slot.id));
  }

  static bool canSubmit(Bracket bracket, GlobalContestConfig config) {
    return config.isAcceptingSubmissions &&
        !config.isLocked &&
        hasCompleteGroupPicks(bracket) &&
        hasCompleteBestThirdPicks(bracket) &&
        hasCompleteKnockoutPicks(bracket);
  }

  static String? resolveSourceCountryId(Bracket bracket, String source) {
    final groupPosition = _groupPositionPattern.firstMatch(source);
    if (groupPosition != null) {
      return _resolveGroupPosition(
        bracket,
        int.parse(groupPosition.group(1)!),
        groupPosition.group(2)!,
      );
    }

    if (source.startsWith('3rd ')) {
      return null;
    }

    final winningSlot = _winningSlotPattern.firstMatch(source);
    if (winningSlot != null) {
      final slotId = 'm${winningSlot.group(1)!}';
      return bracket.knockoutPicks
          .where((pick) => pick.slotId == slotId)
          .map((pick) => pick.winnerCountryId)
          .firstOrNull;
    }

    return null;
  }

  static String? resolvedThirdPlaceSource(
    Bracket bracket,
    BracketSlot roundOf32Slot,
  ) {
    if (!roundOf32Slot.sourceB.startsWith('3rd ')) {
      return null;
    }
    final winnerSource = roundOf32Slot.sourceA;
    final assignments = thirdPlaceAssignments(bracket);
    return assignments[winnerSource];
  }

  static Map<String, String> thirdPlaceAssignments(Bracket bracket) {
    final key = thirdPlaceCombinationKey(bracket);
    if (key == null) {
      return const {};
    }
    return thirdPlaceSlotMapping[key] ?? const {};
  }

  static String? thirdPlaceCombinationKey(Bracket bracket) {
    final groupIds = bracket.bestThirdGroupIds.toSet();
    if (groupIds.length != 8) {
      return null;
    }
    final sorted = groupIds.toList()..sort();
    return sorted.join();
  }

  static Set<String> predictedAdvancingCountryIds(Bracket bracket) {
    final bestThirdGroups = bracket.bestThirdGroupIds.toSet();
    return {
      for (final pick in bracket.groupPicks) pick.firstCountryId,
      for (final pick in bracket.groupPicks) pick.secondCountryId,
      for (final pick in bracket.groupPicks)
        if (bestThirdGroups.contains(pick.groupId) &&
            pick.thirdCountryId != null &&
            pick.thirdCountryId!.isNotEmpty)
          pick.thirdCountryId!,
    };
  }

  static String? _resolveGroupPosition(
    Bracket bracket,
    int position,
    String groupId,
  ) {
    final pick =
        bracket.groupPicks.where((pick) => pick.groupId == groupId).firstOrNull;
    if (pick == null) {
      return null;
    }
    switch (position) {
      case 1:
        return pick.firstCountryId;
      case 2:
        return pick.secondCountryId;
      case 3:
        return pick.thirdCountryId;
      default:
        return null;
    }
  }

  static final _groupPositionPattern = RegExp(r'^([123])([A-L])$');
  static final _winningSlotPattern = RegExp(r'^W(\d+)$');
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
