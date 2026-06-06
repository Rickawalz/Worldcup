import '../domain/models.dart';

abstract class AppRepository {
  Stream<AppUser?> watchCurrentUser();

  Stream<GlobalContestConfig> watchGlobalContestConfig();

  Stream<List<Country>> watchCountries();

  Stream<Bracket> watchMyBracket();

  Stream<List<LeaderboardEntry>> watchLeaderboard();

  Stream<List<Fixture>> watchFixtures();

  Stream<List<ChatMessage>> watchGlobalChatMessages();

  Future<AppUser> createUsernameProfile(String username);

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<void> linkAccount(AuthProviderLink provider);

  Future<void> saveBracket(Bracket bracket);

  Future<void> submitBracket(Bracket bracket);

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
