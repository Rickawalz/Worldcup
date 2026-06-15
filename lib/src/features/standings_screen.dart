import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/providers.dart';
import '../domain/bracket_rules.dart';
import '../domain/models.dart';
import '../localization/app_strings.dart';
import '../localization/country_names.dart';
import '../widgets/country_badge.dart';
import '../widgets/dashboard.dart';
import '../widgets/country_flags.dart';

class StandingsScreen extends ConsumerWidget {
  const StandingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countries = ref.watch(countriesProvider);
    final fixtures = ref.watch(fixturesProvider);
    final standings = ref.watch(standingsProvider);
    final strings = context.strings;
    return countries.when(
      data:
          (countryList) => fixtures.when(
            data:
                (fixtureList) => standings.when(
                  data: (standingList) {
                    final groupedFixtures = _groupFixturesByGroup(fixtureList);
                    final knockoutFixtures =
                        fixtureList
                            .where(
                              (fixture) =>
                                  fixture.stage != TournamentStage.group,
                            )
                            .toList()
                          ..sort((a, b) => a.kickoff.compareTo(b.kickoff));
                    return DashboardPage(
                      title: strings.standings,
                      subtitle:
                          'Group tables update from admin-entered results. Ranking may include admin tiebreaker overrides.',
                      icon: Icons.table_rows_outlined,
                      stats: [
                        DashboardStat(
                          label: 'groups',
                          value: '${standingList.length}',
                          icon: Icons.grid_view_outlined,
                        ),
                        DashboardStat(
                          label: 'games loaded',
                          value: '${fixtureList.length}',
                          icon: Icons.sports_soccer,
                          color: DashboardColors.sky,
                        ),
                      ],
                      children: [
                        const _StandingsLegend(),
                        const SizedBox(height: 16),
                        _GroupStandingsGrid(
                          standings: standingList,
                          countries: countryList,
                          fixturesByGroup: groupedFixtures,
                        ),
                        const SizedBox(height: 24),
                        _OfficialKnockoutBracket(
                          fixtures: knockoutFixtures,
                          countries: countryList,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Knockout games',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        if (knockoutFixtures.isEmpty)
                          const Text(
                            'Knockout games will appear here when seeded.',
                          )
                        else
                          for (final fixture in knockoutFixtures)
                            _FixtureTile(
                              fixture: fixture,
                              countries: countryList,
                            ),
                        const SizedBox(height: 24),
                        Text(
                          strings.teamsFlagsFixtures,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(strings.countryDataExplainer),
                        const SizedBox(height: 16),
                        _CountryGrid(countries: countryList),
                      ],
                    );
                  },
                  loading:
                      () => const Center(child: CircularProgressIndicator()),
                  error:
                      (error, _) =>
                          Center(child: Text('Standings error: $error')),
                ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Game error: $error')),
          ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Country error: $error')),
    );
  }
}

class _StandingsLegend extends StatelessWidget {
  const _StandingsLegend();

  static bool _isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 640;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final theme = Theme.of(context);
    final content = _StandingsLegendContent(strings: strings);

    if (_isMobile(context)) {
      return Card(
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            title: Text(
              strings.standingsLegendTitle,
              style: theme.textTheme.titleSmall,
            ),
            initiallyExpanded: false,
            children: [content],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.standingsLegendTitle,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            content,
          ],
        ),
      ),
    );
  }
}

