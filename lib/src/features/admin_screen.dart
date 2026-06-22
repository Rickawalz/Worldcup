import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../admin/admin_access.dart';
import '../data/providers.dart';
import '../domain/admin_validators.dart';
import '../domain/bracket_rules.dart';
import '../domain/contest_submission_status.dart';
import '../domain/models.dart';
import '../localization/app_strings.dart';
import '../localization/country_names.dart';
import '../widgets/dashboard.dart';

enum _AdminSection {
  matchResults,
  standings,
  groupAdvancers,
  leaderboard,
  settings,
  auditLog,
}

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  _AdminSection _section = _AdminSection.matchResults;

  @override
  Widget build(BuildContext context) {
    final countries = ref.watch(countriesProvider);
    final fixtures = ref.watch(fixturesProvider);
    final standings = ref.watch(standingsProvider);
    final officialResults = ref.watch(officialResultsProvider);
    final config = ref.watch(contestConfigProvider);
    final auditLogs = ref.watch(adminAuditLogsProvider);
    final user = ref.watch(currentUserProvider);
    final strings = context.strings;

    final currentUser = user.valueOrNull;
    if (!AdminAccess.isAdmin(currentUser)) {
      return const _AdminSignInGate();
    }

    return DashboardPage(
      title: strings.adminConsole,
      subtitle:
          'Manual admin tools are the source of truth for launch. Result saves and leaderboard rebuilds write directly to Firestore from this admin account.',
      icon: Icons.admin_panel_settings_outlined,
      stats: [
        DashboardStat(
          label: 'games',
          value: '${fixtures.valueOrNull?.length ?? 0}',
          icon: Icons.sports_soccer,
        ),
        DashboardStat(
          label: 'groups',
          value: '${standings.valueOrNull?.length ?? 0}',
          icon: Icons.table_rows_outlined,
          color: DashboardColors.sky,
        ),
        DashboardStat(
          label: 'audit rows',
          value: '${auditLogs.valueOrNull?.length ?? 0}',
          icon: Icons.history,
          color: DashboardColors.gold,
        ),
      ],
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<_AdminSection>(
            segments: const [
              ButtonSegment(
                value: _AdminSection.matchResults,
                icon: Icon(Icons.sports_soccer),
                label: Text('Games & results'),
              ),
              ButtonSegment(
                value: _AdminSection.groupAdvancers,
                icon: Icon(Icons.groups_2_outlined),
                label: Text('Group advancers'),
              ),
              ButtonSegment(
                value: _AdminSection.standings,
                icon: Icon(Icons.table_rows_outlined),
                label: Text('Standings'),
              ),
              ButtonSegment(
                value: _AdminSection.leaderboard,
                icon: Icon(Icons.leaderboard_outlined),
                label: Text('Leaderboard'),
              ),
              ButtonSegment(
                value: _AdminSection.settings,
                icon: Icon(Icons.tune),
                label: Text('Settings'),
              ),
              ButtonSegment(
                value: _AdminSection.auditLog,
                icon: Icon(Icons.history),
                label: Text('Audit log'),
              ),
            ],
            selected: {_section},
            onSelectionChanged:
                (selection) => setState(() => _section = selection.first),
          ),
        ),
        const SizedBox(height: 16),
        countries.when(
          data:
              (countryList) => fixtures.when(
                data:
                    (fixtureList) => officialResults.when(
                      data:
                          (results) => standings.when(
                            data:
                                (standingList) => config.when(
                                  data:
                                      (contestConfig) => _sectionContent(
                                        countryList,
                                        fixtureList,
                                        standingList,
                                        results,
                                        contestConfig,
                                        auditLogs,
                                      ),
                                  loading:
                                      () => const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                  error:
                                      (error, _) =>
                                          Text('Config load error: $error'),
                                ),
                            loading:
                                () => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                            error:
                                (error, _) =>
                                    Text('Standings load error: $error'),
                          ),
                      loading:
                          () =>
                              const Center(child: CircularProgressIndicator()),
                      error:
                          (error, _) => Text('Official results error: $error'),
                    ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Text('Game load error: $error'),
              ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text('Country load error: $error'),
        ),
      ],
    );
  }

  Widget _sectionContent(
    List<Country> countries,
    List<Fixture> fixtures,
    List<GroupStanding> standings,
    OfficialResults officialResults,
    GlobalContestConfig config,
    AsyncValue<List<AdminAuditLog>> auditLogs,
  ) {
    switch (_section) {
      case _AdminSection.matchResults:
        return _MatchResultsSection(
          countries: countries,
          fixtures: fixtures,
          officialResults: officialResults,
        );
      case _AdminSection.standings:
        return _AdminStandingsSection(
          countries: countries,
          standings: standings,
        );
      case _AdminSection.groupAdvancers:
        return _GroupAdvancersSection(
          countries: countries,
          standings: standings,
          officialResults: officialResults,
        );
      case _AdminSection.leaderboard:
        return _RecalculateLeaderboardSection(officialResults: officialResults);
      case _AdminSection.settings:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ContestSettingsSection(config: config),
            const SizedBox(height: 16),
            const _ApiFootballSyncSection(),
          ],
        );
      case _AdminSection.auditLog:
        return auditLogs.when(
          data: (logs) => _AuditLogSection(logs: logs),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text('Audit log error: $error'),
        );
    }
  }
}

