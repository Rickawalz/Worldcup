import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_cup_bracket/src/data/providers.dart';
import 'package:world_cup_bracket/src/domain/models.dart';
import 'package:world_cup_bracket/src/features/amys_calendar_screen.dart';
import 'package:world_cup_bracket/src/localization/app_strings.dart';
import 'package:world_cup_bracket/src/widgets/country_flags.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('shows month calendar and matches for the selected date', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1200, 2400);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(() => tester.view.devicePixelRatio = 1.0);

    await tester.pumpWidget(
      _calendarTestApp(
        initialDate: DateTime(2026, 6, 11),
        fixtures: _sampleFixtures,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Amy's Calendar"), findsOneWidget);
    expect(find.textContaining('Mexico'), findsWidgets);
    expect(find.textContaining('South Africa'), findsWidgets);
    expect(find.textContaining('Mexico City Stadium'), findsOneWidget);
    expect(find.textContaining('Canada'), findsNothing);
  });

  testWidgets('shows an empty state when no matches are on the selected date', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1200, 2400);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(() => tester.view.devicePixelRatio = 1.0);

    await tester.pumpWidget(
      _calendarTestApp(
        initialDate: DateTime(2026, 6, 13),
        fixtures: _sampleFixtures,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No matches on this date.'), findsOneWidget);
  });

  testWidgets('filters games by selected team', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1200, 2400);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(() => tester.view.devicePixelRatio = 1.0);

    await tester.pumpWidget(
      _calendarTestApp(
        initialDate: DateTime(2026, 6, 11),
        fixtures: _sampleFixtures,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Mexico'), findsWidgets);

    await tester.tap(find.byType(DropdownButtonFormField<String?>));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Canada').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('Mexico'), findsNothing);
    expect(find.text('No matches on this date.'), findsOneWidget);
  });

  testWidgets('shows finished scores from fixture data', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1200, 2400);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(() => tester.view.devicePixelRatio = 1.0);

    await tester.pumpWidget(
      _calendarTestApp(
        initialDate: DateTime(2026, 6, 12),
        fixtures: [
          _sampleFixtures.first,
          Fixture(
            id: 'm2',
            externalId: '2',
            stage: TournamentStage.group,
            roundLabel: 'Group B',
            kickoff: DateTime(2026, 6, 12, 19),
            status: FixtureStatus.finished,
            homeCountryId: 'canada',
            awayCountryId: 'usa',
            homeScore: 2,
            awayScore: 1,
            winnerCountryId: 'canada',
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2-1'), findsWidgets);
    expect(find.textContaining('Finished'), findsOneWidget);
  });

  testWidgets('shows event blocks in month grid and +N more overflow', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1200, 2400);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(() => tester.view.devicePixelRatio = 1.0);

    await tester.pumpWidget(
      _calendarTestApp(
        initialDate: DateTime(2026, 6, 11),
        fixtures: [
          _sampleFixtures.first,
          Fixture(
            id: 'm3',
            externalId: '3',
            stage: TournamentStage.group,
            roundLabel: 'Group C',
            kickoff: DateTime(2026, 6, 11, 16),
            status: FixtureStatus.scheduled,
            homeCountryId: 'canada',
            awayCountryId: 'usa',
          ),
          Fixture(
            id: 'm4',
            externalId: '4',
            stage: TournamentStage.group,
            roundLabel: 'Group D',
            kickoff: DateTime(2026, 6, 11, 13),
            status: FixtureStatus.scheduled,
            homeCountryId: 'usa',
            awayCountryId: 'canada',
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining(_expectedMatchupLabel('usa', 'canada')),
      findsOneWidget,
    );
    expect(
      find.textContaining(_expectedMatchupLabel('canada', 'usa')),
      findsOneWidget,
    );
    expect(
      find.textContaining(_expectedMatchupLabel('mexico', 'south_africa')),
      findsNothing,
    );
    expect(find.text('+1 more'), findsOneWidget);

    await tester.tap(find.text('+1 more'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining(_expectedMatchupLabel('mexico', 'south_africa')),
      findsNothing,
    );
    expect(find.textContaining('Mexico'), findsWidgets);
  });

  testWidgets('selects a game block and shows full match details below', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1200, 2400);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(() => tester.view.devicePixelRatio = 1.0);

    await tester.pumpWidget(
      _calendarTestApp(
        initialDate: DateTime(2026, 6, 11),
        fixtures: _sampleFixtures,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find
          .textContaining(_expectedMatchupLabel('mexico', 'south_africa'))
          .first,
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Group A'), findsWidgets);
    expect(find.textContaining('Mexico City Stadium'), findsWidgets);
  });

  testWidgets('shows readable time and flag matchup blocks on mobile', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 2400);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(() => tester.view.devicePixelRatio = 1.0);

    await tester.pumpWidget(
      _calendarTestApp(
        initialDate: DateTime(2026, 6, 11),
        fixtures: _sampleFixtures,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('7:00'), findsWidgets);
    expect(
      find.textContaining(_expectedMatchupLabel('mexico', 'south_africa')),
      findsOneWidget,
    );
  });

  testWidgets('shows two blocks and +N more on mobile overflow days', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 2400);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(() => tester.view.devicePixelRatio = 1.0);

    await tester.pumpWidget(
      _calendarTestApp(
        initialDate: DateTime(2026, 6, 11),
        fixtures: [
          _sampleFixtures.first,
          Fixture(
            id: 'm3',
            externalId: '3',
            stage: TournamentStage.group,
            roundLabel: 'Group C',
            kickoff: DateTime(2026, 6, 11, 16),
            status: FixtureStatus.scheduled,
            homeCountryId: 'canada',
            awayCountryId: 'usa',
          ),
          Fixture(
            id: 'm4',
            externalId: '4',
            stage: TournamentStage.group,
            roundLabel: 'Group D',
            kickoff: DateTime(2026, 6, 11, 13),
            status: FixtureStatus.scheduled,
            homeCountryId: 'usa',
            awayCountryId: 'canada',
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('1:00'), findsWidgets);
    expect(
      find.textContaining(_expectedMatchupLabel('usa', 'canada')),
      findsOneWidget,
    );
    expect(
      find.textContaining(_expectedMatchupLabel('canada', 'usa')),
      findsOneWidget,
    );
    expect(find.text('+1 more'), findsOneWidget);
  });

  testWidgets('uses horizontal scroll with fixed-width columns on mobile', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 2400);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(() => tester.view.devicePixelRatio = 1.0);

    await tester.pumpWidget(
      _calendarTestApp(
        initialDate: DateTime(2026, 6, 11),
        fixtures: _sampleFixtures,
      ),
    );
    await tester.pumpAndSettle();

    final horizontalScroll = tester.widget<SingleChildScrollView>(
      find.descendant(
        of: find.byType(Card),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is SingleChildScrollView &&
              widget.scrollDirection == Axis.horizontal,
        ),
      ),
    );
    expect(horizontalScroll.scrollDirection, Axis.horizontal);
    expect(
      find.textContaining(_expectedMatchupLabel('mexico', 'south_africa')),
      findsOneWidget,
    );
  });
}

String _expectedMatchupLabel(String homeId, String awayId) {
  final home = _countries.firstWhere((country) => country.id == homeId);
  final away = _countries.firstWhere((country) => country.id == awayId);
  return '${flagEmoji(home)} ${home.abbreviation} · ${flagEmoji(away)} ${away.abbreviation}';
}

Widget _calendarTestApp({
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
        child: Scaffold(body: AmysCalendarScreen(initialDate: initialDate)),
      ),
    ),
  );
}

final _sampleFixtures = [
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
];

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