class _StandingsLegendContent extends StatelessWidget {
  const _StandingsLegendContent({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = _StandingsLegend._isMobile(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            if (!isMobile) {
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final entry in strings.standingsLegendEntries)
                    _StandingsLegendItem(entry: entry),
                ],
              );
            }
            final itemWidth = (constraints.maxWidth - 6) / 2;
            return Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final entry in strings.standingsLegendEntries)
                  SizedBox(
                    width: itemWidth,
                    child: _StandingsLegendItem(entry: entry, compact: true),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LegendAbbrChip(label: 'Form', compact: isMobile),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                strings.standingsLegendForm,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StandingsLegendItem extends StatelessWidget {
  const _StandingsLegendItem({required this.entry, this.compact = false});

  final StandingsLegendEntry entry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (compact) {
      return Row(
        children: [
          _LegendAbbrChip(label: entry.abbr, compact: true),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              entry.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      );
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 140, maxWidth: 220),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LegendAbbrChip(label: entry.abbr),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              entry.label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendAbbrChip extends StatelessWidget {
  const _LegendAbbrChip({required this.label, this.compact = false});

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0x44142533),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x33FFFFFF)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: DashboardColors.gold,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _GroupStandingsGrid extends StatelessWidget {
  const _GroupStandingsGrid({
    required this.standings,
    required this.countries,
    required this.fixturesByGroup,
  });

  final List<GroupStanding> standings;
  final List<Country> countries;
  final Map<String, List<Fixture>> fixturesByGroup;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1100 ? 2 : 1;
        final cardWidth = columns == 2 ? (width - 16) / 2 : double.infinity;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final standing in standings)
              SizedBox(
                width: cardWidth,
                child: _GroupStandingCard(
                  standing: standing,
                  countries: countries,
                  fixtures: fixturesByGroup[standing.groupId] ?? const [],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _GroupStandingCard extends StatelessWidget {
  const _GroupStandingCard({
    required this.standing,
    required this.countries,
    required this.fixtures,
  });

  final GroupStanding standing;
  final List<Country> countries;
  final List<Fixture> fixtures;

  @override
  Widget build(BuildContext context) {
    final countryById = {for (final country in countries) country.id: country};
    final isMobile = MediaQuery.sizeOf(context).width < 640;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.strings.group(standing.groupId),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            _GroupStandingTable(
              standing: standing,
              countryById: countryById,
            ),
            if (isMobile)
              _MobileGroupGamesSection(
                fixtures: fixtures,
                countries: countries,
              )
            else ...[
              const SizedBox(height: 16),
              Text('Games', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (fixtures.isEmpty)
                const Text('Group games will appear here when seeded.')
              else
                for (final fixture in fixtures)
                  _FixtureTile(fixture: fixture, countries: countries),
            ],
          ],
        ),
      ),
    );
  }
}

class _MobileGroupGamesSection extends StatelessWidget {
  const _MobileGroupGamesSection({
    required this.fixtures,
    required this.countries,
  });

  final List<Fixture> fixtures;
  final List<Country> countries;

  @override
  Widget build(BuildContext context) {
    if (fixtures.isEmpty) {
      return const SizedBox.shrink();
    }
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        title: Text(
          context.strings.showGroupGames(fixtures.length),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        initiallyExpanded: false,
        children: [
          for (final fixture in fixtures)
            _FixtureTile(fixture: fixture, countries: countries),
        ],
      ),
    );
  }
}

class _GroupStandingTable extends StatelessWidget {
  const _GroupStandingTable({
    required this.standing,
    required this.countryById,
  });

  final GroupStanding standing;
  final Map<String, Country> countryById;

  @override
  Widget build(BuildContext context) {
    final useMobileLayout = MediaQuery.sizeOf(context).width < 640;
    if (useMobileLayout) {
      return _MobileStandingList(
        standing: standing,
        countryById: countryById,
      );
    }
    return _DesktopStandingTable(
      standing: standing,
      countryById: countryById,
    );
  }
}

class _DesktopStandingTable extends StatelessWidget {
  const _DesktopStandingTable({
    required this.standing,
    required this.countryById,
  });

  final GroupStanding standing;
  final Map<String, Country> countryById;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 36,
        dataRowMinHeight: 44,
        dataRowMaxHeight: 52,
        columnSpacing: 16,
        columns: const [
          DataColumn(label: Text('Pos')),
          DataColumn(label: Text('Team')),
          DataColumn(label: Text('P')),
          DataColumn(label: Text('W')),
          DataColumn(label: Text('D')),
          DataColumn(label: Text('L')),
          DataColumn(label: Text('GF')),
          DataColumn(label: Text('GA')),
          DataColumn(label: Text('GD')),
          DataColumn(label: Text('Form')),
          DataColumn(label: Text('Pts')),
        ],
        rows: [
          for (final row in standing.rows)
            DataRow(
              cells: [
                DataCell(Text('${row.rank}')),
                DataCell(_TeamCell(country: countryById[row.countryId])),
                DataCell(Text('${row.played}')),
                DataCell(Text('${row.won}')),
                DataCell(Text('${row.drawn}')),
                DataCell(Text('${row.lost}')),
                DataCell(Text('${row.goalsFor}')),
                DataCell(Text('${row.goalsAgainst}')),
                DataCell(Text('${row.goalDifference}')),
                DataCell(
                  Text(
                    row.form.isEmpty ? '—' : row.form,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    '${row.points}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _MobileStandingList extends StatelessWidget {
  const _MobileStandingList({
    required this.standing,
    required this.countryById,
  });

  final GroupStanding standing;
  final Map<String, Country> countryById;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < standing.rows.length; index++) ...[
          if (index > 0) const Divider(height: 1),
          _MobileStandingRow(
            row: standing.rows[index],
            country: countryById[standing.rows[index].countryId],
            highlight: standing.rows[index].rank <= 2,
          ),
        ],
      ],
    );
  }
}

class _MobileStatsRow extends StatelessWidget {
  const _MobileStatsRow({required this.cells, this.header = false});

