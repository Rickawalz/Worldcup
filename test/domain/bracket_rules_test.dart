import 'package:flutter_test/flutter_test.dart';
import 'package:world_cup_bracket/src/domain/bracket_rules.dart';
import 'package:world_cup_bracket/src/domain/models.dart';

void main() {
  group('BracketRules', () {
    test('models the full knockout bracket through the final', () {
      final slots = BracketRules.knockoutSlots();

      expect(
        slots.where((slot) => slot.stage == TournamentStage.roundOf32),
        hasLength(16),
      );
      expect(
        slots.where((slot) => slot.stage == TournamentStage.roundOf16),
        hasLength(8),
      );
      expect(
        slots.where((slot) => slot.stage == TournamentStage.quarterfinal),
        hasLength(4),
      );
      expect(
        slots.where((slot) => slot.stage == TournamentStage.semifinal),
        hasLength(2),
      );
      expect(
        slots.where((slot) => slot.stage == TournamentStage.finalMatch),
        hasLength(1),
      );
      expect(slots.last.id, 'm104');
    });

    test('models official FIFA 2026 group membership', () {
      expect(BracketRules.groupCountryIds['A'], [
        'mexico',
        'south_africa',
        'south_korea',
        'czech_republic',
      ]);
      expect(BracketRules.groupCountryIds['L'], [
        'england',
        'croatia',
        'ghana',
        'panama',
      ]);
      expect(BracketRules.officialCountryIds, hasLength(48));
      expect(BracketRules.officialCountryIds.toSet(), hasLength(48));
    });

    test(
      'requires top three groups, best thirds, and knockouts before submit',
      () {
        final completeBracket = Bracket.empty('user').copyWith(
          groupPicks: [
            for (final groupId in BracketRules.groupIds)
              GroupPick(
                groupId: groupId,
                firstCountryId: '${groupId}_1',
                secondCountryId: '${groupId}_2',
                thirdCountryId: '${groupId}_3',
              ),
          ],
          bestThirdGroupIds: BracketRules.groupIds.take(8).toList(),
          knockoutPicks: [
            for (final slot in BracketRules.knockoutSlots())
              KnockoutPick(
                slotId: slot.id,
                stage: slot.stage,
                winnerCountryId: 'usa',
              ),
          ],
        );
        final config = GlobalContestConfig(
          lockAt: DateTime.now().add(const Duration(days: 1)),
        );

        expect(BracketRules.canSubmit(completeBracket, config), isTrue);
        expect(
          BracketRules.canSubmit(
            completeBracket.copyWith(knockoutPicks: const []),
            config,
          ),
          isFalse,
        );
        expect(
          BracketRules.canSubmit(
            completeBracket.copyWith(bestThirdGroupIds: const ['A']),
            config,
          ),
          isFalse,
        );
        expect(
          BracketRules.canSubmit(
            completeBracket.copyWith(
              groupPicks: [
                for (final groupId in BracketRules.groupIds)
                  GroupPick(
                    groupId: groupId,
                    firstCountryId: '${groupId}_1',
                    secondCountryId: '${groupId}_2',
                  ),
              ],
            ),
            config,
          ),
          isFalse,
        );
        expect(
          BracketRules.canSubmit(
            completeBracket.copyWith(status: BracketStatus.submitted),
            config,
          ),
          isTrue,
        );
      },
    );

    test('resolves third-place teams from the FIFA Annexe C mapping', () {
      final bracket = Bracket.empty('user').copyWith(
        groupPicks: [
          for (final groupId in BracketRules.groupIds)
            GroupPick(
              groupId: groupId,
              firstCountryId: '${groupId}_1',
              secondCountryId: '${groupId}_2',
              thirdCountryId: '${groupId}_3',
            ),
        ],
        bestThirdGroupIds: const ['C', 'D', 'E', 'F', 'G', 'I', 'K', 'L'],
      );
      final match79 = BracketRules.roundOf32Slots.firstWhere(
        (slot) => slot.id == 'm79',
      );

      expect(BracketRules.thirdPlaceCombinationKey(bracket), 'CDEFGIKL');
      expect(BracketRules.resolvedThirdPlaceSource(bracket, match79), '3C');
      expect(BracketRules.resolveSourceCountryId(bracket, '3C'), 'C_3');
    });

    test('resolves knockout dropdown participants from predicted path', () {
      final bracket = Bracket.empty('user').copyWith(
        groupPicks: [
          for (final groupId in BracketRules.groupIds)
            GroupPick(
              groupId: groupId,
              firstCountryId: '${groupId}_1',
              secondCountryId: '${groupId}_2',
              thirdCountryId: '${groupId}_3',
            ),
        ],
        bestThirdGroupIds: const ['C', 'D', 'E', 'F', 'G', 'I', 'K', 'L'],
        knockoutPicks: const [
          KnockoutPick(
            slotId: 'm73',
            stage: TournamentStage.roundOf32,
            winnerCountryId: 'A_2',
          ),
          KnockoutPick(
            slotId: 'm75',
            stage: TournamentStage.roundOf32,
            winnerCountryId: 'F_1',
          ),
        ],
      );
      final match73 = BracketRules.knockoutSlots().firstWhere(
        (slot) => slot.id == 'm73',
      );
      final match90 = BracketRules.knockoutSlots().firstWhere(
        (slot) => slot.id == 'm90',
      );

      expect(BracketRules.resolveSlotParticipantIds(bracket, match73), [
        'A_2',
        'B_2',
      ]);
      expect(BracketRules.resolveSlotParticipantIds(bracket, match90), [
        'A_2',
        'F_1',
      ]);
    });
  });
}
