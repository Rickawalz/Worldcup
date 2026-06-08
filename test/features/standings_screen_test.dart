import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_cup_bracket/src/data/providers.dart';
import 'package:world_cup_bracket/src/domain/models.dart';
import 'package:world_cup_bracket/src/features/standings_screen.dart';
import 'package:world_cup_bracket/src/localization/app_strings.dart';
import 'package:world_cup_bracket/src/widgets/dashboard.dart';

void main() {
  testWidgets('renders standings match cards with flags scores and venue', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_standingsTestApp());
    await tester.pump();

    expect(find.text('Standings'), findsOneWidget);
    expect(find.text('Group A'), findsWidgets);
    expect(find.text('Mexico'), findsWidgets);
    expect(find.text('South Africa'), findsWidgets);
    expect(find.text('2 - 1'), findsOneWidget);
    expect(find.text('Final'), findsWidgets);
    expect(find.textContaining('Winner: Mexico'), findsOneWidget);
    expect(find.textContaining('Mexico City Stadium'), findsOneWidget);
    expect(find.text('Official Knockout Bracket'), findsOneWidget);
    expect(
      find.text('Filled from admin-entered scores and winners.'),
      findsOneWidget,
    );
    expect(find.text('3 - 2'), findsWidgets);
    expect(find.text('Knockout games'), findsOneWidget);

    expect(find.text('vs'), findsWidgets);
  });
}

Widget _standingsTestApp() {
  return ProviderScope(
    overrides: [
      countriesProvider.overrideWith((ref) => Stream.value(_countries)),
      fixturesProvider.overrideWith((ref) => Stream.value(_fixtures)),
      standingsProvider.overrideWith((ref) => Stream.value(_standings)),
    ],
    child: MaterialApp(
      theme: buildDashboardTheme(),
      home: const AppLocaleScope(
        locale: Locale('en'),
        child: Scaffold(body: StandingsScreen()),
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

final _fixtures = [
  Fixture(
    id: 'm1',
    externalId: '1',
    stage: TournamentStage.group,
    roundLabel: 'Group A',
    kickoff: DateTime(2026, 6, 11, 19),
    status: FixtureStatus.finished,
    homeCountryId: 'mexico',
    awayCountryId: 'south_africa',
    homeScore: 2,
    awayScore: 1,
    winnerCountryId: 'mexico',
    venueName: 'Mexico City Stadium',
    venueCity: 'Mexico City',
  ),
  Fixture(
    id: 'm73',
    externalId: '73',
    stage: TournamentStage.roundOf32,
    roundLabel: 'Match 73',
    kickoff: DateTime(2026, 6, 28, 19),
    status: FixtureStatus.finished,
    homeCountryId: 'canada',
    awayCountryId: 'usa',
    homeScore: 3,
    awayScore: 2,
    winnerCountryId: 'canada',
    venueName: 'Los Angeles Stadium',
    venueCity: 'Los Angeles',
  ),
];

final _standings = [
  GroupStanding(
    groupId: 'A',
    updatedAt: DateTime(2026, 6, 11),
    rows: const [
      StandingRow(
        countryId: 'mexico',
        rank: 1,
        played: 1,
        won: 1,
        drawn: 0,
        lost: 0,
        goalsFor: 2,
        goalsAgainst: 1,
        goalDifference: 1,
        points: 3,
      ),
      StandingRow(
        countryId: 'south_africa',
        rank: 2,
        played: 1,
        won: 0,
        drawn: 0,
        lost: 1,
        goalsFor: 1,
        goalsAgainst: 2,
        goalDifference: -1,
        points: 0,
      ),
    ],
  ),
];
