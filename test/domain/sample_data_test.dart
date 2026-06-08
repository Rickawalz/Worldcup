import 'package:flutter_test/flutter_test.dart';
import 'package:world_cup_bracket/src/data/fixture_seed_data.dart';
import 'package:world_cup_bracket/src/data/sample_data.dart';
import 'package:world_cup_bracket/src/domain/bracket_rules.dart';
import 'package:world_cup_bracket/src/domain/models.dart';

void main() {
  test('sample countries include every official grouped team in order', () {
    expect(sampleCountries.map((country) => country.id), [
      for (final groupId in BracketRules.groupIds)
        ...BracketRules.groupCountryIds[groupId]!,
    ]);
  });

  test('fixture seed covers every published match slot', () {
    expect(official2026FixtureSeed, hasLength(104));
    expect(official2026FixtureSeed.map((fixture) => fixture.id), [
      for (var matchNumber = 1; matchNumber <= 104; matchNumber++)
        'm$matchNumber',
    ]);
    expect(sampleFixtures, same(official2026FixtureSeed));
  });

  test('fixture seed has group teams, venues, and bracket fixtures', () {
    final officialCountryIds = BracketRules.officialCountryIds.toSet();
    final fixtureById = {
      for (final fixture in official2026FixtureSeed) fixture.id: fixture,
    };

    for (final fixture in official2026FixtureSeed) {
      expect(fixture.venueLabel, isNotNull, reason: fixture.id);
      expect(fixture.status, FixtureStatus.scheduled, reason: fixture.id);
      expect(fixture.kickoff.isUtc, isTrue, reason: fixture.id);
      if (fixture.stage == TournamentStage.group) {
        expect(
          officialCountryIds,
          contains(fixture.homeCountryId),
          reason: fixture.id,
        );
        expect(
          officialCountryIds,
          contains(fixture.awayCountryId),
          reason: fixture.id,
        );
      }
    }

    for (final slot in BracketRules.knockoutSlots()) {
      expect(fixtureById[slot.id], isNotNull, reason: slot.id);
    }
    expect(fixtureById['m103']?.stage, TournamentStage.thirdPlace);
  });
}
