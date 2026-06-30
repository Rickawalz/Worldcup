import 'package:flutter_test/flutter_test.dart';
import 'package:world_cup_bracket/src/domain/models.dart';
import 'package:world_cup_bracket/src/domain/players_ranking.dart';

void main() {
  test('orders players by leaderboard rank', () {
    final profiles = [
      _profile(userId: 'b', username: 'Bravo', totalScore: 10),
      _profile(userId: 'a', username: 'Alpha', totalScore: 20),
    ];
    final leaderboard = [
      _entry(userId: 'a', rank: 1, score: 20),
      _entry(userId: 'b', rank: 2, score: 10),
    ];

    final ranked = rankPublicBracketProfiles(
      profiles: profiles,
      leaderboard: leaderboard,
    );

    expect(ranked, hasLength(2));
    expect(ranked[0].rank, 1);
    expect(ranked[0].profile.user.username, 'Alpha');
    expect(ranked[0].totalScore, 20);
    expect(ranked[1].rank, 2);
    expect(ranked[1].profile.user.username, 'Bravo');
    expect(ranked[1].totalScore, 10);
  });

  test('falls back to score order when leaderboard ranks are missing', () {
    final profiles = [
      _profile(userId: 'b', username: 'Bravo', totalScore: 5),
      _profile(userId: 'a', username: 'Alpha', totalScore: 12),
    ];

    final ranked = rankPublicBracketProfiles(profiles: profiles, leaderboard: const []);

    expect(ranked[0].profile.user.username, 'Alpha');
    expect(ranked[0].rank, 1);
    expect(ranked[1].profile.user.username, 'Bravo');
    expect(ranked[1].rank, 2);
  });
}

PublicBracketProfile _profile({
  required String userId,
  required String username,
  required int totalScore,
}) {
  return PublicBracketProfile(
    user: AppUser(
      id: userId,
      username: username,
      createdAt: DateTime.utc(2026, 1, 1),
    ),
    bracket: Bracket.empty(userId).copyWith(
      status: BracketStatus.submitted,
      totalScore: totalScore,
    ),
  );
}

LeaderboardEntry _entry({
  required String userId,
  required int rank,
  required int score,
}) {
  return LeaderboardEntry(
    userId: userId,
    username: userId,
    score: score,
    tiebreakerDistance: 0,
    rank: rank,
    groupScore: score ~/ 2,
    knockoutScore: score - (score ~/ 2),
  );
}
