import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_cup_bracket/src/data/providers.dart';
import 'package:world_cup_bracket/src/domain/models.dart';
import 'package:world_cup_bracket/src/features/schedule_screen.dart';
import 'package:world_cup_bracket/src/localization/app_strings.dart';

void main() {
  testWidgets('shows matches for the selected local date', (tester) async {
    await tester.pumpWidget(
      _scheduleTestApp(
        initialDate: DateTime(2026, 6, 11),
        fixtures: [
          Fixture(
            id: 'm1',
            externalId: '1',
            stage: TournamentStage.group,
            roundLabel: 'Group A',
            kickoff: DateTime(2026, 6, 11, 19),
            status: FixtureStatus.scheduled,
            homeCountryId: 'mexico',
            awayCountryId: 'south_africa',
            venueName: 'Mexico City Stadium',
            venueCity: 'Mexico City',
          ),
          Fixture(
            id: 'm2',
            externalId: '2',
            stage: TournamentStage.group,
            roundLabel: 'Group B',
            kickoff: DateTime(2026, 6, 12, 19),
            status: FixtureStatus.scheduled,
            homeCountryId: 'canada',
            awayCountryId: 'usa',
          ),
        ],
      ),
    );
    await tester.pump();

    expect(find.text('Schedule'), findsOneWidget);
    expect(find.textContaining('Mexico'), findsWidgets);
    expect(find.textContaining('South Africa'), findsWidgets);
    expect(find.textContaining('Mexico City Stadium'), findsOneWidget);
    expect(find.textContaining('Canada'), findsNothing);
  });

  testWidgets('shows an empty state when no matches are scheduled', (
    tester,
  ) async {
    await tester.pumpWidget(
      _scheduleTestApp(
        initialDate: DateTime(2026, 6, 13),
        fixtures: [
          Fixture(
            id: 'm1',
            externalId: '1',
            stage: TournamentStage.group,
            roundLabel: 'Group A',
            kickoff: DateTime(2026, 6, 11, 19),
            status: FixtureStatus.scheduled,
            homeCountryId: 'mexico',
            awayCountryId: 'south_africa',
          ),
        ],
      ),
    );
    await tester.pump();

    expect(find.text('No matches on this date.'), findsOneWidget);
  });
}

Widget _scheduleTestApp({
  required DateTime initialDate,
  required List<Fixture> fixtures,
}) {
  return ProviderScope(
    overrides: [
      countriesProvider.overrideWith((ref) => Stream.value(_countries)),
      fixturesProvider.overrideWith((ref) => Stream.value(fixtures)),
    ],
    child: MaterialApp(
      home: AppLocaleScope(
        locale: const Locale('en'),
        child: Scaffold(body: ScheduleScreen(initialDate: initialDate)),
      ),
    ),
  );
}

final _countries = [
  const Country(
    id: 'mexico',
    apiFootballTeamId: 16,
    name: 'Mexico',
    abbreviation: 'MEX',
    flagUrl: '',
    fallbackAssetKey: '',
  ),
  const Country(
    id: 'south_africa',
    apiFootballTeamId: 0,
    name: 'South Africa',
    abbreviation: 'RSA',
    flagUrl: '',
    fallbackAssetKey: '',
  ),
  const Country(
    id: 'canada',
    apiFootballTeamId: 5529,
    name: 'Canada',
    abbreviation: 'CAN',
    flagUrl: '',
    fallbackAssetKey: '',
  ),
  const Country(
    id: 'usa',
    apiFootballTeamId: 2384,
    name: 'USA',
    abbreviation: 'USA',
    flagUrl: '',
    fallbackAssetKey: '',
  ),
];
