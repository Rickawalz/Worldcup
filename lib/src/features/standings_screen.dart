import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/providers.dart';
import '../domain/models.dart';
import '../localization/app_strings.dart';
import '../widgets/country_badge.dart';

class StandingsScreen extends ConsumerWidget {
  const StandingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countries = ref.watch(countriesProvider);
    final fixtures = ref.watch(fixturesProvider);
    final strings = context.strings;
    return countries.when(
      data:
          (countryList) => fixtures.when(
            data:
                (fixtureList) => ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text(
                      strings.teamsFlagsFixtures,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(strings.countryDataExplainer),
                    const SizedBox(height: 16),
                    _CountryGrid(countries: countryList),
                    const SizedBox(height: 24),
                    Text(
                      strings.fixtureSyncPreview,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    for (final fixture in fixtureList)
                      _FixtureTile(fixture: fixture, countries: countryList),
                  ],
                ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Fixture error: $error')),
          ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Country error: $error')),
    );
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

class _FixtureTile extends StatelessWidget {
  const _FixtureTile({required this.fixture, required this.countries});

  final Fixture fixture;
  final List<Country> countries;

  @override
  Widget build(BuildContext context) {
    final home = _countryName(fixture.homeCountryId);
    final away = _countryName(fixture.awayCountryId);
    return Card(
      child: ListTile(
        leading: const Icon(Icons.sports_soccer),
        title: Text('${fixture.roundLabel}: $home ${context.strings.vs} $away'),
        subtitle: Text(
          DateFormat.yMMMd().add_jm().format(fixture.kickoff.toLocal()),
        ),
        trailing: Text(fixture.status.name),
      ),
    );
  }

  String _countryName(String? id) {
    if (id == null) {
      return 'TBD';
    }
    return countries
            .where((country) => country.id == id)
            .map((country) => country.name)
            .firstOrNull ??
        'TBD';
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