class _MatchResultsSection extends ConsumerStatefulWidget {
  const _MatchResultsSection({
    required this.countries,
    required this.fixtures,
    required this.officialResults,
  });

  final List<Country> countries;
  final List<Fixture> fixtures;
  final OfficialResults officialResults;

  @override
  ConsumerState<_MatchResultsSection> createState() =>
      _MatchResultsSectionState();
}

class _MatchResultsSectionState extends ConsumerState<_MatchResultsSection> {
  final _kickoffController = TextEditingController();
  final _homeScoreController = TextEditingController();
  final _awayScoreController = TextEditingController();
  final _venueNameController = TextEditingController();
  final _venueCityController = TextEditingController();
  String? _fixtureId;
  String? _homeCountryId;
  String? _awayCountryId;
  String? _winnerCountryId;
  FixtureStatus _status = FixtureStatus.scheduled;
  bool _isSaving = false;

  @override
  void dispose() {
    _kickoffController.dispose();
    _homeScoreController.dispose();
    _awayScoreController.dispose();
    _venueNameController.dispose();
    _venueCityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.fixtures.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No games are loaded yet.'),
        ),
      );
    }
    _fixtureId ??= widget.fixtures.first.id;
    final fixture = _selectedFixture;
    if (fixture == null) {
      return const Text('Selected game was not found.');
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Games & Results',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Edit teams, kickoff, venue, status, scores, and winners. Group results update standings; knockout results update scoring winners.',
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: fixture.id,
              decoration: const InputDecoration(
                labelText: 'Game',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final item in widget.fixtures)
                  DropdownMenuItem(
                    value: item.id,
                    child: Text('${item.id} - ${item.roundLabel}'),
                  ),
              ],
              onChanged: (value) {
                final next =
                    widget.fixtures
                        .where((item) => item.id == value)
                        .firstOrNull;
                if (next == null) return;
                setState(() => _loadFixture(next));
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 280,
                  child: TextField(
                    controller: _kickoffController,
                    decoration: const InputDecoration(
                      labelText: 'Kickoff (ISO date/time)',
                      helperText: 'Example: 2026-06-11T19:00:00.000Z',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(
                  width: 280,
                  child: _CountryDropdown(
                    label: 'Home team',
                    value: _homeCountryId ?? fixture.homeCountryId,
                    countries: widget.countries,
                    onChanged:
                        (value) => setState(() => _homeCountryId = value),
                  ),
                ),
                SizedBox(
                  width: 280,
                  child: _CountryDropdown(
                    label: 'Away team',
                    value: _awayCountryId ?? fixture.awayCountryId,
                    countries: widget.countries,
                    onChanged:
                        (value) => setState(() => _awayCountryId = value),
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: TextField(
                    controller: _homeScoreController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Home score',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: TextField(
                    controller: _awayScoreController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Away score',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<FixtureStatus>(
                    value: _status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final status in FixtureStatus.values)
                        DropdownMenuItem(
                          value: status,
                          child: Text(status.name),
                        ),
                    ],
                    onChanged:
                        (value) => setState(
                          () => _status = value ?? FixtureStatus.scheduled,
                        ),
                  ),
                ),
                SizedBox(
                  width: 280,
                  child: TextField(
                    controller: _venueNameController,
                    decoration: const InputDecoration(
                      labelText: 'Venue name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(
                  width: 280,
                  child: TextField(
                    controller: _venueCityController,
                    decoration: const InputDecoration(
                      labelText: 'Venue city',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(
                  width: 280,
                  child: _CountryDropdown(
                    label: 'Winner',
                    value: _winnerCountryId ?? fixture.winnerCountryId,
                    countries: _winnerOptions,
                    onChanged:
                        (value) => setState(() => _winnerCountryId = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : () => _save(fixture),
                icon:
                    _isSaving
                        ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.save_outlined),
                label: const Text('Save result and recalculate'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Fixture? get _selectedFixture {
    final fixture =
        widget.fixtures.where((item) => item.id == _fixtureId).firstOrNull;
    if (fixture != null &&
        _homeScoreController.text.isEmpty &&
        _awayScoreController.text.isEmpty) {
      _loadFixture(fixture);
    }
    return fixture;
  }

  List<Country> get _winnerOptions {
    final ids = {
      if ((_homeCountryId ?? _selectedFixture?.homeCountryId) != null)
        _homeCountryId ?? _selectedFixture!.homeCountryId!,
      if ((_awayCountryId ?? _selectedFixture?.awayCountryId) != null)
        _awayCountryId ?? _selectedFixture!.awayCountryId!,
    };
    return widget.countries
        .where((country) => ids.contains(country.id))
        .toList();
  }

  void _loadFixture(Fixture fixture) {
    _fixtureId = fixture.id;
    _homeCountryId = fixture.homeCountryId;
    _awayCountryId = fixture.awayCountryId;
    _winnerCountryId = fixture.winnerCountryId;
    _status = fixture.status;
    _kickoffController.text = fixture.kickoff.toIso8601String();
    _homeScoreController.text = fixture.homeScore?.toString() ?? '';
    _awayScoreController.text = fixture.awayScore?.toString() ?? '';
    _venueNameController.text = fixture.venueName ?? '';
    _venueCityController.text = fixture.venueCity ?? '';
  }

  Future<void> _save(Fixture fixture) async {
    final kickoff = DateTime.tryParse(_kickoffController.text.trim());
    if (kickoff == null) {
      _showSnack('Enter a valid ISO kickoff date/time.');
      return;
    }
    final updated = fixture.copyWith(
      kickoff: kickoff,
      homeCountryId: _homeCountryId ?? fixture.homeCountryId,
      awayCountryId: _awayCountryId ?? fixture.awayCountryId,
      homeScore: int.tryParse(_homeScoreController.text.trim()),
      awayScore: int.tryParse(_awayScoreController.text.trim()),
      winnerCountryId: _winnerCountryId ?? fixture.winnerCountryId,
      venueName: _venueNameController.text.trim(),
      venueCity: _venueCityController.text.trim(),
      status: _status,
    );
    final validationError = AdminValidators.validateFixtureResult(updated);
    if (validationError != null) {
      _showSnack(validationError);
      return;
    }
    final note =
        fixture.status == FixtureStatus.finished
            ? await _confirmAdminChange(
              context,
              title: 'Correct finished result?',
              body:
                  'This game is already finished. Saving will overwrite the result, write an audit entry, and recalculate the leaderboard.',
              requireNote: false,
            )
            : null;
    if (!mounted ||
        (fixture.status == FixtureStatus.finished && note == null)) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      await ref
          .read(appRepositoryProvider)
          .saveFixtureResult(updated, note: note);
      _showSnack('Result saved and leaderboard recalculated.');
    } catch (error) {
      _showSnack('Save failed: $error');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _AdminStandingsSection extends ConsumerStatefulWidget {
  const _AdminStandingsSection({
    required this.countries,
    required this.standings,
  });

  final List<Country> countries;
  final List<GroupStanding> standings;

  @override
  ConsumerState<_AdminStandingsSection> createState() =>
      _AdminStandingsSectionState();
}

class _AdminStandingsSectionState
    extends ConsumerState<_AdminStandingsSection> {
  bool _isRecalculating = false;
  String? _savingGroupId;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Group Standings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Stats are calculated from finished group games. Use up/down controls only to override ranking order for tiebreakers.',
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: _isRecalculating ? null : _recalculate,
                icon:
                    _isRecalculating
                        ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.refresh),
                label: const Text('Recalculate standings'),
              ),
            ),
            const SizedBox(height: 16),
            for (final standing in widget.standings) _groupCard(standing),
          ],
        ),
      ),
    );
  }

  Widget _groupCard(GroupStanding standing) {
    final countryById = {
      for (final country in widget.countries) country.id: country,
    };
    final isSaving = _savingGroupId == standing.groupId;
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Group ${standing.groupId}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (standing.overrideOrderCountryIds.isNotEmpty)
                  const Chip(label: Text('Override active')),
              ],
            ),
            const SizedBox(height: 8),
            for (var index = 0; index < standing.rows.length; index++)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  child: Text('${standing.rows[index].rank}'),
                ),
                title: Text(
                  _countryName(
                    context,
                    countryById[standing.rows[index].countryId],
                  ),
                ),
                subtitle: Text(
                  'Pts ${standing.rows[index].points} | GD ${standing.rows[index].goalDifference} | P ${standing.rows[index].played}',
                ),
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    IconButton(
                      tooltip: 'Move up',
                      onPressed:
                          isSaving || index == 0
                              ? null
                              : () => _move(standing, index, -1),
                      icon: const Icon(Icons.arrow_upward),
                    ),
                    IconButton(
                      tooltip: 'Move down',
                      onPressed:
                          isSaving || index == standing.rows.length - 1
                              ? null
                              : () => _move(standing, index, 1),
                      icon: const Icon(Icons.arrow_downward),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _recalculate() async {
    setState(() => _isRecalculating = true);
    try {
      final summary = await ref
          .read(appRepositoryProvider)
          .recalculateStandings(note: 'Manual standings refresh');
      _showSnack('Updated ${summary.groupsUpdated} groups.');
    } catch (error) {
      _showSnack('Recalculate failed: $error');
    } finally {
      if (mounted) setState(() => _isRecalculating = false);
    }
  }

  Future<void> _move(GroupStanding standing, int index, int delta) async {
    final rows = [...standing.rows];
    final nextIndex = index + delta;
    final row = rows.removeAt(index);
    rows.insert(nextIndex, row);
    setState(() => _savingGroupId = standing.groupId);
    try {
      await ref
          .read(appRepositoryProvider)
          .saveStandingOverrideOrder(
            groupId: standing.groupId,
            countryIds: rows.map((row) => row.countryId).toList(),
            note: 'Admin ranking override',
          );
      _showSnack('Group ${standing.groupId} order updated.');
    } catch (error) {
      _showSnack('Override failed: $error');
    } finally {
      if (mounted) setState(() => _savingGroupId = null);
    }
  }

  String _countryName(BuildContext context, Country? country) {
    return country == null ? 'TBD' : countryDisplayName(context, country);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _GroupAdvancersSection extends ConsumerStatefulWidget {
  const _GroupAdvancersSection({
    required this.countries,
    required this.standings,
    required this.officialResults,
  });

  final List<Country> countries;
  final List<GroupStanding> standings;
  final OfficialResults officialResults;

  @override
  ConsumerState<_GroupAdvancersSection> createState() =>
      _GroupAdvancersSectionState();
}

class _GroupAdvancersSectionState
    extends ConsumerState<_GroupAdvancersSection> {
  final _firstByGroup = <String, String?>{};
  final _secondByGroup = <String, String?>{};
  final _thirdByGroup = <String, String?>{};
  final _bestThirdGroupIds = <String>{};
  bool _initialized = false;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      _loadExistingPlacements();
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Confirm Group Advancers',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Select first, second, and third in each group. Then mark exactly 8 third-place teams as advancing. Selected advancers: ${_advancerCount()} / 32.',
            ),
            const SizedBox(height: 16),
            for (final groupId in BracketRules.groupIds) _groupCard(groupId),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon:
                    _isSaving
                        ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.check_circle_outline),
                label: const Text('Save group advancers and recalculate'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _groupCard(String groupId) {
    final countries = _countriesForGroup(groupId);
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Group $groupId',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 260,
                  child: _CountryDropdown(
                    label: '1st place',
                    value: _firstByGroup[groupId],
                    countries: countries,
                    onChanged:
                        (value) =>
                            setState(() => _firstByGroup[groupId] = value),
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: _CountryDropdown(
                    label: '2nd place',
                    value: _secondByGroup[groupId],
                    countries: countries,
                    onChanged:
                        (value) =>
                            setState(() => _secondByGroup[groupId] = value),
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: _CountryDropdown(
                    label: '3rd place',
                    value: _thirdByGroup[groupId],
                    countries: countries,
                    onChanged:
                        (value) =>
                            setState(() => _thirdByGroup[groupId] = value),
                  ),
                ),
                FilterChip(
                  label: const Text('Best third advances'),
                  selected: _bestThirdGroupIds.contains(groupId),
                  onSelected:
                      (selected) => setState(() {
                        if (selected) {
                          _bestThirdGroupIds.add(groupId);
                        } else {
                          _bestThirdGroupIds.remove(groupId);
                        }
                      }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _loadExistingPlacements() {
    final placements = widget.officialResults.groupPlacements;
    if (placements != null) {
      for (final pick in placements.groupPicks) {
        _firstByGroup[pick.groupId] = pick.firstCountryId;
        _secondByGroup[pick.groupId] = pick.secondCountryId;
        _thirdByGroup[pick.groupId] = pick.thirdCountryId;
      }
      _bestThirdGroupIds
        ..clear()
        ..addAll(placements.bestThirdGroupIds);
    } else {
      for (final standing in widget.standings) {
        if (standing.rows.length >= 3) {
          _firstByGroup[standing.groupId] = standing.rows[0].countryId;
          _secondByGroup[standing.groupId] = standing.rows[1].countryId;
          _thirdByGroup[standing.groupId] = standing.rows[2].countryId;
        }
      }
    }
    _initialized = true;
  }

  List<Country> _countriesForGroup(String groupId) {
    final ids = BracketRules.groupCountryIds[groupId] ?? const <String>[];
    return [
      for (final id in ids)
        if (widget.countries.where((country) => country.id == id).firstOrNull
            case final country?)
          country,
    ];
  }

  int _advancerCount() {
    return OfficialGroupPlacements(
      groupPicks: _groupPicks(),
      bestThirdGroupIds: _bestThirdGroupIds.toList(),
    ).advancingCountryIds.length;
  }

  List<GroupPick> _groupPicks() {
    return [
      for (final groupId in BracketRules.groupIds)
        GroupPick(
          groupId: groupId,
          firstCountryId: _firstByGroup[groupId] ?? '',
          secondCountryId: _secondByGroup[groupId] ?? '',
          thirdCountryId: _thirdByGroup[groupId],
        ),
    ];
  }

  Future<void> _save() async {
    final placements = OfficialGroupPlacements(
      groupPicks: _groupPicks(),
      bestThirdGroupIds: _bestThirdGroupIds.toList()..sort(),
    );
    final validationError = AdminValidators.validateGroupPlacements(placements);
    if (validationError != null) {
      _showSnack(validationError);
      return;
    }
    final note = await _confirmAdminChange(
      context,
      title: 'Save official group advancers?',
      body:
          'This will replace the official group-stage scoring inputs and recalculate the leaderboard.',
      requireNote: false,
    );
    if (!mounted || note == null) return;
    setState(() => _isSaving = true);
    try {
      await ref
          .read(appRepositoryProvider)
          .saveGroupAdvancers(placements, note: note);
      _showSnack('Group advancers saved and leaderboard recalculated.');
    } catch (error) {
      _showSnack('Save failed: $error');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _RecalculateLeaderboardSection extends ConsumerStatefulWidget {
  const _RecalculateLeaderboardSection({required this.officialResults});

  final OfficialResults officialResults;

  @override
  ConsumerState<_RecalculateLeaderboardSection> createState() =>
      _RecalculateLeaderboardSectionState();
}

class _RecalculateLeaderboardSectionState
    extends ConsumerState<_RecalculateLeaderboardSection> {
  bool _isRunning = false;

  @override
  Widget build(BuildContext context) {
    final lastRun = widget.officialResults.leaderboardUpdatedAt;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recalculate Leaderboard',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              lastRun == null
                  ? 'The leaderboard has not been recalculated from official results yet.'
                  : 'Last recalculated: ${DateFormat.yMMMd().add_jm().format(lastRun.toLocal())}',
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isRunning ? null : _run,
              icon:
                  _isRunning
                      ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.refresh),
              label: const Text('Recalculate now'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _run() async {
    final note = await _confirmAdminChange(
      context,
      title: 'Recalculate leaderboard?',
      body:
          'This will rescore all submitted brackets from the current official results.',
      requireNote: false,
    );
    if (!mounted || note == null) return;
    setState(() => _isRunning = true);
    try {
      final summary = await ref
          .read(appRepositoryProvider)
          .recalculateLeaderboard(note: note);
      _showSnack('Updated ${summary.entriesUpdated} leaderboard entries.');
    } catch (error) {
      _showSnack('Recalculation failed: $error');
    } finally {
      if (mounted) setState(() => _isRunning = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ApiFootballSyncSection extends ConsumerStatefulWidget {
  const _ApiFootballSyncSection();

  @override
  ConsumerState<_ApiFootballSyncSection> createState() =>
      _ApiFootballSyncSectionState();
}

class _ApiFootballSyncSectionState extends ConsumerState<_ApiFootballSyncSection> {
  bool _isSyncing = false;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final syncState = ref.watch(apiFootballSyncStateProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              strings.apiFootballSync,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(strings.apiFootballSyncBody),
            const SizedBox(height: 16),
            syncState.when(
              data: (state) => _SyncStateDetails(state: state),
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => Text('Sync state error: $error'),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isSyncing ? null : _syncNow,
              icon:
                  _isSyncing
                      ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.sync),
              label: Text(strings.syncNow),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _syncNow() async {
    final confirmed = await _confirmAdminChange(
      context,
      title: 'Run score sync now?',
      body:
          'This pulls live scores from football-data.org for games without manual admin overrides. Admin-entered results always win. You must be signed in with rgw1985@hotmail.com.',
      requireNote: false,
    );
    if (!mounted || confirmed == null) return;
    setState(() => _isSyncing = true);
    try {
      final summary = await ref
          .read(appRepositoryProvider)
          .triggerApiFootballSync();
      _showSnack(
        'Sync finished: ${summary.fixturesUpdated} updated of '
        '${summary.apiFixturesReceived} API games '
        '(${summary.skippedUnchanged} unchanged, '
        '${summary.skippedUnmatched} unmatched, '
        '${summary.skippedAdmin} admin). '
        'Local fixtures: ${summary.localFixturesLoaded}, '
        'countries mapped: ${summary.countriesWithApiId}.',
      );
    } catch (error) {
      _showSnack('Sync failed: $error');
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SyncStateDetails extends StatelessWidget {
  const _SyncStateDetails({required this.state});

  final ApiFootballSyncState state;

  @override
  Widget build(BuildContext context) {
    final lastSync = state.lastSyncAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lastSync == null
              ? 'No API sync has run yet.'
              : 'Last sync: ${DateFormat.yMMMd().add_jm().format(lastSync.toLocal())}'
                  '${state.source == null ? '' : ' (${state.source})'}',
        ),
        if (state.lastError != null && state.lastError!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Last error: ${state.lastError}',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        if (lastSync != null) ...[
          const SizedBox(height: 8),
          Text(
            'API returned ${state.apiFixturesReceived} games for '
            '${state.localFixturesLoaded} local fixtures. '
            'Updated ${state.fixturesUpdated}, '
            '${state.skippedUnchanged} unchanged, '
            '${state.skippedUnmatched} unmatched, '
            '${state.skippedAdmin} admin overrides. '
            'Countries mapped: ${state.countriesWithApiId}'
            '${state.countriesEnrichedFromApi > 0 ? ' (+${state.countriesEnrichedFromApi} from API names)' : ''}.',
          ),
        ],
      ],
    );
  }
}

class _ContestSettingsSection extends ConsumerStatefulWidget {
  const _ContestSettingsSection({required this.config});

  final GlobalContestConfig config;

  @override
  ConsumerState<_ContestSettingsSection> createState() =>
      _ContestSettingsSectionState();
}

class _ContestSettingsSectionState
    extends ConsumerState<_ContestSettingsSection> {
  final _lockAtController = TextEditingController();
  bool _initialized = false;
  bool _isSavingLockAt = false;
  bool _isSavingSubmissions = false;

  @override
  void dispose() {
    _lockAtController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _ContestSettingsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config.lockAt != widget.config.lockAt && !_isSavingLockAt) {
      _lockAtController.text = widget.config.lockAt.toIso8601String();
    }
  }

  bool get _isSaving => _isSavingLockAt || _isSavingSubmissions;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    if (!_initialized) {
      _lockAtController.text = widget.config.lockAt.toIso8601String();
      _initialized = true;
    }
    final statusMessage = adminSubmissionStatusMessage(strings, widget.config);
    final statusHint = adminSubmissionStatusHint(strings, widget.config);
    final statusColor =
        widget.config.areSubmissionsOpen
            ? DashboardColors.emerald
            : DashboardColors.gold;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Manage Contest Settings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'The submissions switch saves immediately. Lock time saves separately below.',
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withValues(alpha: 0.45)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusMessage,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(statusHint, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: widget.config.isAcceptingSubmissions,
              title: const Text('Accepting submissions'),
              subtitle: const Text('Saves immediately when changed'),
              onChanged: _isSaving ? null : _onAcceptingSubmissionsChanged,
            ),
            if (_isSavingSubmissions)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: LinearProgressIndicator(),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _lockAtController,
              decoration: InputDecoration(
                labelText: 'Lock at (ISO date/time)',
                helperText: 'Example: 2026-06-11T19:00:00.000Z',
                border: const OutlineInputBorder(),
                suffixIcon:
                    _isSavingLockAt
                        ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                        : null,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _saveLockAt,
                icon: const Icon(Icons.schedule),
                label: Text(strings.saveLockTime),
              ),
            ),
            const SizedBox(height: 12),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Scoring rules'),
              subtitle: Text(
                'Groups: +1 if your pick finishes top 3, +2 extra for the exact spot.\n'
                'Knockouts: Round of 32 = 1 pt, Round of 16 = 2, QF = 4, SF = 8, Final = 16.',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onAcceptingSubmissionsChanged(bool value) async {
    final strings = context.strings;
    final lockAtLabel = widget.config.lockAt.toLocal().toString();
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              value ? strings.openSubmissionsTitle : strings.closeSubmissionsTitle,
            ),
            content: Text(
              value
                  ? strings.openSubmissionsBody(lockAtLabel)
                  : strings.closeSubmissionsBody,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(value ? 'Open' : 'Close'),
              ),
            ],
          ),
    );
    if (!mounted || confirmed != true) {
      return;
    }

    setState(() => _isSavingSubmissions = true);
    try {
      await ref
          .read(appRepositoryProvider)
          .updateContestConfig(
            widget.config.copyWith(isAcceptingSubmissions: value),
            note: value ? 'Submissions reopened' : 'Submissions closed',
          );
      if (!mounted) return;
      _showSnack(
        value ? 'Submissions are now open.' : 'Submissions are now closed.',
      );
    } catch (error) {
      _showSnack('Could not update submissions: $error');
    } finally {
      if (mounted) setState(() => _isSavingSubmissions = false);
    }
  }

  Future<void> _saveLockAt() async {
    final lockAt = DateTime.tryParse(_lockAtController.text.trim());
    if (lockAt == null) {
      _showSnack('Enter a valid ISO lock time.');
      return;
    }
    final normalizedLockAt = lockAt.toUtc();
    final note = await _confirmAdminChange(
      context,
      title: 'Save lock time?',
      body:
          'Players ${widget.config.isAcceptingSubmissions ? 'can' : 'cannot'} '
          'submit now. New lock: ${normalizedLockAt.toLocal()}.',
      requireNote: false,
    );
    if (!mounted || note == null) return;

    setState(() => _isSavingLockAt = true);
    try {
      await ref
          .read(appRepositoryProvider)
          .updateContestConfig(
            widget.config.copyWith(lockAt: normalizedLockAt),
            note: note,
          );
      if (!mounted) return;
      _showSnack('Lock time saved.');
    } catch (error) {
      _showSnack('Save failed: $error');
    } finally {
      if (mounted) setState(() => _isSavingLockAt = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _AuditLogSection extends StatelessWidget {
  const _AuditLogSection({required this.logs});

  final List<AdminAuditLog> logs;

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No admin audit entries yet.'),
        ),
      );
    }
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: logs.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final log = logs[index];
          return ListTile(
            leading: const Icon(Icons.history),
            title: Text(log.operationType.name),
            subtitle: Text(
              '${DateFormat.yMMMd().add_jm().format(log.createdAt.toLocal())}\n${log.note ?? 'No note'}',
            ),
            isThreeLine: true,
          );
        },
      ),
    );
  }
}

class _CountryDropdown extends StatelessWidget {
  const _CountryDropdown({
    required this.label,
    required this.value,
    required this.countries,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<Country> countries;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final values = countries.map((country) => country.id).toSet();
    return DropdownButtonFormField<String>(
      value: values.contains(value) ? value : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final country in countries)
          DropdownMenuItem(
            value: country.id,
            child: Text(countryDisplayName(context, country)),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

Future<String?> _confirmAdminChange(
  BuildContext context, {
  required String title,
  required String body,
  required bool requireNote,
}) async {
  final noteController = TextEditingController();
  final result = await showDialog<String?>(
    context: context,
    builder:
        (context) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(body),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: requireNote ? 'Required audit note' : 'Audit note',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final note = noteController.text.trim();
                if (requireNote && note.isEmpty) {
                  return;
                }
                Navigator.of(context).pop(note);
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
  );
  noteController.dispose();
  return result;
}

class _AdminSignInGate extends ConsumerStatefulWidget {
  const _AdminSignInGate();

  @override
  ConsumerState<_AdminSignInGate> createState() => _AdminSignInGateState();
}

class _AdminSignInGateState extends ConsumerState<_AdminSignInGate> {
  final _emailController = TextEditingController(text: AdminAccess.adminEmail);
  final _passwordController = TextEditingController();
  String? _error;
  String? _status;
  bool _isSigningIn = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 48),
                const SizedBox(height: 16),
                Text(
                  strings.adminLogin,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  strings.adminAccessDeniedBody,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: strings.adminEmail,
                    helperText: strings.adminEmailLocked,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: strings.password,
                    errorText: _error,
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _signIn(),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _isSigningIn ? null : _signIn,
                  child:
                      _isSigningIn
                          ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : Text(strings.signIn),
                ),
                if (_status != null) ...[
                  const SizedBox(height: 12),
                  Text(_status!, textAlign: TextAlign.center),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signIn() async {
    final strings = context.strings;
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() {
        _status = null;
        _error = strings.passwordRequired;
      });
      return;
    }
    setState(() {
      _error = null;
      _status = null;
      _isSigningIn = true;
    });
    try {
      await ref
          .read(appRepositoryProvider)
          .signInWithEmailAndPassword(
            email: AdminAccess.adminEmail,
            password: password,
          );
      ref.invalidate(currentUserProvider);
      if (mounted) {
        setState(() => _status = strings.adminProfileLoading);
      }
    } catch (error) {
      setState(() {
        _status = null;
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isSigningIn = false);
      }
    }
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
