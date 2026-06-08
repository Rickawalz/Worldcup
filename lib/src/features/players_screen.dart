import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/providers.dart';
import '../domain/bracket_rules.dart';
import '../domain/models.dart';
import '../localization/app_strings.dart';
import '../widgets/country_badge.dart';
import '../widgets/dashboard.dart';

class PlayersScreen extends ConsumerWidget {
  const PlayersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(publicBracketProfilesProvider);
    final countries = ref.watch(countriesProvider);
    return profiles.when(
      data:
          (items) => countries.when(
            data:
                (countryList) =>
                    _PlayersList(profiles: items, countries: countryList),
            loading: () => const Center(child: CircularProgressIndicator()),
            error:
                (error, _) => Center(
                  child: Text(context.strings.couldNotLoad('players', error)),
                ),
          ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (error, _) => Center(
            child: Text(context.strings.couldNotLoad('players', error)),
          ),
    );
  }
}

class PublicBracketScreen extends ConsumerWidget {
  const PublicBracketScreen({required this.userId, super.key});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(publicBracketProfileProvider(userId));
    final countries = ref.watch(countriesProvider);
    return profile.when(
      data:
          (value) => countries.when(
            data: (countryList) {
              if (value == null) {
                return Center(
                  child: Text(context.strings.publicBracketUnavailable),
                );
              }
              return _PublicBracketDetail(
                profile: value,
                countries: countryList,
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error:
                (error, _) => Center(
                  child: Text(context.strings.couldNotLoad('players', error)),
                ),
          ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (error, _) => Center(
            child: Text(context.strings.couldNotLoad('players', error)),
          ),
    );
  }
}

class _PlayersList extends StatelessWidget {
  const _PlayersList({required this.profiles, required this.countries});

  final List<PublicBracketProfile> profiles;
  final List<Country> countries;

  @override
  Widget build(BuildContext context) {
    final countryById = {for (final country in countries) country.id: country};
    return DashboardPage(
      title: context.strings.players,
      subtitle: context.strings.playersIntro,
      icon: Icons.groups_outlined,
      stats: [
        DashboardStat(
          label: 'submitted brackets',
          value: '${profiles.length}',
          icon: Icons.assignment_turned_in_outlined,
        ),
        DashboardStat(
          label: 'countries',
          value: '${countries.length}',
          icon: Icons.flag_outlined,
          color: DashboardColors.sky,
        ),
      ],
      children: [
        if (profiles.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(context.strings.noSubmittedBrackets),
            ),
          )
        else
          for (final profile in profiles) ...[
            _PlayerCard(profile: profile, countryById: countryById),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({required this.profile, required this.countryById});

  final PublicBracketProfile profile;
  final Map<String, Country> countryById;

  @override
  Widget build(BuildContext context) {
    final champion = countryById[profile.bracket.championCountryId];
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/players/${profile.user.id}'),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: colorScheme.primary, width: 5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  foregroundColor: colorScheme.onPrimaryContainer,
                  child: Text(profile.user.username.characters.first),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.user.username,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      champion == null
                          ? Text(context.strings.championPick('TBD'))
                          : Row(
                            children: [
                              const Text('Champion: '),
                              Expanded(
                                child: CountryBadge(
                                  country: champion,
                                  compact: true,
                                ),
                              ),
                            ],
                          ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _ScoreChip(
                            label: 'Total',
                            value: profile.bracket.totalScore,
                            color: colorScheme.primaryContainer,
                            textColor: colorScheme.onPrimaryContainer,
                          ),
                          _ScoreChip(
                            label: 'Group',
                            value: profile.bracket.groupScore,
                          ),
                          _ScoreChip(
                            label: 'Knockout',
                            value: profile.bracket.knockoutScore,
                          ),
                          _ScoreChip(
                            label: 'Tie',
                            value: profile.bracket.tiebreakerDistance,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: () => context.go('/players/${profile.user.id}'),
                  child: Text(context.strings.view),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PublicBracketDetail extends StatelessWidget {
  const _PublicBracketDetail({required this.profile, required this.countries});

  final PublicBracketProfile profile;
  final List<Country> countries;

  @override
  Widget build(BuildContext context) {
    final countryById = {for (final country in countries) country.id: country};
    final champion = countryById[profile.bracket.championCountryId];
    return DashboardPage(
      title: profile.user.username,
      subtitle: 'Public bracket picks, champion choice, and score breakdown.',
      icon: Icons.person_search_outlined,
      stats: [
        DashboardStat(
          label: 'total',
          value: '${profile.bracket.totalScore}',
          icon: Icons.emoji_events_outlined,
        ),
        DashboardStat(
          label: 'group',
          value: '${profile.bracket.groupScore}',
          icon: Icons.groups_2_outlined,
          color: DashboardColors.sky,
        ),
        DashboardStat(
          label: 'knockout',
          value: '${profile.bracket.knockoutScore}',
          icon: Icons.account_tree_outlined,
          color: DashboardColors.emerald,
        ),
      ],
      children: [
        _PublicBracketHeader(profile: profile, champion: champion),
        const SizedBox(height: 16),
        _GroupPicksCard(bracket: profile.bracket, countryById: countryById),
        const SizedBox(height: 16),
        _BestThirdsCard(bracket: profile.bracket, countryById: countryById),
        const SizedBox(height: 16),
        _KnockoutPicksCard(bracket: profile.bracket, countryById: countryById),
      ],
    );
  }
}

class _PublicBracketHeader extends StatelessWidget {
  const _PublicBracketHeader({required this.profile, required this.champion});

  final PublicBracketProfile profile;
  final Country? champion;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final championCountry = champion;
    return Card(
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              profile.user.username,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              context.strings.championPick(''),
              style: TextStyle(color: colorScheme.onPrimaryContainer),
            ),
            const SizedBox(height: 6),
            championCountry == null
                ? Text(
                  'TBD',
                  style: TextStyle(color: colorScheme.onPrimaryContainer),
                )
                : CountryBadge(country: championCountry, compact: true),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ScoreChip(
                  label: 'Total',
                  value: profile.bracket.totalScore,
                  color: colorScheme.primary,
                  textColor: colorScheme.onPrimary,
                ),
                _ScoreChip(
                  label: 'Group',
                  value: profile.bracket.groupScore,
                  color: colorScheme.surface,
                ),
                _ScoreChip(
                  label: 'Knockout',
                  value: profile.bracket.knockoutScore,
                  color: colorScheme.surface,
                ),
                _ScoreChip(
                  label: 'Tiebreaker',
                  value: profile.bracket.tiebreakerDistance,
                  color: colorScheme.surface,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({
    required this.label,
    required this.value,
    this.color,
    this.textColor,
  });

  final String label;
  final int value;
  final Color? color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveColor = color ?? colorScheme.secondaryContainer;
    final effectiveTextColor = textColor ?? colorScheme.onSecondaryContainer;
    return Chip(
      backgroundColor: effectiveColor,
      label: Text(
        '$label $value',
        style: TextStyle(
          color: effectiveTextColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _GroupPicksCard extends StatelessWidget {
  const _GroupPicksCard({required this.bracket, required this.countryById});

  final Bracket bracket;
  final Map<String, Country> countryById;

  @override
  Widget build(BuildContext context) {
    final picksByGroup = {
      for (final pick in bracket.groupPicks) pick.groupId: pick,
    };
    final colorScheme = Theme.of(context).colorScheme;
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
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final cardWidth =
                    width >= 900
                        ? (width - 24) / 3
                        : width >= 600
                        ? (width - 12) / 2
                        : width;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final groupId in BracketRules.groupIds)
                      SizedBox(
                        width: cardWidth,
                        child: Card.outlined(
                          color: colorScheme.surfaceContainerHighest,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.strings.group(groupId),
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                _PickCountryRow(
                                  label: '1st',
                                  country: _country(
                                    picksByGroup[groupId]?.firstCountryId,
                                  ),
                                ),
                                _PickCountryRow(
                                  label: '2nd',
                                  country: _country(
                                    picksByGroup[groupId]?.secondCountryId,
                                  ),
                                ),
                                _PickCountryRow(
                                  label: '3rd',
                                  country: _country(
                                    picksByGroup[groupId]?.thirdCountryId,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Country? _country(String? countryId) => countryById[countryId];
}

class _BestThirdsCard extends StatelessWidget {
  const _BestThirdsCard({required this.bracket, required this.countryById});

  final Bracket bracket;
  final Map<String, Country> countryById;

  @override
  Widget build(BuildContext context) {
    final picksByGroup = {
      for (final pick in bracket.groupPicks) pick.groupId: pick,
    };
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
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final groupId in bracket.bestThirdGroupIds)
                  _BestThirdChip(
                    groupLabel: context.strings.group(groupId),
                    country: _country(picksByGroup[groupId]?.thirdCountryId),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Country? _country(String? countryId) => countryById[countryId];
}

class _KnockoutPicksCard extends StatelessWidget {
  const _KnockoutPicksCard({required this.bracket, required this.countryById});

  final Bracket bracket;
  final Map<String, Country> countryById;

  @override
  Widget build(BuildContext context) {
    final picksBySlot = {
      for (final pick in bracket.knockoutPicks) pick.slotId: pick,
    };
    final slotsByStage = {
      for (final stage in TournamentStage.values)
        if (stage != TournamentStage.group &&
            BracketRules.knockoutSlots().any((slot) => slot.stage == stage))
          stage:
              BracketRules.knockoutSlots()
                  .where((slot) => slot.stage == stage)
                  .toList(),
    };
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
            for (final entry in slotsByStage.entries) ...[
              _KnockoutStagePanel(
                stage: entry.key,
                slots: entry.value,
                winnerForSlot:
                    (slot) => _country(picksBySlot[slot.id]?.winnerCountryId),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  Country? _country(String? countryId) => countryById[countryId];
}

class _PickCountryRow extends StatelessWidget {
  const _PickCountryRow({required this.label, required this.country});

  final String label;
  final Country? country;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          Expanded(
            child:
                country == null
                    ? const Text('TBD')
                    : CountryBadge(country: country!, compact: true),
          ),
        ],
      ),
    );
  }
}

class _BestThirdChip extends StatelessWidget {
  const _BestThirdChip({required this.groupLabel, required this.country});

  final String groupLabel;
  final Country? country;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colorScheme.tertiary.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            groupLabel,
            style: TextStyle(
              color: colorScheme.onTertiaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          if (country == null)
            Text(
              'TBD',
              style: TextStyle(color: colorScheme.onTertiaryContainer),
            )
          else
            CountryBadge(
              country: country!,
              compact: true,
              abbreviationOnly: true,
            ),
        ],
      ),
    );
  }
}

class _KnockoutStagePanel extends StatelessWidget {
  const _KnockoutStagePanel({
    required this.stage,
    required this.slots,
    required this.winnerForSlot,
  });

  final TournamentStage stage;
  final List<BracketSlot> slots;
  final Country? Function(BracketSlot slot) winnerForSlot;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card.outlined(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: _stageColor(colorScheme),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(
              _stageTitle(context),
              style: TextStyle(
                color: _stageTextColor(colorScheme),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                for (final slot in slots)
                  _KnockoutWinnerRow(slot: slot, country: winnerForSlot(slot)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _stageColor(ColorScheme colorScheme) {
    return switch (stage) {
      TournamentStage.roundOf32 => colorScheme.secondaryContainer,
      TournamentStage.roundOf16 => colorScheme.primaryContainer,
      TournamentStage.quarterfinal => colorScheme.tertiaryContainer,
      TournamentStage.semifinal => colorScheme.primary,
      TournamentStage.thirdPlace => colorScheme.surfaceContainerHighest,
      TournamentStage.finalMatch => colorScheme.secondary,
      TournamentStage.group => colorScheme.surfaceContainerHighest,
    };
  }

  Color _stageTextColor(ColorScheme colorScheme) {
    return switch (stage) {
      TournamentStage.semifinal => colorScheme.onPrimary,
      TournamentStage.finalMatch => colorScheme.onSecondary,
      TournamentStage.roundOf32 => colorScheme.onSecondaryContainer,
      TournamentStage.roundOf16 => colorScheme.onPrimaryContainer,
      TournamentStage.quarterfinal => colorScheme.onTertiaryContainer,
      TournamentStage.thirdPlace => colorScheme.onSurfaceVariant,
      TournamentStage.group => colorScheme.onSurfaceVariant,
    };
  }

  String _stageTitle(BuildContext context) {
    final strings = context.strings;
    return switch (stage) {
      TournamentStage.roundOf32 => strings.roundOf32,
      TournamentStage.roundOf16 => strings.roundOf16,
      TournamentStage.quarterfinal => strings.quarterfinals,
      TournamentStage.semifinal => strings.semifinals,
      TournamentStage.thirdPlace => 'Third place',
      TournamentStage.finalMatch => strings.finalRound,
      TournamentStage.group => strings.groupStage,
    };
  }
}

class _KnockoutWinnerRow extends StatelessWidget {
  const _KnockoutWinnerRow({required this.slot, required this.country});

  final BracketSlot slot;
  final Country? country;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              slot.label,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          Expanded(
            child:
                country == null
                    ? const Text('TBD')
                    : CountryBadge(country: country!, compact: true),
          ),
        ],
      ),
    );
  }
}