  final List<String> cells;
  final bool header;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style =
        header
            ? theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            )
            : theme.textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            );

    return Row(
      children: [
        for (var index = 0; index < cells.length; index++) ...[
          if (index > 0)
            Text(
              '·',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          Expanded(
            child: Text(
              cells[index],
              textAlign: TextAlign.center,
              style: style,
            ),
          ),
        ],
      ],
    );
  }
}

class _MobileStandingRow extends StatelessWidget {
  const _MobileStandingRow({
    required this.row,
    required this.country,
    required this.highlight,
  });

  final StandingRow row;
  final Country? country;
  final bool highlight;

  static const _statHeaders = ['P', 'W', 'D', 'L', 'GF', 'GA', 'GD'];

  static List<String> _valueCells(StandingRow row) {
    final gdText =
        row.goalDifference > 0
            ? '+${row.goalDifference}'
            : '${row.goalDifference}';
    return [
      '${row.played}',
      '${row.won}',
      '${row.drawn}',
      '${row.lost}',
      '${row.goalsFor}',
      '${row.goalsAgainst}',
      gdText,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration:
          highlight
              ? BoxDecoration(
                color: DashboardColors.emerald.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              )
              : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _RankBadge(rank: row.rank, highlight: highlight, compact: true),
              const SizedBox(width: 8),
              Expanded(
                child:
                    country == null
                        ? Text('TBD', style: theme.textTheme.bodyLarge)
                        : CountryBadge(country: country!, compact: true),
              ),
              Text(
                '${row.points} pts',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: DashboardColors.gold,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 34),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MobileStatsRow(cells: _statHeaders, header: true),
                const SizedBox(height: 2),
                _MobileStatsRow(cells: _valueCells(row)),
                if (row.form.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        'Form',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _FormBadges(form: row.form, compact: true),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({
    required this.rank,
    required this.highlight,
    this.compact = false,
  });

  final int rank;
  final bool highlight;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 26.0 : 32.0;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color:
            highlight
                ? DashboardColors.emerald.withValues(alpha: 0.25)
                : const Color(0x33142533),
        borderRadius: BorderRadius.circular(compact ? 8 : 10),
        border: Border.all(
          color:
              highlight
                  ? DashboardColors.emerald.withValues(alpha: 0.6)
                  : const Color(0x33FFFFFF),
        ),
      ),
      child: Text(
        '$rank',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _FormBadges extends StatelessWidget {
  const _FormBadges({required this.form, this.compact = false});

  final String form;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final results = form.split(',').where((part) => part.isNotEmpty).toList();
    return Wrap(
      spacing: compact ? 3 : 6,
      children: [
        for (final result in results)
          _FormBadge(result: result.trim(), compact: compact),
      ],
    );
  }
}

class _FormBadge extends StatelessWidget {
  const _FormBadge({required this.result, this.compact = false});

  final String result;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = switch (result) {
      'W' => DashboardColors.emerald,
      'D' => DashboardColors.sky,
      'L' => const Color(0xFFE57373),
      _ => themeFallback(context),
    };
    final size = compact ? 20.0 : 28.0;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(compact ? 5 : 8),
        border: Border.all(color: color.withValues(alpha: 0.65)),
      ),
      child: Text(
        result,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: compact ? 10 : null,
        ),
      ),
    );
  }

  Color themeFallback(BuildContext context) {
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }
}

class _TeamCell extends StatelessWidget {
  const _TeamCell({required this.country});

  final Country? country;

  @override
  Widget build(BuildContext context) {
    final team = country;
    if (team == null) {
      return const Text('TBD');
    }
    return CountryBadge(country: team, compact: true);
  }
}

class _CountryGrid extends StatelessWidget {
  const _CountryGrid({required this.countries});

  final List<Country> countries;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns =
            width >= 1000
                ? 4
                : width >= 640
                ? 3
                : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            childAspectRatio: 5.5,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: countries.length,
          itemBuilder: (context, index) {
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: CountryBadge(country: countries[index]),
              ),
            );
          },
        );
      },
    );
  }
}

