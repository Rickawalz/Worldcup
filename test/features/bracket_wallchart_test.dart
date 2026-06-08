import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_cup_bracket/src/data/providers.dart';
import 'package:world_cup_bracket/src/domain/bracket_rules.dart';
import 'package:world_cup_bracket/src/domain/models.dart';
import 'package:world_cup_bracket/src/features/bracket_screen.dart';
import 'package:world_cup_bracket/src/localization/app_strings.dart';
import 'package:world_cup_bracket/src/widgets/dashboard.dart';

void main() {
  testWidgets('renders knockout wallchart and fallback editor', (tester) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_bracketWallchartTestApp());
    await tester.pump();

    expect(find.text('World Cup Wallchart 2026'), findsOneWidget);
    expect(find.text('FINAL'), findsOneWidget);
    expect(find.text('WINNER'), findsOneWidget);
    expect(
      find.text('Tap any match box to pick or change the winner.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('The detailed editor below remains available'),
      findsOneWidget,
    );
    expect(find.text('Match 73'), findsWidgets);
  });
}

Widget _bracketWallchartTestApp() {
  return ProviderScope(
    overrides: [
      countriesProvider.overrideWith((ref) => Stream.value(_countries)),
      myBracketProvider.overrideWith((ref) => Stream.value(_bracket)),
      contestConfigProvider.overrideWith(
        (ref) => Stream.value(
          GlobalContestConfig(lockAt: DateTime(2026, 6, 11, 19)),
        ),
      ),
      currentUserProvider.overrideWith(
        (ref) => Stream.value(
          AppUser(
            id: 'user',
            username: 'Tester',
            createdAt: DateTime(2026, 1, 1),
          ),
        ),
      ),
      fixturesProvider.overrideWith((ref) => Stream.value(_fixtures)),
    ],
    child: MaterialApp(
      theme: buildDashboardTheme(),
      home: const AppLocaleScope(
        locale: Locale('en'),
        child: Scaffold(body: BracketScreen()),
      ),
    ),
  );
}

final _countries = [
  for (final id in BracketRules.officialCountryIds)
    Country(
      id: id,
      apiFootballTeamId: 0,
      name: _titleCase(id),
      abbreviation: id.substring(0, 3).toUpperCase(),
      flagUrl: '',
      fallbackAssetKey: '',
    ),
];

final _bracket = Bracket.empty('user').copyWith(
  groupPicks: [
    for (final entry in BracketRules.groupCountryIds.entries)
      GroupPick(
        groupId: entry.key,
        firstCountryId: entry.value[0],
        secondCountryId: entry.value[1],
        thirdCountryId: entry.value[2],
      ),
  ],
  bestThirdGroupIds: BracketRules.groupIds.take(8).toList(),
  knockoutPicks: [
    for (final slot in BracketRules.knockoutSlots())
      KnockoutPick(
        slotId: slot.id,
        stage: slot.stage,
        winnerCountryId: BracketRules.officialCountryIds.first,
      ),
  ],
);

final _fixtures = [
  for (final slot in BracketRules.knockoutSlots())
    Fixture(
      id: slot.id,
      externalId: slot.id,
      stage: slot.stage,
      roundLabel: slot.label,
      kickoff: DateTime(2026, 6, 28, 19),
      status: FixtureStatus.scheduled,
      venueName: 'Test Stadium',
      venueCity: 'Test City',
    ),
];

String _titleCase(String value) {
  return value
      .split('_')
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
