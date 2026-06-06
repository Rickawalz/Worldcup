import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models.dart';
import 'app_repository.dart';
import 'in_memory_app_repository.dart';

final appRepositoryProvider = Provider<AppRepository>((ref) {
  final repository = InMemoryAppRepository();
  ref.onDispose(repository.dispose);
  return repository;
});

final currentUserProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(appRepositoryProvider).watchCurrentUser();
});

final contestConfigProvider = StreamProvider<GlobalContestConfig>((ref) {
  return ref.watch(appRepositoryProvider).watchGlobalContestConfig();
});

final countriesProvider = StreamProvider<List<Country>>((ref) {
  return ref.watch(appRepositoryProvider).watchCountries();
});

final myBracketProvider = StreamProvider<Bracket>((ref) {
  return ref.watch(appRepositoryProvider).watchMyBracket();
});

final leaderboardProvider = StreamProvider<List<LeaderboardEntry>>((ref) {
  return ref.watch(appRepositoryProvider).watchLeaderboard();
});

final fixturesProvider = StreamProvider<List<Fixture>>((ref) {
  return ref.watch(appRepositoryProvider).watchFixtures();
});

final globalChatMessagesProvider = StreamProvider<List<ChatMessage>>((ref) {
  return ref.watch(appRepositoryProvider).watchGlobalChatMessages();
});
