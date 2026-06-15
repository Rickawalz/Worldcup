import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/providers.dart';
import '../domain/models.dart';
import '../localization/app_strings.dart';
import '../localization/country_names.dart';
import '../widgets/country_badge.dart';
import '../widgets/country_flags.dart';
import '../widgets/dashboard.dart';

class AmysCalendarScreen extends ConsumerStatefulWidget {
  const AmysCalendarScreen({this.initialDate, super.key});

  final DateTime? initialDate;

  @override
  ConsumerState<AmysCalendarScreen> createState() => _AmysCalendarScreenState();
}

class _AmysCalendarScreenState extends ConsumerState<AmysCalendarScreen> {
  DateTime? _selectedDate;
  late DateTime _focusedMonth;
  String? _selectedTeamId;
  String? _highlightedFixtureId;
  final _fixtureCardKeys = <String, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    final seed = widget.initialDate ?? DateTime.now();
    _focusedMonth = DateTime(seed.year, seed.month);
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      _focusedMonth = DateTime(date.year, date.month);
      _highlightedFixtureId = null;
    });
  }

  void _selectFixture(DateTime date, String fixtureId) {
    setState(() {
      _selectedDate = date;
      _focusedMonth = DateTime(date.year, date.month);
      _highlightedFixtureId = fixtureId;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _fixtureCardKeys[fixtureId]?.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.05,
        );
      }
    });
  }

  GlobalKey _keyForFixture(String fixtureId) {
    return _fixtureCardKeys.putIfAbsent(fixtureId, GlobalKey.new);
  }

  @override
  Widget build(BuildContext context) {
    final countries = ref.watch(countriesProvider);
    final fixtures = ref.watch(fixturesProvider);
    final strings = context.strings;

    return countries.when(
      data:
          (countryList) => fixtures.when(
            data: (fixtureList) {
              final filteredFixtures = _filterByTeam(
                fixtureList,
                _selectedTeamId,
              );
              final selectedDate =
                  _selectedDate ?? _defaultDate(filteredFixtures);
              final fixturesForDay = _fixturesForDate(
                filteredFixtures,
                selectedDate,
              );
              final fixturesByDate = _fixturesByDate(filteredFixtures);
              final teamOptions = _teamOptions(fixtureList, countryList);
              return DashboardPage(
                title: strings.amysCalendar,
                subtitle: strings.amysCalendarIntro,
                icon: Icons.calendar_month_outlined,
                stats: [
                  DashboardStat(
                    label:
                        _isToday(selectedDate)
                            ? strings.today.toLowerCase()
                            : DateFormat.MMMd().format(selectedDate),
                    value: '${fixturesForDay.length}',
                    icon: Icons.sports_soccer,
                  ),
                  DashboardStat(
                    label: strings.totalGamesLabel,
                    value: '${filteredFixtures.length}',
                    icon: Icons.event_available_outlined,
                    color: DashboardColors.sky,
                  ),
                ],
                children: [
                  _TeamFilter(
                    teamOptions: teamOptions,
                    selectedTeamId: _selectedTeamId,
                    onChanged:
                        (teamId) => setState(() {
                          _selectedTeamId = teamId;
                          _highlightedFixtureId = null;
                        }),
                  ),
                  const SizedBox(height: 12),
                  _MonthCalendar(
                    focusedMonth: _focusedMonth,
                    selectedDate: selectedDate,
                    fixturesByDate: fixturesByDate,
                    countries: countryList,
                    onMonthChanged:
                        (month) => setState(() {
                          _focusedMonth = month;
                          _highlightedFixtureId = null;
                        }),
                    onDayTap: _selectDate,
                    onFixtureChipTap: _selectFixture,
                    onTodayPressed:
                        () => setState(() {
                          final today = _dateOnly(DateTime.now());
                          _selectedDate = today;
                          _focusedMonth = DateTime(today.year, today.month);
                          _highlightedFixtureId = null;
                        }),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isToday(selectedDate)
                        ? strings.todaysGames
                        : DateFormat.yMMMMEEEEd().format(selectedDate),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  if (fixturesForDay.isEmpty)
                    _EmptyCalendarCard(message: strings.noMatchesOnDate)
                  else
                    for (final fixture in fixturesForDay)
                      _CalendarMatchCard(
                        key: _keyForFixture(fixture.id),
                        fixture: fixture,
                        countries: countryList,
                        isHighlighted: _highlightedFixtureId == fixture.id,
                      ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Game error: $error')),
          ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Country error: $error')),
    );
  }

  DateTime _defaultDate(List<Fixture> fixtures) {
    final initialDate = widget.initialDate;
    if (initialDate != null) return _dateOnly(initialDate);
    final today = _dateOnly(DateTime.now());
    if (_fixturesForDate(fixtures, today).isNotEmpty) return today;
    final futureDates =
        fixtures
            .map((fixture) => _dateOnly(fixture.kickoff.toLocal()))
            .where((date) => !date.isBefore(today))
            .toSet()
            .toList()
          ..sort();
    if (futureDates.isNotEmpty) return futureDates.first;
    return today;
  }
}

class _TeamFilter extends StatelessWidget {
  const _TeamFilter({
    required this.teamOptions,
    required this.selectedTeamId,
    required this.onChanged,
  });

  final List<Country> teamOptions;
  final String? selectedTeamId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: DropdownButtonFormField<String?>(
          isExpanded: true,
          value: selectedTeamId,
          decoration: InputDecoration(
            labelText: strings.filterByTeam,
            prefixIcon: const Icon(Icons.filter_alt_outlined),
          ),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(strings.allTeams),
            ),
            for (final country in teamOptions)
              DropdownMenuItem<String?>(
                value: country.id,
                child: CountryBadge(country: country, compact: true),
              ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _MonthCalendar extends StatefulWidget {
  const _MonthCalendar({
    required this.focusedMonth,
    required this.selectedDate,
    required this.fixturesByDate,
    required this.countries,
    required this.onMonthChanged,
    required this.onDayTap,
    required this.onFixtureChipTap,
    required this.onTodayPressed,
  });

  final DateTime focusedMonth;
  final DateTime selectedDate;
  final Map<DateTime, List<Fixture>> fixturesByDate;
  final List<Country> countries;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDayTap;
  final void Function(DateTime date, String fixtureId) onFixtureChipTap;
  final VoidCallback onTodayPressed;

  @override
  State<_MonthCalendar> createState() => _MonthCalendarState();
}

class _MobileCalendarLayout {
  static const breakpoint = 900.0;
  static const dayColumnWidth = 72.0;
  static const columnGap = 4.0;

  static double get weekWidth => dayColumnWidth * 7 + columnGap * 6;
}

class _MonthCalendarState extends State<_MonthCalendar> {
  late ScrollController _mobileScrollController;

  @override
  void initState() {
    super.initState();
    _mobileScrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelectedDay());
  }

  @override
  void didUpdateWidget(covariant _MonthCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusedMonth != widget.focusedMonth ||
        oldWidget.selectedDate != widget.selectedDate) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelectedDay());
    }
  }

  @override
  void dispose() {
    _mobileScrollController.dispose();
    super.dispose();
  }

  void _scrollToSelectedDay() {
    if (!_mobileScrollController.hasClients) {
      return;
    }
    if (MediaQuery.sizeOf(context).width >= _MobileCalendarLayout.breakpoint) {
      return;
    }
    final columnIndex = widget.selectedDate.weekday - 1;
    final columnStride =
        _MobileCalendarLayout.dayColumnWidth + _MobileCalendarLayout.columnGap;
    final target = columnIndex * columnStride;
    final maxExtent = _mobileScrollController.position.maxScrollExtent;
    _mobileScrollController.animateTo(
      target.clamp(0.0, maxExtent),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final monthLabel = DateFormat.yMMMM(locale).format(widget.focusedMonth);
    final weekdayLabels = List.generate(7, (index) {
      final date = DateTime(2024, 1, 1 + index);
      return DateFormat.E(locale).format(date);
    });
    final weeks = _monthWeeks(widget.focusedMonth);
    final isMobile =
        MediaQuery.sizeOf(context).width < _MobileCalendarLayout.breakpoint;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton.outlined(
                  tooltip: strings.previousMonth,
                  onPressed:
                      () => widget.onMonthChanged(
                        DateTime(
                          widget.focusedMonth.year,
                          widget.focusedMonth.month - 1,
                        ),
                      ),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    monthLabel,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton.outlined(
                  tooltip: strings.nextMonth,
                  onPressed:
                      () => widget.onMonthChanged(
                        DateTime(
                          widget.focusedMonth.year,
                          widget.focusedMonth.month + 1,
                        ),
                      ),
                  icon: const Icon(Icons.chevron_right),
                ),
                FilledButton.tonal(
                  onPressed: widget.onTodayPressed,
                  child: Text(strings.today),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (isMobile)
              _HorizontalEdgeFade(
                child: SingleChildScrollView(
                  controller: _mobileScrollController,
                  scrollDirection: Axis.horizontal,
                  physics: _ColumnSnapScrollPhysics(
                    columnStride:
                        _MobileCalendarLayout.dayColumnWidth +
                        _MobileCalendarLayout.columnGap,
                  ),
                  child: SizedBox(
                    width: _MobileCalendarLayout.weekWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _WeekdayHeaderRow(
                          labels: weekdayLabels,
                          mobile: true,
                        ),
                        const SizedBox(height: 8),
                        for (final week in weeks)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: _CalendarWeekRow(
                              week: week,
                              fixturesByDate: widget.fixturesByDate,
                              countries: widget.countries,
                              selectedDate: widget.selectedDate,
                              mobile: true,
                              onDayTap: widget.onDayTap,
                              onFixtureChipTap: widget.onFixtureChipTap,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              )
            else ...[
              _WeekdayHeaderRow(labels: weekdayLabels, mobile: false),
              const SizedBox(height: 8),
              for (final week in weeks)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _CalendarWeekRow(
                    week: week,
                    fixturesByDate: widget.fixturesByDate,
                    countries: widget.countries,
                    selectedDate: widget.selectedDate,
                    mobile: false,
                    onDayTap: widget.onDayTap,
                    onFixtureChipTap: widget.onFixtureChipTap,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WeekdayHeaderRow extends StatelessWidget {
  const _WeekdayHeaderRow({required this.labels, required this.mobile});

  final List<String> labels;
  final bool mobile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < labels.length; index++) ...[
          if (mobile)
            SizedBox(
              width: _MobileCalendarLayout.dayColumnWidth,
              child: Text(
                labels[index],
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            )
          else
            Expanded(
              child: Text(
                labels[index],
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          if (mobile && index < labels.length - 1)
            SizedBox(width: _MobileCalendarLayout.columnGap),
        ],
      ],
    );
  }
}

class _CalendarWeekRow extends StatelessWidget {
  const _CalendarWeekRow({
    required this.week,
    required this.fixturesByDate,
    required this.countries,
    required this.selectedDate,
    required this.mobile,
    required this.onDayTap,
    required this.onFixtureChipTap,
  });

  final List<DateTime?> week;
  final Map<DateTime, List<Fixture>> fixturesByDate;
  final List<Country> countries;
  final DateTime selectedDate;
  final bool mobile;
  final ValueChanged<DateTime> onDayTap;
  final void Function(DateTime date, String fixtureId) onFixtureChipTap;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < week.length; index++) ...[
            if (mobile)
              SizedBox(
                width: _MobileCalendarLayout.dayColumnWidth,
                child:
                    week[index] == null
                        ? const SizedBox.shrink()
                        : _CalendarDayColumn(
                          date: week[index]!,
                          fixtures: fixturesByDate[week[index]!] ?? const [],
                          countries: countries,
                          isSelected: week[index] == selectedDate,
                          isToday: week[index] == _dateOnly(DateTime.now()),
                          onDayTap: () => onDayTap(week[index]!),
                          onFixtureTap:
                              (fixtureId) =>
                                  onFixtureChipTap(week[index]!, fixtureId),
                        ),
              )
            else
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child:
                      week[index] == null
                          ? const SizedBox.shrink()
                          : _CalendarDayColumn(
                            date: week[index]!,
                            fixtures: fixturesByDate[week[index]!] ?? const [],
                            countries: countries,
                            isSelected: week[index] == selectedDate,
                            isToday: week[index] == _dateOnly(DateTime.now()),
                            onDayTap: () => onDayTap(week[index]!),
                            onFixtureTap:
                                (fixtureId) => onFixtureChipTap(
                                  week[index]!,
                                  fixtureId,
                                ),
                          ),
                ),
              ),
            if (mobile && index < week.length - 1)
              SizedBox(width: _MobileCalendarLayout.columnGap),
          ],
        ],
      ),
    );
  }
}

class _HorizontalEdgeFade extends StatelessWidget {
  const _HorizontalEdgeFade({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final fadeColor = Theme.of(context).cardColor;
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: Row(
              children: [
                Container(
                  width: 18,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [fadeColor, fadeColor.withValues(alpha: 0)],
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 18,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [fadeColor.withValues(alpha: 0), fadeColor],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ColumnSnapScrollPhysics extends ScrollPhysics {
  const _ColumnSnapScrollPhysics({required this.columnStride, super.parent});

  final double columnStride;

  @override
  _ColumnSnapScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _ColumnSnapScrollPhysics(
      columnStride: columnStride,
      parent: buildParent(ancestor),
    );
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final page = (position.pixels / columnStride).round();
    final target = (page * columnStride).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if ((target - position.pixels).abs() < tolerance.distance &&
        velocity.abs() < tolerance.velocity) {
      return null;
    }
    return ScrollSpringSimulation(
      spring,
      position.pixels,
      target,
      velocity,
      tolerance: tolerance,
    );
  }
}

class _CalendarDayColumn extends StatelessWidget {
  const _CalendarDayColumn({
    required this.date,
    required this.fixtures,
    required this.countries,
    required this.isSelected,
    required this.isToday,
    required this.onDayTap,
    required this.onFixtureTap,
  });

  final DateTime date;
  final List<Fixture> fixtures;
  final List<Country> countries;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onDayTap;
  final ValueChanged<String> onFixtureTap;

  static const _visibleEventLimit = 2;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = context.strings;
    final background =
        isSelected
            ? DashboardColors.emerald.withValues(alpha: 0.22)
            : isToday
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55)
            : const Color(0x33142533);
    final visibleFixtures = fixtures.take(_visibleEventLimit).toList();
    final hiddenCount = fixtures.length - visibleFixtures.length;

    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color:
              isSelected
                  ? DashboardColors.gold.withValues(alpha: 0.85)
                  : isToday
                  ? DashboardColors.gold.withValues(alpha: 0.45)
                  : const Color(0x22FFFFFF),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onDayTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(3, 4, 3, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  '${date.day}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? DashboardColors.gold : null,
                  ),
                ),
              ),
              if (fixtures.isNotEmpty) ...[
                const SizedBox(height: 2),
                for (final fixture in visibleFixtures)
                  _CalendarEventBlock(
                    fixture: fixture,
                    countries: countries,
                    onTap: () => onFixtureTap(fixture.id),
                  ),
                if (hiddenCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      strings.moreGames(hiddenCount),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: DashboardColors.gold,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ] else
                const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalendarEventBlock extends StatelessWidget {
  const _CalendarEventBlock({
    required this.fixture,
    required this.countries,
    required this.onTap,
  });

  final Fixture fixture;
  final List<Country> countries;
  final VoidCallback onTap;

  static const _timeFontSize = 12.0;
  static const _matchupFontSize = 12.0;

  @override
  Widget build(BuildContext context) {
    final colors = _chipColors(fixture);
    final time = DateFormat.jm().format(fixture.kickoff.toLocal());
    final matchup = _flagMatchupLabel(fixture, countries);

    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Material(
        color: colors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: colors.border, width: colors.borderWidth),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  time,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: _timeFontSize,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    color: colors.foreground.withValues(alpha: 0.95),
                  ),
                ),
                Text(
                  matchup,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: _matchupFontSize,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    color: colors.foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChipColors {
  const _ChipColors({
    required this.background,
    required this.border,
    required this.foreground,
    this.borderWidth = 1,
  });

  final Color background;
  final Color border;
  final Color foreground;
  final double borderWidth;
}

class _CalendarMatchCard extends StatelessWidget {
  const _CalendarMatchCard({
    required this.fixture,
    required this.countries,
    this.isHighlighted = false,
    super.key,
  });

  final Fixture fixture;
  final List<Country> countries;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final home = _country(fixture.homeCountryId);
    final away = _country(fixture.awayCountryId);
    final hasScore = fixture.homeScore != null && fixture.awayScore != null;
    final winner = _country(fixture.winnerCountryId);
    final metadata = [
      fixture.roundLabel,
      '${strings.matchStatus}: ${_statusLabel(strings, fixture.status)}',
      if (fixture.venueLabel != null) '${strings.venue}: ${fixture.venueLabel}',
      if (winner != null)
        '${strings.winnerLabel}: ${countryDisplayName(context, winner)}',
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side:
            isHighlighted
                ? BorderSide(color: DashboardColors.gold, width: 2)
                : BorderSide.none,
      ),
      color:
          isHighlighted
              ? DashboardColors.gold.withValues(alpha: 0.08)
              : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  DateFormat.jm().format(fixture.kickoff.toLocal()),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _TeamLabel(country: home)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    hasScore
                        ? '${fixture.homeScore}-${fixture.awayScore}'
                        : strings.vs,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _TeamLabel(country: away),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final item in metadata)
                  Chip(label: Text(item), visualDensity: VisualDensity.compact),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Country? _country(String? countryId) {
    if (countryId == null) return null;
    return countries.where((country) => country.id == countryId).firstOrNull;
  }
}

class _TeamLabel extends StatelessWidget {
  const _TeamLabel({required this.country, this.compact = false});

  final Country? country;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final team = country;
    if (team == null) {
      return Text(
        context.strings.tbd,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      );
    }
    return CountryBadge(country: team, compact: compact);
  }
}

class _EmptyCalendarCard extends StatelessWidget {
  const _EmptyCalendarCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(child: Text(message)),
      ),
    );
  }
}

_ChipColors _chipColors(Fixture fixture) {
  final isKnockout = fixture.stage != TournamentStage.group;
  if (fixture.status == FixtureStatus.live) {
    return _ChipColors(
      background: DashboardColors.gold.withValues(alpha: 0.22),
      border: DashboardColors.gold,
      foreground: Colors.white,
      borderWidth: 1.5,
    );
  }
  if (fixture.status == FixtureStatus.finished) {
    return _ChipColors(
      background:
          isKnockout
              ? DashboardColors.sky.withValues(alpha: 0.18)
              : DashboardColors.emerald.withValues(alpha: 0.18),
      border: const Color(0x44FFFFFF),
      foreground: const Color(0xFFB8C6CF),
    );
  }
  if (isKnockout) {
    return _ChipColors(
      background: DashboardColors.sky.withValues(alpha: 0.28),
      border: DashboardColors.sky.withValues(alpha: 0.55),
      foreground: Colors.white,
    );
  }
  return _ChipColors(
    background: DashboardColors.emerald.withValues(alpha: 0.32),
    border: DashboardColors.emerald.withValues(alpha: 0.65),
    foreground: Colors.white,
  );
}

String _flagMatchupLabel(Fixture fixture, List<Country> countries) {
  final countryById = {for (final country in countries) country.id: country};
  final home = countryById[fixture.homeCountryId];
  final away = countryById[fixture.awayCountryId];
  final homeToken = _teamToken(home);
  final awayToken = _teamToken(away);
  if (fixture.homeScore != null && fixture.awayScore != null) {
    return '$homeToken ${fixture.homeScore}-${fixture.awayScore} $awayToken';
  }
  return '$homeToken · $awayToken';
}

String _teamToken(Country? country) {
  if (country == null) {
    return 'TBD';
  }
  final emoji = flagEmoji(country);
  if (emoji == null) {
    return country.abbreviation;
  }
  return '$emoji ${country.abbreviation}';
}

List<List<DateTime?>> _monthWeeks(DateTime month) {
  final firstDay = DateTime(month.year, month.month, 1);
  final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
  final cells = <DateTime?>[];
  for (var index = 0; index < firstDay.weekday - 1; index++) {
    cells.add(null);
  }
  for (var day = 1; day <= daysInMonth; day++) {
    cells.add(DateTime(month.year, month.month, day));
  }
  while (cells.length % 7 != 0) {
    cells.add(null);
  }
  return [
    for (var index = 0; index < cells.length; index += 7)
      cells.sublist(index, index + 7),
  ];
}

Map<DateTime, List<Fixture>> _fixturesByDate(List<Fixture> fixtures) {
  final grouped = <DateTime, List<Fixture>>{};
  for (final fixture in fixtures) {
    final date = _dateOnly(fixture.kickoff.toLocal());
    grouped.putIfAbsent(date, () => []).add(fixture);
  }
  for (final entry in grouped.entries) {
    entry.value.sort((a, b) => a.kickoff.compareTo(b.kickoff));
  }
  return grouped;
}

List<Fixture> _filterByTeam(List<Fixture> fixtures, String? teamId) {
  if (teamId == null) {
    return fixtures;
  }
  return fixtures
      .where(
        (fixture) =>
            fixture.homeCountryId == teamId || fixture.awayCountryId == teamId,
      )
      .toList();
}

List<Country> _teamOptions(List<Fixture> fixtures, List<Country> countries) {
  final countryIds =
      fixtures
          .expand((fixture) => [fixture.homeCountryId, fixture.awayCountryId])
          .whereType<String>()
          .toSet();
  final countryById = {for (final country in countries) country.id: country};
  return countryIds.map((id) => countryById[id]).whereType<Country>().toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
}

List<Fixture> _fixturesForDate(List<Fixture> fixtures, DateTime selectedDate) {
  return fixtures
      .where((fixture) => _dateOnly(fixture.kickoff.toLocal()) == selectedDate)
      .toList()
    ..sort((a, b) => a.kickoff.compareTo(b.kickoff));
}

DateTime _dateOnly(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

bool _isToday(DateTime date) => date == _dateOnly(DateTime.now());

String _statusLabel(AppStrings strings, FixtureStatus status) {
  return switch (status) {
    FixtureStatus.scheduled => strings.isSpanish ? 'Programado' : 'Scheduled',
    FixtureStatus.live => strings.isSpanish ? 'En vivo' : 'Live',
    FixtureStatus.finished => strings.isSpanish ? 'Finalizado' : 'Finished',
    FixtureStatus.postponed => strings.isSpanish ? 'Pospuesto' : 'Postponed',
  };
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