class _OfficialKnockoutBracket extends StatelessWidget {
  const _OfficialKnockoutBracket({
    required this.fixtures,
    required this.countries,
  });

  final List<Fixture> fixtures;
  final List<Country> countries;

  @override
  Widget build(BuildContext context) {
    final slots = BracketRules.knockoutSlots();
    final byStage = {
      for (final stage in TournamentStage.values)
        stage: slots.where((slot) => slot.stage == stage).toList(),
    };
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
            Positioned.fill(
              child: CustomPaint(painter: _OfficialBracketPainter()),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(18),
              child: SizedBox(
                width: 1120,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Official Knockout Bracket',
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Filled from admin-entered scores and winners.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _OfficialRoundColumn(
                          title: context.strings.roundOf32,
                          color: const Color(0xFF4057A8),
                          slots:
                              byStage[TournamentStage.roundOf32]!
                                  .take(8)
                                  .toList(),
                          fixtures: fixtures,
                          countries: countries,
                        ),
                        _OfficialRoundColumn(
                          title: context.strings.roundOf16,
                          color: const Color(0xFF61B34A),
                          slots:
                              byStage[TournamentStage.roundOf16]!
                                  .take(4)
                                  .toList(),
                          fixtures: fixtures,
                          countries: countries,
                        ),
                        _OfficialRoundColumn(
                          title: context.strings.quarterfinals,
                          color: const Color(0xFFE05D3F),
                          slots:
                              byStage[TournamentStage.quarterfinal]!
                                  .take(2)
                                  .toList(),
                          fixtures: fixtures,
                          countries: countries,
                        ),
                        _OfficialRoundColumn(
                          title: context.strings.semifinals,
                          color: const Color(0xFF6F6681),
                          slots:
                              byStage[TournamentStage.semifinal]!
                                  .take(1)
                                  .toList(),
                          fixtures: fixtures,
                          countries: countries,
                        ),
                        _OfficialFinalPanel(
                          slot: byStage[TournamentStage.finalMatch]!.single,
                          fixtures: fixtures,
                          countries: countries,
                        ),
                        _OfficialRoundColumn(
                          title: context.strings.semifinals,
                          color: const Color(0xFF6F6681),
                          slots:
                              byStage[TournamentStage.semifinal]!
                                  .skip(1)
                                  .toList(),
                          fixtures: fixtures,
                          countries: countries,
                        ),
                        _OfficialRoundColumn(
                          title: context.strings.quarterfinals,
                          color: const Color(0xFFE05D3F),
                          slots:
                              byStage[TournamentStage.quarterfinal]!
                                  .skip(2)
                                  .toList(),
                          fixtures: fixtures,
                          countries: countries,
                        ),
                        _OfficialRoundColumn(
                          title: context.strings.roundOf16,
                          color: const Color(0xFF61B34A),
                          slots:
                              byStage[TournamentStage.roundOf16]!
                                  .skip(4)
                                  .toList(),
                          fixtures: fixtures,
                          countries: countries,
                        ),
                        _OfficialRoundColumn(
                          title: context.strings.roundOf32,
                          color: const Color(0xFF4057A8),
                          slots:
                              byStage[TournamentStage.roundOf32]!
                                  .skip(8)
                                  .toList(),
                          fixtures: fixtures,
                          countries: countries,
                        ),
                      ],
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

class _OfficialRoundColumn extends StatelessWidget {
  const _OfficialRoundColumn({
    required this.title,
    required this.color,
    required this.slots,
    required this.fixtures,
    required this.countries,
  });

  final String title;
  final Color color;
  final List<BracketSlot> slots;
  final List<Fixture> fixtures;
  final List<Country> countries;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      child: Column(
        children: [
          Text(
            title.toUpperCase(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          for (final slot in slots) ...[
            _OfficialBracketMatchCard(
              slot: slot,
              color: color,
              fixtures: fixtures,
              countries: countries,
            ),
            SizedBox(height: slot.stage == TournamentStage.roundOf32 ? 10 : 26),
          ],
        ],
      ),
    );
  }
}

class _OfficialFinalPanel extends StatelessWidget {
  const _OfficialFinalPanel({
    required this.slot,
    required this.fixtures,
    required this.countries,
  });

  final BracketSlot slot;
  final List<Fixture> fixtures;
  final List<Country> countries;

  @override
  Widget build(BuildContext context) {
    final fixture = _fixtureForSlot(fixtures, slot);
    final champion = _countryById(countries)[fixture?.winnerCountryId];
    return SizedBox(
      width: 190,
      child: Column(
        children: [
          const Icon(Icons.emoji_events, size: 64, color: DashboardColors.gold),
          Text(
            context.strings.finalRound.toUpperCase(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: DashboardColors.gold,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          _OfficialBracketMatchCard(
            slot: slot,
            color: DashboardColors.gold,
            fixtures: fixtures,
            countries: countries,
            isCenterpiece: true,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
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
                  ),
                ),
                const SizedBox(height: 8),
                champion == null
                    ? const Text('TBD')
                    : CountryBadge(country: champion, compact: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OfficialBracketMatchCard extends StatelessWidget {
  const _OfficialBracketMatchCard({
    required this.slot,
    required this.color,
    required this.fixtures,
    required this.countries,
    this.isCenterpiece = false,
  });

  final BracketSlot slot;
  final Color color;
  final List<Fixture> fixtures;
  final List<Country> countries;
  final bool isCenterpiece;

  @override
  Widget build(BuildContext context) {
    final fixture = _fixtureForSlot(fixtures, slot);
    final home = _officialTeamLabel(
      context,
      fixture?.homeCountryId,
      slot.sourceA,
    );
    final away = _officialTeamLabel(
      context,
      fixture?.awayCountryId,
      slot.sourceB,
    );
    final hasScore = fixture?.homeScore != null && fixture?.awayScore != null;
    final score =
        hasScore
            ? '${fixture!.homeScore} - ${fixture.awayScore}'
            : context.strings.vs;
    final winner = _countryById(countries)[fixture?.winnerCountryId];
    return Container(
      width: isCenterpiece ? 170 : 104,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.9), width: 1.4),
      ),
      child: Column(
        children: [
          Text(
            slot.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          _OfficialTeamLine(text: home),
          const SizedBox(height: 4),
          _OfficialTeamLine(text: away),
          const SizedBox(height: 7),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
            decoration: BoxDecoration(
              color:
                  hasScore
                      ? DashboardColors.gold.withValues(alpha: 0.18)
                      : Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color:
                    hasScore
                        ? DashboardColors.gold
                        : Colors.white.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              score,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: hasScore ? DashboardColors.gold : Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (winner != null) ...[
            const SizedBox(height: 7),
            CountryBadge(country: winner, compact: true),
          ],
        ],
      ),
    );
  }

  String _officialTeamLabel(
    BuildContext context,
    String? countryId,
    String source,
  ) {
    final country = _countryById(countries)[countryId];
    if (country == null) return source;
    return country.abbreviation;
  }
}

class _OfficialTeamLine extends StatelessWidget {
  const _OfficialTeamLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
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

class _OfficialBracketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.08)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1;
    final centerY = size.height * 0.58;
    canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), paint);
    canvas.drawCircle(Offset(size.width / 2, centerY), 74, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FixtureTile extends StatelessWidget {
  const _FixtureTile({required this.fixture, required this.countries});

  final Fixture fixture;
  final List<Country> countries;

  @override
  Widget build(BuildContext context) {
    final home = _country(fixture.homeCountryId);
    final away = _country(fixture.awayCountryId);
    final winner = _country(fixture.winnerCountryId);
    final hasScore = fixture.homeScore != null && fixture.awayScore != null;
    final scoreText =
        hasScore
            ? '${fixture.homeScore} - ${fixture.awayScore}'
            : context.strings.vs;
    final isWide = MediaQuery.sizeOf(context).width >= 520;
    final metadata = [
      DateFormat.yMMMd().add_jm().format(fixture.kickoff.toLocal()),
      if (fixture.venueLabel != null) fixture.venueLabel!,
      if (fixture.updatedAt != null)
        'Updated ${DateFormat.yMMMd().add_jm().format(fixture.updatedAt!.toLocal())}',
    ];

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(color: DashboardColors.emerald, width: 4),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Chip(
                    avatar: const Icon(Icons.sports_soccer, size: 16),
                    label: Text(fixture.roundLabel),
                  ),
                  _StatusChip(status: fixture.status),
                  if (winner != null && hasScore)
                    Chip(
                      avatar: const Icon(Icons.emoji_events_outlined, size: 16),
                      label: Text(
                        'Winner: ${countryDisplayName(context, winner)}',
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MatchTeamSide(
                      country: home,
                      alignment: CrossAxisAlignment.start,
                      textAlign: TextAlign.left,
                      abbreviationOnly: !isWide,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _ScorePill(text: scoreText, hasScore: hasScore),
                  ),
                  Expanded(
                    child: _MatchTeamSide(
                      country: away,
                      alignment: CrossAxisAlignment.end,
                      textAlign: TextAlign.right,
                      abbreviationOnly: !isWide,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  for (final item in metadata)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item == fixture.venueLabel
                                ? Icons.location_on_outlined
                                : item.startsWith('Updated')
                                ? Icons.update
                                : Icons.schedule,
                            size: 16,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              item,
                              style: Theme.of(context).textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Country? _country(String? id) {
    if (id == null) {
      return null;
    }
    return countries.where((country) => country.id == id).firstOrNull;
  }
}

class _MatchTeamSide extends StatelessWidget {
  const _MatchTeamSide({
    required this.country,
    required this.alignment,
    required this.textAlign,
    required this.abbreviationOnly,
  });

  final Country? country;
  final CrossAxisAlignment alignment;
  final TextAlign textAlign;
  final bool abbreviationOnly;

  @override
  Widget build(BuildContext context) {
    final team = country;
    if (team == null) {
      return Column(
        crossAxisAlignment: alignment,
        children: [
          const CircleAvatar(child: Text('TBD')),
          const SizedBox(height: 6),
          Text('TBD', textAlign: textAlign),
        ],
      );
    }
    final label =
        abbreviationOnly
            ? team.abbreviation
            : countryDisplayName(context, team);
    final flag = flagEmoji(team);
    return Column(
      crossAxisAlignment: alignment,
      children: [
        CircleAvatar(
          radius: 19,
          backgroundColor: DashboardColors.emerald.withValues(alpha: 0.2),
          child: Text(flag ?? team.abbreviation),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: textAlign,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ],
    );
  }
}

class _ScorePill extends StatelessWidget {
  const _ScorePill({required this.text, required this.hasScore});

  final String text;
  final bool hasScore;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 72),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color:
            hasScore
                ? DashboardColors.gold.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              hasScore
                  ? DashboardColors.gold
                  : Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: hasScore ? DashboardColors.gold : Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final FixtureStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = switch (status) {
      FixtureStatus.scheduled => (
        'Scheduled',
        Icons.event_available_outlined,
        DashboardColors.sky,
      ),
      FixtureStatus.live => ('Live', Icons.bolt, DashboardColors.gold),
      FixtureStatus.finished => (
        'Final',
        Icons.check_circle_outline,
        DashboardColors.emerald,
      ),
      FixtureStatus.postponed => (
        'Postponed',
        Icons.event_busy_outlined,
        Theme.of(context).colorScheme.error,
      ),
    };
    return Chip(avatar: Icon(icon, size: 16, color: color), label: Text(label));
  }
}

Fixture? _fixtureForSlot(List<Fixture> fixtures, BracketSlot slot) {
  return fixtures.where((fixture) => fixture.id == slot.id).firstOrNull;
}

Map<String, Country> _countryById(List<Country> countries) {
  return {for (final country in countries) country.id: country};
}

Map<String, List<Fixture>> _groupFixturesByGroup(List<Fixture> fixtures) {
  final grouped = <String, List<Fixture>>{
    for (final groupId in BracketRules.groupIds) groupId: <Fixture>[],
  };
  for (final fixture in fixtures) {
    if (fixture.stage != TournamentStage.group) continue;
    final groupId = _fixtureGroupId(fixture);
    if (groupId == null) continue;
    grouped[groupId]?.add(fixture);
  }
  for (final fixtures in grouped.values) {
    fixtures.sort((a, b) => a.kickoff.compareTo(b.kickoff));
  }
  return grouped;
}

String? _fixtureGroupId(Fixture fixture) {
  final match = RegExp(
    r'group\s+([a-l])',
    caseSensitive: false,
  ).firstMatch(fixture.roundLabel);
  final groupFromLabel = match?.group(1)?.toUpperCase();
  if (groupFromLabel != null) return groupFromLabel;

  final homeId = fixture.homeCountryId;
  final awayId = fixture.awayCountryId;
  if (homeId == null && awayId == null) return null;
  for (final entry in BracketRules.groupCountryIds.entries) {
    final countryIds = entry.value;
    if ((homeId == null || countryIds.contains(homeId)) &&
        (awayId == null || countryIds.contains(awayId))) {
      return entry.key;
    }
  }
  return null;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
