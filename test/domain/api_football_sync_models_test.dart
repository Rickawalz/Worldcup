import 'package:flutter_test/flutter_test.dart';
import 'package:world_cup_bracket/src/domain/models.dart';

void main() {
  test('ApiFootballSyncSummary parses callable response', () {
    final summary = ApiFootballSyncSummary.fromMap({
      'fixturesUpdated': 4,
      'skippedAdmin': 1,
      'skippedUnmatched': 2,
      'skippedUnchanged': 10,
      'knockoutResultsUpdated': 1,
      'apiFixturesReceived': 104,
      'localFixturesLoaded': 104,
      'countriesWithApiId': 48,
      'countriesEnrichedFromApi': 12,
      'source': 'manual',
    });

    expect(summary.fixturesUpdated, 4);
    expect(summary.apiFixturesReceived, 104);
    expect(summary.countriesEnrichedFromApi, 12);
  });

  test('ApiFootballSyncState parses syncState document', () {
    final state = ApiFootballSyncState.fromMap({
      'lastSyncAt': '2026-06-15T18:30:00.000Z',
      'lastError': null,
      'fixturesUpdated': 3,
      'skippedAdmin': 0,
      'skippedUnmatched': 1,
      'skippedUnchanged': 5,
      'knockoutResultsUpdated': 0,
      'source': 'scheduled',
    });

    expect(state.lastSyncAt, DateTime.parse('2026-06-15T18:30:00.000Z'));
    expect(state.fixturesUpdated, 3);
    expect(state.source, 'scheduled');
  });
}
