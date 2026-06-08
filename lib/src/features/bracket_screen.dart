import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../data/providers.dart';
import '../domain/bracket_rules.dart';
import '../domain/models.dart';
import 'bracket_pdf/bracket_pdf_builder.dart';
import '../localization/app_strings.dart';
import '../localization/country_names.dart';
import '../widgets/country_badge.dart';
import '../widgets/dashboard.dart';

class BracketScreen extends ConsumerWidget {
  const BracketScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countries = ref.watch(countriesProvider);
    final bracket = ref.watch(myBracketProvider);
    final config = ref.watch(contestConfigProvider);
    final user = ref.watch(currentUserProvider);

    return countries.when(
      data:
          (countryList) => bracket.when(
            data:
                (bracketValue) => config.when(
                  data: (configValue) {
                    final fixtures =
                        ref.watch(fixturesProvider).value ?? const [];
                    final groupContent = Column(
                      children: [
                        _GroupPicks(countries: countryList),
                        _BestThirdPicks(countries: countryList),
                      ],
                    );
                    final wallchart = _KnockoutWallchart(
                      countries: countryList,
                      bracket: bracketValue,
                      fixtures: fixtures,
                    );
                    final fallbackEditor = _KnockoutPicks(
                      countries: countryList,
                      bracket: bracketValue,
                      fixtures: fixtures,
                    );

                    final completedPicks =
                        _completedGroupPickCount(bracketValue) +
                        (BracketRules.hasCompleteBestThirdPicks(bracketValue)
                            ? 1
                            : 0) +
                        bracketValue.knockoutPicks.length;
                    final totalPicks =
                        BracketRules.groupIds.length +
                        1 +
                        BracketRules.knockoutSlots().length;

                    return DashboardPage(
                      title: context.strings.yourGlobalBracket,
                      subtitle:
                          configValue.isLocked
                              ? context.strings.bracketReadOnly
                              : bracketValue.status == BracketStatus.submitted
                              ? context.strings.bracketSubmitted
                              : context.strings.autosaveEnabled,
                      icon: Icons.account_tree_outlined,
                      stats: [
                        DashboardStat(
                          label: 'complete',
                          value: '$completedPicks/$totalPicks',
                          icon: Icons.check_circle_outline,
                        ),
                        DashboardStat(
                          label: bracketValue.status.name,
                          value: 'Status',
                          icon: Icons.shield_outlined,
                          color: DashboardColors.sky,
                        ),
                      ],
                      children: [
                        _BracketHeader(
                          bracket: bracketValue,
                          config: configValue,
                        ),
                        const SizedBox(height: 8),
                        ProviderScope(
                          overrides: [
                            _editableBracketProvider.overrideWithValue(
                              bracketValue,
                            ),
                            _availableCountriesProvider.overrideWithValue(
                              countryList,
                            ),
                            _isBracketLockedProvider.overrideWithValue(
                              configValue.isLocked,
                            ),
                          ],
                          child: Column(
                            children: [
                              const _SaveStatusLine(),
                              const SizedBox(height: 16),
                              groupContent,
                              const SizedBox(height: 16),
                              wallchart,
                              const SizedBox(height: 16),
                              const _FallbackEditorNote(),
                              const SizedBox(height: 16),
                              fallbackEditor,
                              const SizedBox(height: 16),
                              _SubmitBar(
                                bracket: bracketValue,
                                config: configValue,
                                countries: countryList,
                                username:
                                    user.valueOrNull?.username ?? 'My bracket',
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                  loading:
                      () => const Center(child: CircularProgressIndicator()),
                  error:
                      (error, _) =>
                          Center(child: Text('Contest error: $error')),
                ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Bracket error: $error')),
          ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Country error: $error')),
    );
  }
}

final _editableBracketProvider = Provider<Bracket>(
  (_) => throw UnimplementedError(),
);
final _availableCountriesProvider = Provider<List<Country>>(
  (_) => throw UnimplementedError(),
);
final _isBracketLockedProvider = Provider<bool>((_) => false);
final _bracketSaveStatusProvider = StateProvider<_BracketSaveStatus>(
  (_) => const _BracketSaveStatus.idle(),
);

enum _BracketSaveStatusKind { idle, saving, saved, failed }

class _BracketSaveStatus {
  const _BracketSaveStatus._(this.kind, {this.savedAt, this.error});

  const _BracketSaveStatus.idle() : this._(_BracketSaveStatusKind.idle);
  const _BracketSaveStatus.saving() : this._(_BracketSaveStatusKind.saving);
  const _BracketSaveStatus.saved(DateTime savedAt)
    : this._(_BracketSaveStatusKind.saved, savedAt: savedAt);
  const _BracketSaveStatus.failed(Object error)
    : this._(_BracketSaveStatusKind.failed, error: error);

  final _BracketSaveStatusKind kind;
  final DateTime? savedAt;
  final Object? error;
}

int _completedGroupPickCount(Bracket bracket) {
  return bracket.groupPicks.where((pick) {
    final third = pick.thirdCountryId;
    return pick.firstCountryId.isNotEmpty &&
        pick.secondCountryId.isNotEmpty &&
        third != null &&
        third.isNotEmpty &&
        {pick.firstCountryId, pick.secondCountryId, third}.length == 3;
  }).length;
}

class _BracketHeader extends StatelessWidget {
  const _BracketHeader({required this.bracket, required this.config});

  final Bracket bracket;
  final GlobalContestConfig config;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.strings.yourGlobalBracket,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              config.isLocked
                  ? context.strings.bracketReadOnly
                  : bracket.status == BracketStatus.submitted
                  ? context.strings.bracketSubmitted
                  : context.strings.autosaveEnabled,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value:
                  (_completedGroupPickCount(bracket) +
                      (BracketRules.hasCompleteBestThirdPicks(bracket)
                          ? 1
                          : 0) +
                      bracket.knockoutPicks.length) /
                  (BracketRules.groupIds.length +
                      1 +
                      BracketRules.knockoutSlots().length),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaveStatusLine extends ConsumerWidget {
  const _SaveStatusLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(_bracketSaveStatusProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final (icon, text, color) = switch (status.kind) {
      _BracketSaveStatusKind.idle => (
        Icons.cloud_done_outlined,
        'Autosave on',
        colorScheme.onSurfaceVariant,
      ),
      _BracketSaveStatusKind.saving => (
        Icons.sync,
        'Saving...',
        colorScheme.primary,
      ),
      _BracketSaveStatusKind.saved => (
        Icons.check_circle_outline,
        'Saved just now',
        colorScheme.primary,
      ),
      _BracketSaveStatusKind.failed => (
        Icons.error_outline,
        'Save failed: ${status.error}',
        colorScheme.error,
      ),
    };
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

Future<void> _autosaveBracket(WidgetRef ref, Bracket bracket) async {
  ref.read(_bracketSaveStatusProvider.notifier).state =
      const _BracketSaveStatus.saving();
  try {
    await ref.read(appRepositoryProvider).saveBracket(bracket);
    ref
        .read(_bracketSaveStatusProvider.notifier)
        .state = _BracketSaveStatus.saved(DateTime.now());
  } catch (error) {
    ref
        .read(_bracketSaveStatusProvider.notifier)
        .state = _BracketSaveStatus.failed(error);
  }
}

class _GroupPicks extends ConsumerWidget {
  const _GroupPicks({required this.countries});

  final List<Country> countries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countryById = {for (final country in countries) country.id: country};
    final groups = {
      for (final groupId in BracketRules.groupIds)
        groupId: [
          for (final countryId in BracketRules.groupCountryIds[groupId]!)
            if (countryById[countryId] != null) countryById[countryId]!,
        ],
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.strings.groupStage,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(context.strings.groupInstructions),
            const SizedBox(height: 16),
            for (final entry in groups.entries)
              _GroupPicker(groupId: entry.key, teams: entry.value),
          ],
        ),
      ),
    );
  }
}

class _GroupPicker extends ConsumerWidget {
  const _GroupPicker({required this.groupId, required this.teams});

  final String groupId;
  final List<Country> teams;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bracket = ref.watch(_editableBracketProvider);
    final isLocked = ref.watch(_isBracketLockedProvider);
    final current =
        bracket.groupPicks.where((pick) => pick.groupId == groupId).firstOrNull;
    final first = current?.firstCountryId;
    final second = current?.secondCountryId;
    final third = current?.thirdCountryId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.strings.group(groupId),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _CountryDropdown(
                label: context.strings.firstPlace,
                teams: _availableTeams(teams, first, [second, third]),
                value: first,
                onChanged:
                    isLocked
                        ? null
                        : (value) => _saveGroupPick(ref, value, second, third),
              ),
              _CountryDropdown(
                label: context.strings.secondPlace,
                teams: _availableTeams(teams, second, [first, third]),
                value: second,
                onChanged:
                    isLocked
                        ? null
                        : (value) => _saveGroupPick(ref, first, value, third),
              ),
              _CountryDropdown(
                label: context.strings.thirdPlace,
                teams: _availableTeams(teams, third, [first, second]),
                value: third,
                onChanged:
                    isLocked
                        ? null
                        : (value) => _saveGroupPick(ref, first, second, value),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _saveGroupPick(
    WidgetRef ref,
    String? firstCountryId,
    String? secondCountryId,
    String? thirdCountryId,
  ) async {
    final bracket = ref.read(_editableBracketProvider);
    final picks = [
      for (final pick in bracket.groupPicks)
        if (pick.groupId != groupId) pick,
      GroupPick(
        groupId: groupId,
        firstCountryId: firstCountryId ?? '',
        secondCountryId: secondCountryId ?? '',
        thirdCountryId: thirdCountryId,
      ),
    ];
    final bestThirdGroupIds = [
      for (final selectedGroupId in bracket.bestThirdGroupIds)
        if (selectedGroupId != groupId || thirdCountryId != null)
          selectedGroupId,
    ];
    await _autosaveBracket(
      ref,
      bracket.copyWith(groupPicks: picks, bestThirdGroupIds: bestThirdGroupIds),
    );
  }

  List<Country> _availableTeams(
    List<Country> teams,
    String? currentValue,
    List<String?> selectedElsewhere,
  ) {
    final blocked = selectedElsewhere.whereType<String>().toSet();
    return [
      for (final team in teams)
        if (team.id == currentValue || !blocked.contains(team.id)) team,
    ];
  }
}

class _BestThirdPicks extends ConsumerWidget {
  const _BestThirdPicks({required this.countries});

  final List<Country> countries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bracket = ref.watch(_editableBracketProvider);
    final isLocked = ref.watch(_isBracketLockedProvider);
    final countryById = {for (final country in countries) country.id: country};
    final selectedGroups = bracket.bestThirdGroupIds.toSet();
    final thirdPlacePicks = [
      for (final groupId in BracketRules.groupIds)
        bracket.groupPicks.where((pick) => pick.groupId == groupId).firstOrNull,
    ];
    final selectedCount = selectedGroups.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.strings.bestThirdPlaceTeams,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(context.strings.bestThirdInstructions(selectedCount)),
            const SizedBox(height: 8),
            for (final pick in thirdPlacePicks)
              _BestThirdCheckbox(
                pick: pick,
                country: countryById[pick?.thirdCountryId],
                isSelected:
                    pick != null && selectedGroups.contains(pick.groupId),
                isDisabled:
                    isLocked ||
                    pick == null ||
                    pick.thirdCountryId == null ||
                    pick.thirdCountryId!.isEmpty ||
                    (selectedCount >= 8 &&
                        !selectedGroups.contains(pick.groupId)),
                onChanged: (value) {
                  if (pick == null) {
                    return;
                  }
                  final next = selectedGroups.toSet();
                  if (value == true) {
                    next.add(pick.groupId);
                  } else {
                    next.remove(pick.groupId);
                  }
                  _autosaveBracket(
                    ref,
                    bracket.copyWith(
                      bestThirdGroupIds: (next.toList()..sort()),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _BestThirdCheckbox extends StatelessWidget {
  const _BestThirdCheckbox({
    required this.pick,
    required this.country,
    required this.isSelected,
    required this.isDisabled,
    required this.onChanged,
  });

  final GroupPick? pick;
  final Country? country;
  final bool isSelected;
  final bool isDisabled;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final groupId = pick?.groupId ?? '-';
    final title =
        country == null
            ? context.strings.groupThirdNotPicked(groupId)
            : context.strings.groupThirdPick(
              groupId,
              countryDisplayName(context, country!),
            );
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      value: isSelected,
      onChanged: isDisabled ? null : onChanged,
      title: Text(title),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}

class _KnockoutWallchart extends ConsumerWidget {
  const _KnockoutWallchart({
    required this.countries,
    required this.bracket,
    required this.fixtures,
  });

  final List<Country> countries;
  final Bracket bracket;
  final List<Fixture> fixtures;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slots = BracketRules.knockoutSlots();
    final roundOf32 =
        slots.where((slot) => slot.stage == TournamentStage.roundOf32).toList();
    final roundOf16 =
        slots.where((slot) => slot.stage == TournamentStage.roundOf16).toList();
    final quarterfinals =
        slots
            .where((slot) => slot.stage == TournamentStage.quarterfinal)
            .toList();
    final semifinals =
        slots.where((slot) => slot.stage == TournamentStage.semifinal).toList();
    final finalSlot = slots.firstWhere(
      (slot) => slot.stage == TournamentStage.finalMatch,
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF102A3D), Color(0xFF0A4A32), Color(0xFF06131D)],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _WallchartPainter())),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(18),
              child: SizedBox(
                width: 1280,
                child: Column(
                  children: [
                    Text(
                      'World Cup Wallchart 2026',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _WallchartRoundColumn(
                          title: context.strings.roundOf32,
                          color: const Color(0xFF4057A8),
                          slots: roundOf32.take(8).toList(),
                          countries: countries,
                          bracket: bracket,
                          fixtures: fixtures,
                        ),
                        _WallchartRoundColumn(
                          title: context.strings.roundOf16,
                          color: const Color(0xFF61B34A),
                          slots: roundOf16.take(4).toList(),
                          countries: countries,
                          bracket: bracket,
                          fixtures: fixtures,
                        ),
                        _WallchartRoundColumn(
                          title: context.strings.quarterfinals,
                          color: const Color(0xFFE05D3F),
                          slots: quarterfinals.take(2).toList(),
                          countries: countries,
                          bracket: bracket,
                          fixtures: fixtures,
                        ),
                        _WallchartRoundColumn(
                          title: context.strings.semifinals,
                          color: const Color(0xFF6F6681),
                          slots: semifinals.take(1).toList(),
                          countries: countries,
                          bracket: bracket,
                          fixtures: fixtures,
                        ),
                        _WallchartCenterPanel(
                          finalSlot: finalSlot,
                          bronzeSlot: null,
                          countries: countries,
                          bracket: bracket,
                          fixtures: fixtures,
                        ),
                        _WallchartRoundColumn(
                          title: context.strings.semifinals,
                          color: const Color(0xFF6F6681),
                          slots: semifinals.skip(1).toList(),
                          countries: countries,
                          bracket: bracket,
                          fixtures: fixtures,
                        ),
                        _WallchartRoundColumn(
                          title: context.strings.quarterfinals,
                          color: const Color(0xFFE05D3F),
                          slots: quarterfinals.skip(2).toList(),
                          countries: countries,
                          bracket: bracket,
                          fixtures: fixtures,
                        ),
                        _WallchartRoundColumn(
                          title: context.strings.roundOf16,
                          color: const Color(0xFF61B34A),
                          slots: roundOf16.skip(4).toList(),
                          countries: countries,
                          bracket: bracket,
                          fixtures: fixtures,
                        ),
                        _WallchartRoundColumn(
                          title: context.strings.roundOf32,
                          color: const Color(0xFF4057A8),
                          slots: roundOf32.skip(8).toList(),
                          countries: countries,
                          bracket: bracket,
                          fixtures: fixtures,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tap any match box to pick or change the winner.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WallchartRoundColumn extends StatelessWidget {
  const _WallchartRoundColumn({
    required this.title,
    required this.color,
    required this.slots,
    required this.countries,
    required this.bracket,
    required this.fixtures,
  });

  final String title;
  final Color color;
  final List<BracketSlot> slots;
  final List<Country> countries;
  final Bracket bracket;
  final List<Fixture> fixtures;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 128,
      child: Column(
        children: [
          Text(
            title.toUpperCase(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          for (final slot in slots) ...[
            _WallchartMatchCard(
              slot: slot,
              color: color,
              countries: countries,
              bracket: bracket,
              fixtures: fixtures,
            ),
            SizedBox(height: slot.stage == TournamentStage.roundOf32 ? 10 : 26),
          ],
        ],
      ),
    );
  }
}

class _WallchartCenterPanel extends StatelessWidget {
  const _WallchartCenterPanel({
    required this.finalSlot,
    required this.bronzeSlot,
    required this.countries,
    required this.bracket,
    required this.fixtures,
  });

  final BracketSlot finalSlot;
  final BracketSlot? bronzeSlot;
  final List<Country> countries;
  final Bracket bracket;
  final List<Fixture> fixtures;

  @override
  Widget build(BuildContext context) {
    final champion = _countryById(countries)[bracket.championCountryId];
    return SizedBox(
      width: 250,
      child: Column(
        children: [
          Icon(
            Icons.emoji_events,
            size: 86,
            color: DashboardColors.gold.withValues(alpha: 0.92),
          ),
          Text(
            context.strings.finalRound.toUpperCase(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: DashboardColors.gold,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          _WallchartMatchCard(
            slot: finalSlot,
            color: DashboardColors.gold,
            countries: countries,
            bracket: bracket,
            fixtures: fixtures,
            isCenterpiece: true,
          ),
          const SizedBox(height: 18),
          Container(
            width: 190,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: DashboardColors.gold.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: DashboardColors.gold),
            ),
            child: Column(
              children: [
                Text(
                  context.strings.winner.toUpperCase(),
                  style: const TextStyle(
                    color: DashboardColors.gold,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                champion == null
                    ? const Text('TBD')
                    : CountryBadge(country: champion, compact: true),
              ],
            ),
          ),
          if (bronzeSlot != null) ...[
            const SizedBox(height: 18),
            Text(
              'Bronze Final'.toUpperCase(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _WallchartMatchCard(
              slot: bronzeSlot!,
              color: const Color(0xFFB9824A),
              countries: countries,
              bracket: bracket,
              fixtures: fixtures,
            ),
          ],
        ],
      ),
    );
  }
}

class _WallchartMatchCard extends ConsumerWidget {
  const _WallchartMatchCard({
    required this.slot,
    required this.color,
    required this.countries,
    required this.bracket,
    required this.fixtures,
    this.isCenterpiece = false,
  });

  final BracketSlot slot;
  final Color color;
  final List<Country> countries;
  final Bracket bracket;
  final List<Fixture> fixtures;
  final bool isCenterpiece;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLocked = ref.watch(_isBracketLockedProvider);
    final countryById = _countryById(countries);
    final fixture =
        fixtures.where((fixture) => fixture.id == slot.id).firstOrNull;
    final current =
        bracket.knockoutPicks
            .where((pick) => pick.slotId == slot.id)
            .firstOrNull;
    final participantIds = BracketRules.resolveSlotParticipantIds(
      bracket,
      slot,
    );
    final sourceA = _wallchartSourceText(
      context,
      bracket,
      countryById,
      slot,
      slot.sourceA,
    );
    final sourceB = _wallchartSourceText(
      context,
      bracket,
      countryById,
      slot,
      slot.sourceB,
    );
    final winner = countryById[current?.winnerCountryId];
    final canPick = !isLocked && participantIds.length >= 2;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap:
          canPick
              ? () => _showWallchartPicker(
                context,
                ref,
                slot,
                participantIds,
                countries,
                bracket,
              )
              : null,
      child: Container(
        width: isCenterpiece ? 210 : 118,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.9), width: 1.4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    slot.label,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Icon(
                  canPick ? Icons.touch_app_outlined : Icons.lock_outline,
                  size: 13,
                  color: Colors.white70,
                ),
              ],
            ),
            const SizedBox(height: 6),
            _WallchartTeamLine(text: sourceA),
            const SizedBox(height: 4),
            _WallchartTeamLine(text: sourceB),
            const SizedBox(height: 7),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child:
                  winner == null
                      ? Text(
                        context.strings.winner,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall,
                      )
                      : CountryBadge(country: winner, compact: true),
            ),
            if (fixture != null) ...[
              const SizedBox(height: 5),
              Text(
                _wallchartFixtureMetadata(fixture),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white70,
                  fontSize: 9,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WallchartTeamLine extends StatelessWidget {
  const _WallchartTeamLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF0B1824),
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _FallbackEditorNote extends StatelessWidget {
  const _FallbackEditorNote();

  @override
  Widget build(BuildContext context) {
    return DashboardSectionCard(
      child: Row(
        children: [
          const Icon(Icons.edit_note, color: DashboardColors.gold),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Wallchart picks autosave when you tap a match. The detailed editor below remains available as a fallback.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _WallchartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.11)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
    final glowPaint =
        Paint()
          ..color = DashboardColors.gold.withValues(alpha: 0.08)
          ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.42),
        width: 520,
        height: 170,
      ),
      glowPaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.62),
      Offset(size.width, size.height * 0.62),
      linePaint,
    );
    canvas.drawCircle(
      Offset(size.width / 2, size.height * 0.62),
      88,
      linePaint,
    );
    for (var i = 0; i < 7; i++) {
      final y = size.height * (0.18 + i * 0.08);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Future<void> _showWallchartPicker(
  BuildContext context,
  WidgetRef ref,
  BracketSlot slot,
  List<String> participantIds,
  List<Country> countries,
  Bracket bracket,
) async {
  final countryById = _countryById(countries);
  final teams = [
    for (final countryId in participantIds)
      if (countryById[countryId] != null) countryById[countryId]!,
  ];
  if (teams.length < 2) return;

  final selected = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder:
        (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${slot.label}: pick winner',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                for (final team in teams)
                  ListTile(
                    leading: CountryBadge(country: team, compact: true),
                    title: Text(countryDisplayName(context, team)),
                    onTap: () => Navigator.of(context).pop(team.id),
                  ),
              ],
            ),
          ),
        ),
  );
  if (selected == null) return;

  final picks = [
    for (final pick in bracket.knockoutPicks)
      if (pick.slotId != slot.id) pick,
    KnockoutPick(slotId: slot.id, stage: slot.stage, winnerCountryId: selected),
  ];
  await _autosaveBracket(ref, bracket.copyWith(knockoutPicks: picks));
}

Map<String, Country> _countryById(List<Country> countries) {
  return {for (final country in countries) country.id: country};
}

String _wallchartSourceText(
  BuildContext context,
  Bracket bracket,
  Map<String, Country> countryById,
  BracketSlot slot,
  String source,
) {
  var effectiveSource = source;
  if (source.startsWith('3rd ')) {
    effectiveSource =
        BracketRules.resolvedThirdPlaceSource(bracket, slot) ?? source;
  }
  final countryId = BracketRules.resolveSourceCountryId(
    bracket,
    effectiveSource,
  );
  final country = countryById[countryId];
  if (country == null) return effectiveSource;
  return country.abbreviation;
}

String _wallchartFixtureMetadata(Fixture fixture) {
  final kickoff = DateFormat.MMMd().add_jm().format(fixture.kickoff.toLocal());
  final venue = fixture.venueLabel;
  if (venue == null) return kickoff;
  return '$kickoff\n$venue';
}

class _KnockoutPicks extends ConsumerWidget {
  const _KnockoutPicks({
    required this.countries,
    required this.bracket,
    required this.fixtures,
  });

  final List<Country> countries;
  final Bracket bracket;
  final List<Fixture> fixtures;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slots = BracketRules.knockoutSlots();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.strings.knockoutBracket,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(context.strings.knockoutInstructions),
            const SizedBox(height: 16),
            for (final stage in TournamentStage.values.where(
              (stage) =>
                  stage != TournamentStage.group &&
                  slots.any((slot) => slot.stage == stage),
            ))
              _StagePicker(
                stage: stage,
                slots: slots.where((slot) => slot.stage == stage).toList(),
                countries: countries,
                fixtures: fixtures,
              ),
          ],
        ),
      ),
    );
  }
}

class _StagePicker extends StatelessWidget {
  const _StagePicker({
    required this.stage,
    required this.slots,
    required this.countries,
    required this.fixtures,
  });

  final TournamentStage stage;
  final List<BracketSlot> slots;
  final List<Country> countries;
  final List<Fixture> fixtures;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded:
          stage == TournamentStage.roundOf32 ||
          stage == TournamentStage.finalMatch,
      title: Text(_stageTitle(context, stage)),
      children: [
        for (final slot in slots)
          _KnockoutSlotPicker(
            slot: slot,
            countries: countries,
            fixtures: fixtures,
          ),
      ],
    );
  }

  String _stageTitle(BuildContext context, TournamentStage stage) {
    final strings = context.strings;
    switch (stage) {
      case TournamentStage.group:
        return strings.groupStage;
      case TournamentStage.roundOf32:
        return strings.roundOf32;
      case TournamentStage.roundOf16:
        return strings.roundOf16;
      case TournamentStage.quarterfinal:
        return strings.quarterfinals;
      case TournamentStage.semifinal:
        return strings.semifinals;
      case TournamentStage.thirdPlace:
        return 'Third place';
      case TournamentStage.finalMatch:
        return strings.finalRound;
    }
  }
}

class _KnockoutSlotPicker extends ConsumerWidget {
  const _KnockoutSlotPicker({
    required this.slot,
    required this.countries,
    required this.fixtures,
  });

  final BracketSlot slot;
  final List<Country> countries;
  final List<Fixture> fixtures;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bracket = ref.watch(_editableBracketProvider);
    final isLocked = ref.watch(_isBracketLockedProvider);
    final countryById = {for (final country in countries) country.id: country};
    final current =
        bracket.knockoutPicks
            .where((pick) => pick.slotId == slot.id)
            .firstOrNull;
    final fixture =
        fixtures.where((fixture) => fixture.id == slot.id).firstOrNull;
    final didNotMakeMatch =
        current != null && _didNotMakeMatch(current.winnerCountryId, fixture);
    final participantIds = BracketRules.resolveSlotParticipantIds(
      bracket,
      slot,
    );
    final participantTeams = [
      for (final countryId in participantIds)
        if (countryById[countryId] != null) countryById[countryId]!,
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${slot.label}: '
            '${_sourceText(context, bracket, countryById, slot.sourceA)} '
            '${context.strings.vs} '
            '${_sourceText(context, bracket, countryById, slot.sourceB)}',
          ),
          if (fixture != null) ...[
            const SizedBox(height: 4),
            Text(
              _fixtureMetadata(fixture),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 8),
          _CountryDropdown(
            label: context.strings.winner,
            teams: participantTeams,
            value: current?.winnerCountryId,
            onChanged:
                isLocked || participantTeams.length < 2
                    ? null
                    : (countryId) async {
                      if (countryId == null) {
                        return;
                      }
                      final picks = [
                        for (final pick in bracket.knockoutPicks)
                          if (pick.slotId != slot.id) pick,
                        KnockoutPick(
                          slotId: slot.id,
                          stage: slot.stage,
                          winnerCountryId: countryId,
                        ),
                      ];
                      await _autosaveBracket(
                        ref,
                        bracket.copyWith(knockoutPicks: picks),
                      );
                    },
          ),
          if (didNotMakeMatch) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.close, color: Theme.of(context).colorScheme.error),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    context.strings.pickDidNotMakeMatch,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  bool _didNotMakeMatch(String countryId, Fixture? fixture) {
    if (fixture == null) {
      return false;
    }
    final knownParticipants =
        {
          fixture.homeCountryId,
          fixture.awayCountryId,
        }.whereType<String>().toSet();
    if (knownParticipants.length == 2 &&
        !knownParticipants.contains(countryId)) {
      return true;
    }
    return fixture.status == FixtureStatus.finished &&
        fixture.winnerCountryId != null &&
        fixture.winnerCountryId != countryId;
  }

  String _sourceText(
    BuildContext context,
    Bracket bracket,
    Map<String, Country> countryById,
    String source,
  ) {
    var effectiveSource = source;
    if (source.startsWith('3rd ')) {
      effectiveSource =
          BracketRules.resolvedThirdPlaceSource(bracket, slot) ?? source;
    }
    final countryId = BracketRules.resolveSourceCountryId(
      bracket,
      effectiveSource,
    );
    final country = countryById[countryId];
    if (country == null) {
      return effectiveSource;
    }
    return '${countryDisplayName(context, country)} ($effectiveSource)';
  }

  String _fixtureMetadata(Fixture fixture) {
    final kickoff = DateFormat.MMMd().add_jm().format(
      fixture.kickoff.toLocal(),
    );
    final venue = fixture.venueLabel;
    if (venue == null) return kickoff;
    return '$kickoff - $venue';
  }
}

class _CountryDropdown extends StatelessWidget {
  const _CountryDropdown({
    required this.label,
    required this.teams,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final List<Country> teams;
  final String? value;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        value: teams.any((team) => team.id == value) ? value : null,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: [
          for (final team in teams)
            DropdownMenuItem(
              value: team.id,
              child: CountryBadge(country: team, compact: true),
            ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _SubmitBar extends ConsumerWidget {
  const _SubmitBar({
    required this.bracket,
    required this.config,
    required this.countries,
    required this.username,
  });

  final Bracket bracket;
  final GlobalContestConfig config;
  final List<Country> countries;
  final String username;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSubmitted = bracket.status == BracketStatus.submitted;
    final canSubmit = BracketRules.canSubmit(bracket, config);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 12,
          children: [
            Text(
              isSubmitted
                  ? context.strings.bracketSubmitted
                  : canSubmit
                  ? context.strings.completeReady
                  : context.strings.completeBeforeSubmit,
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    final locale = AppLocaleScope.localeOf(context);
                    await Printing.layoutPdf(
                      name: 'world-cup-bracket-$username.pdf',
                      onLayout:
                          (_) => buildBracketPdf(
                            bracket: bracket,
                            countries: countries,
                            username: username,
                            locale: locale,
                          ),
                    );
                  },
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(context.strings.exportPdf),
                ),
                FilledButton.icon(
                  onPressed:
                      canSubmit
                          ? () async {
                            ref
                                .read(_bracketSaveStatusProvider.notifier)
                                .state = const _BracketSaveStatus.saving();
                            try {
                              await ref
                                  .read(appRepositoryProvider)
                                  .submitBracket(bracket);
                              ref
                                  .read(_bracketSaveStatusProvider.notifier)
                                  .state = _BracketSaveStatus.saved(
                                DateTime.now(),
                              );
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isSubmitted
                                        ? 'Submitted bracket updated.'
                                        : context.strings.bracketSubmitSuccess,
                                  ),
                                ),
                              );
                            } catch (error) {
                              ref
                                  .read(_bracketSaveStatusProvider.notifier)
                                  .state = _BracketSaveStatus.failed(error);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    context.strings.bracketSubmitFailed(error),
                                  ),
                                ),
                              );
                            }
                          }
                          : null,
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(
                    isSubmitted
                        ? 'Update submitted bracket'
                        : context.strings.submitBracket,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
