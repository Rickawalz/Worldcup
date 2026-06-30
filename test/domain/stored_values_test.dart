import 'package:flutter_test/flutter_test.dart';
import 'package:world_cup_bracket/src/domain/models.dart';
import 'package:world_cup_bracket/src/domain/stored_values.dart';

void main() {
  test('parses ISO string timestamps for leaderboard entries', () {
    final entry = LeaderboardEntry.fromMap('user-1', {
      'username': 'Ricky',
      'score': 12,
      'rank': 1,
      'updatedAt': '2026-06-30T15:49:19.000Z',
    });

    expect(entry.username, 'Ricky');
    expect(entry.updatedAt, DateTime.utc(2026, 6, 30, 15, 49, 19));
  });

  test('parses Firestore-style timestamp objects for leaderboard entries', () {
    final entry = LeaderboardEntry.fromMap('user-1', {
      'username': 'Ricky',
      'score': 12,
      'rank': 1,
      'updatedAt': _FakeTimestamp(DateTime.utc(2026, 6, 30, 15, 49, 19)),
    });

    expect(entry.updatedAt, DateTime.utc(2026, 6, 30, 15, 49, 19));
  });
}

class _FakeTimestamp {
  _FakeTimestamp(this.dateTime);

  final DateTime dateTime;

  int get seconds => dateTime.millisecondsSinceEpoch ~/ 1000;

  int get nanoseconds => (dateTime.millisecond % 1000) * 1000000;
}
