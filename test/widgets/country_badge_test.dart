import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_cup_bracket/src/domain/models.dart';
import 'package:world_cup_bracket/src/widgets/country_badge.dart';

void main() {
  testWidgets('CountryBadge can render abbreviation-only chip text', (
    tester,
  ) async {
    const country = Country(
      id: 'usa',
      apiFootballTeamId: 2384,
      name: 'USA',
      abbreviation: 'USA',
      flagUrl: '',
      fallbackAssetKey: '',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CountryBadge(
            country: country,
            compact: true,
            abbreviationOnly: true,
          ),
        ),
      ),
    );

    expect(find.text('USA'), findsOneWidget);
  });
}
