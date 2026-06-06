import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import '../domain/bracket_rules.dart';
import '../domain/models.dart';
import '../localization/app_strings.dart';
import '../widgets/country_badge.dart';

class BracketScreen extends ConsumerWidget {
  const BracketScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countries = ref.watch(countriesProvider);
    final bracket = ref.watch(myBracketProvider);
    final config = ref.watch(contestConfigProvider);

    return countries.when(
      data:
          (countryList) => bracket.when(
            data:
                (bracketValue) => config.when(
                  data: (configValue) {
                    final isWide = MediaQuery.sizeOf(context).width >= 900;
                    final fixtures =
                        ref.watch(fixturesProvider).value ?? const [];
                    final groupContent = Column(
                      children: [
                        _GroupPicks(countries: countryList),
                        _BestThirdPicks(countries: countryList),
                      ],
                    );
                    final content =
                        isWide
                            ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: groupContent),
                                Expanded(
                                  child: _KnockoutPicks(
                                    countries: countryList,
                                    bracket: bracketValue,
                                    fixtures: fixtures,
                                  ),
                                ),
                              ],
                            )
                            : Column(
                              children: [
                                groupContent,
                                _KnockoutPicks(
                                  countries: countryList,
                                  bracket: bracketValue,
                                  fixtures: fixtures,
                                ),
                              ],
                            );

                    return ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        _BracketHeader(
                          bracket: bracketValue,
                          config: configValue,
                        ),
                        const SizedBox(height: 16),
                        ProviderScope(
                          overrides: [
                            _editableBracketProvider.overrideWithValue(
                              bracketValue,
                            ),
                            _availableCountriesProvider.overrideWithValue(
                              countryList,
                            ),
                          ],
                          child: content,
                        ),
                        const SizedBox(height: 16),
                        _SubmitBar(bracket: bracketValue, config: configValue),
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
}

class _GroupPicks extends ConsumerWidget {
  const _GroupPicks({required this.countries});

  final List<Country> countries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = <String, List<Country>>{};
    for (var i = 0; i < BracketRules.groupIds.length; i += 1) {
      final start = i * 4;
      groups[BracketRules.groupIds[i]] = countries
          .skip(start)
          .take(4)
          .toList(growable: false);
    }

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
                onChanged: (value) => _saveGroupPick(ref, value, second, third),
              ),
              _CountryDropdown(
                label: context.strings.secondPlace,
                teams: _availableTeams(teams, second, [first, third]),
                value: second,
                onChanged: (value) => _saveGroupPick(ref, first, value, third),
              ),
              _CountryDropdown(
                label: context.strings.thirdPlace,
                teams: _availableTeams(teams, third, [first, second]),
                value: third,
                onChanged: (value) => _saveGroupPick(ref, first, second, value),
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
    await ref
        .read(appRepositoryProvider)
        .saveBracket(
          bracket.copyWith(
            groupPicks: picks,
            bestThirdGroupIds: bestThirdGroupIds,
          ),
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
                  ref
                      .read(appRepositoryProvider)
                      .saveBracket(
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
            : context.strings.groupThirdPick(groupId, country!.name);
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      value: isSelected,
      onChanged: isDisabled ? null : onChanged,
      title: Text(title),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
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
              (stage) => stage != TournamentStage.group,
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
    final countryById = {for (final country in countries) country.id: country};
    final current =
        bracket.knockoutPicks
            .where((pick) => pick.slotId == slot.id)
            .firstOrNull;
    final fixture =
        fixtures.where((fixture) => fixture.id == slot.id).firstOrNull;
    final didNotMakeMatch =
        current != null && _didNotMakeMatch(current.winnerCountryId, fixture);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${slot.label}: '
            '${_sourceText(bracket, countryById, slot.sourceA)} '
            '${context.strings.vs} '
            '${_sourceText(bracket, countryById, slot.sourceB)}',
          ),
          const SizedBox(height: 8),
          _CountryDropdown(
            label: context.strings.winner,
            teams: countries,
            value: current?.winnerCountryId,
            onChanged: (countryId) async {
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
              await ref
                  .read(appRepositoryProvider)
                  .saveBracket(bracket.copyWith(knockoutPicks: picks));
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
    return '${country.name} ($effectiveSource)';
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
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: DropdownButtonFormField<String>(
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
  const _SubmitBar({required this.bracket, required this.config});

  final Bracket bracket;
  final GlobalContestConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              canSubmit
                  ? context.strings.completeReady
                  : context.strings.completeBeforeSubmit,
            ),
            FilledButton.icon(
              onPressed:
                  canSubmit
                      ? () =>
                          ref.read(appRepositoryProvider).submitBracket(bracket)
                      : null,
              icon: const Icon(Icons.check_circle_outline),
              label: Text(context.strings.submitBracket),
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
