import 'package:flutter_test/flutter_test.dart';
import 'package:world_cup_bracket/src/domain/models.dart';
import 'package:world_cup_bracket/src/widgets/country_flags.dart';

void main() {
  test('returns emoji flag for known country', () {
    const country = Country(
      id: 'south_africa',
      apiFootballTeamId: 0,
      name: 'South Africa',
      abbreviation: 'RSA',
      flagUrl: '',
      fallbackAssetKey: '',
    );

    expect(flagEmoji(country), '🇿🇦');
  });

  test('returns null when no emoji fallback is known', () {
    const country = Country(
      id: 'unknown_team',
      apiFootballTeamId: 0,
      name: 'Unknown Team',
      abbreviation: 'UNK',
      flagUrl: '',
      fallbackAssetKey: '',
    );

    expect(flagEmoji(country), isNull);
  });
}
