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
    final isWide = MediaQuery.sizeOf(context).width >= 700;
    final countryById = {for (final country in countries) country.id: country};
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.strings.group(standing.groupId),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            isWide
                ? _WideStandingTable(
                  standing: standing,
                  countryById: countryById,
                )
                : _MobileStandingTable(
                  standing: standing,
                  countryById: countryById,
                ),
            const SizedBox(height: 16),
            Text('Games', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (fixtures.isEmpty)
              const Text('Group games will appear here when seeded.')
            else
              for (final fixture in fixtures)
                _FixtureTile(fixture: fixture, countries: countries),
          ],
        ),
      ),
    );
  }
}

class _WideStandingTable extends StatelessWidget {
  const _WideStandingTable({required this.standing, required this.countryById});

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
                DataCell(Text('${row.points}')),
              ],
            ),
        ],
      ),
    );
  }
}

class _MobileStandingTable extends StatelessWidget {
  const _MobileStandingTable({
    required this.standing,
    required this.countryById,
  });

  final GroupStanding standing;
  final Map<String, Country> countryById;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final row in standing.rows)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(child: Text('${row.rank}')),
            title: _TeamCell(country: countryById[row.countryId]),
            subtitle: Text('P ${row.played} | GD ${row.goalDifference}'),
            trailing: Text(
              '${row.points} pts',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
      ],
    );
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item == fixture.venueLabel
                              ? Icons.location_on_outlined
                              : item.startsWith('Updated')
                              ? Icons.update
                              : Icons.schedule,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
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
