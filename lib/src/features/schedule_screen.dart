import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/providers.dart';
import '../domain/models.dart';
import '../localization/app_strings.dart';
import '../localization/country_names.dart';
import '../widgets/country_badge.dart';
import '../widgets/dashboard.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({this.initialDate, super.key});

  final DateTime? initialDate;

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    final countries = ref.watch(countriesProvider);
    final fixtures = ref.watch(fixturesProvider);
    final strings = context.strings;

    return countries.when(
      data:
          (countryList) => fixtures.when(
            data: (fixtureList) {
              final selectedDate = _selectedDate ?? _defaultDate(fixtureList);
              final fixturesForDay = _fixturesForDate(
                fixtureList,
                selectedDate,
              );
              final dateRange = _dateRange(fixtureList);
              return DashboardPage(
                title: strings.schedule,
                subtitle: strings.scheduleIntro,
                icon: Icons.calendar_month_outlined,
                stats: [
                  DashboardStat(
                    label:
                        _isToday(selectedDate)
                            ? 'today'
                            : DateFormat.MMMd().format(selectedDate),
                    value: '${fixturesForDay.length}',
                    icon: Icons.sports_soccer,
                  ),
                  DashboardStat(
                    label: 'total games',
                    value: '${fixtureList.length}',
                    icon: Icons.event_available_outlined,
                    color: DashboardColors.sky,
                  ),
                ],
                children: [
                  _DateControls(
                    selectedDate: selectedDate,
                    firstDate: dateRange.$1,
                    lastDate: dateRange.$2,
                    onDateChanged:
                        (date) => setState(() => _selectedDate = date),
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
                    _EmptyScheduleCard(message: strings.noMatchesOnDate)
                  else
                    for (final fixture in fixturesForDay)
                      _ScheduleMatchCard(
                        fixture: fixture,
                        countries: countryList,
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

class _DateControls extends StatelessWidget {
  const _DateControls({
    required this.selectedDate,
    required this.firstDate,
    required this.lastDate,
    required this.onDateChanged,
  });

  final DateTime selectedDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onDateChanged;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            IconButton.outlined(
              tooltip: strings.previousDay,
              onPressed:
                  selectedDate.isAfter(firstDate)
                      ? () => onDateChanged(
                        selectedDate.subtract(const Duration(days: 1)),
                      )
                      : null,
              icon: const Icon(Icons.chevron_left),
            ),
            OutlinedButton.icon(
              onPressed: () => _showDatePicker(context),
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text(DateFormat.yMMMd().format(selectedDate)),
            ),
            IconButton.outlined(
              tooltip: strings.nextDay,
              onPressed:
                  selectedDate.isBefore(lastDate)
                      ? () => onDateChanged(
                        selectedDate.add(const Duration(days: 1)),
                      )
                      : null,
              icon: const Icon(Icons.chevron_right),
            ),
            FilledButton.tonal(
              onPressed: () => onDateChanged(_dateOnly(DateTime.now())),
              child: Text(strings.today),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.clampDate(firstDate, lastDate),
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: context.strings.chooseDate,
    );
    if (picked != null) {
      onDateChanged(_dateOnly(picked));
    }
  }
}

class _ScheduleMatchCard extends StatelessWidget {
  const _ScheduleMatchCard({required this.fixture, required this.countries});

  final Fixture fixture;
  final List<Country> countries;

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
  const _TeamLabel({required this.country});

  final Country? country;

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
    return CountryBadge(country: team, compact: true);
  }
}

class _EmptyScheduleCard extends StatelessWidget {
  const _EmptyScheduleCard({required this.message});

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

List<Fixture> _fixturesForDate(List<Fixture> fixtures, DateTime selectedDate) {
  return fixtures
      .where((fixture) => _dateOnly(fixture.kickoff.toLocal()) == selectedDate)
      .toList()
    ..sort((a, b) => a.kickoff.compareTo(b.kickoff));
}

(DateTime, DateTime) _dateRange(List<Fixture> fixtures) {
  if (fixtures.isEmpty) {
    final today = _dateOnly(DateTime.now());
    return (today, today.add(const Duration(days: 365)));
  }
  final sorted = [...fixtures]..sort((a, b) => a.kickoff.compareTo(b.kickoff));
  final first = _dateOnly(sorted.first.kickoff.toLocal());
  final last = _dateOnly(sorted.last.kickoff.toLocal());
  final today = _dateOnly(DateTime.now());
  return (
    first.isBefore(today) ? first : today,
    last.isAfter(today) ? last : today,
  );
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

extension _ClampDate on DateTime {
  DateTime clampDate(DateTime firstDate, DateTime lastDate) {
    if (isBefore(firstDate)) return firstDate;
    if (isAfter(lastDate)) return lastDate;
    return this;
  }
}
