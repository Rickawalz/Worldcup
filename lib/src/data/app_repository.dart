import '../domain/models.dart';

abstract class AppRepository {
  Stream<AppUser?> watchCurrentUser();

  Stream<GlobalContestConfig> watchGlobalContestConfig();

  Stream<List<Country>> watchCountries();

  Stream<Bracket> watchMyBracket();

  Stream<List<LeaderboardEntry>> watchLeaderboard();

  Stream<List<PublicBracketProfile>> watchPublicBracketProfiles();

  Stream<PublicBracketProfile?> watchPublicBracketProfile(String userId);

  Stream<List<Fixture>> watchFixtures();

  Stream<List<GroupStanding>> watchStandings();

  Stream<OfficialResults> watchOfficialResults();

  Stream<List<AdminAuditLog>> watchAdminAuditLogs();

  Stream<List<ChatMessage>> watchGlobalChatMessages();

  Future<AppUser> createAccount({
    required String username,
    required String password,
    String? email,
    String? phone,
  });

  Future<void> signInWithIdentifierAndPassword({
    required String identifier,
    required String password,
  });

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<void> sendPasswordReset(String identifier);

  Future<void> signOut();

  Future<void> linkAccount(AuthProviderLink provider);

  Future<void> saveBracket(Bracket bracket);

  Future<void> submitBracket(Bracket bracket);

  Future<void> saveFixtureResult(Fixture fixture, {String? note});

  Future<StandingsRecalculationSummary> recalculateStandings({String? note});

  Future<void> saveStandingOverrideOrder({
    required String groupId,
    required List<String> countryIds,
    String? note,
  });

  Future<void> saveGroupAdvancers(
    OfficialGroupPlacements placements, {
    String? note,
  });

  Future<LeaderboardRecalculationSummary> recalculateLeaderboard({
    String? note,
  });

  Future<void> updateContestConfig(
    GlobalContestConfig config, {
    String? note,
    bool recalculateAfterSave = false,
  });

  Future<void> sendChatMessage(String text);

  Future<void> editChatMessage({
    required String messageId,
    required String text,
  });

  Future<void> deleteChatMessage(String messageId);

  Future<void> reactToChatMessage({
    required String messageId,
    required String emoji,
  });

  Future<void> report({
    required ReportTargetType targetType,
    required String targetId,
    required String reason,
  });

  Future<void> setNotificationsEnabled(bool enabled);
}
