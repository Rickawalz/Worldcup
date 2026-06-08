import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_cup_bracket/src/domain/models.dart';
import 'package:world_cup_bracket/src/localization/country_names.dart';

void main() {
  test('uses English country name outside Spanish locale', () {
    const country = Country(
      id: 'usa',
      apiFootballTeamId: 2384,
      name: 'United States',
      abbreviation: 'USA',
      flagUrl: '',
      fallbackAssetKey: '',
    );

    expect(
      countryDisplayNameForLocale(const Locale('en'), country),
      'United States',
    );
  });

  test('uses common Spanish country name in Spanish locale', () {
    const country = Country(
      id: 'usa',
      apiFootballTeamId: 2384,
      name: 'United States',
      abbreviation: 'USA',
      flagUrl: '',
      fallbackAssetKey: '',
    );

    expect(
      countryDisplayNameForLocale(const Locale('es'), country),
      'Estados Unidos',
    );
  });

  test('falls back to source name when Spanish translation is missing', () {
    const country = Country(
      id: 'unknown_team',
      apiFootballTeamId: 0,
      name: 'Unknown Team',
      abbreviation: 'UNK',
      flagUrl: '',
      fallbackAssetKey: '',
    );

    expect(
      countryDisplayNameForLocale(const Locale('es'), country),
      'Unknown Team',
    );
  });
}
