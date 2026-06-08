import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models.dart';
import 'app_repository.dart';
import '../firebase/firebase_app_repository.dart';
import 'in_memory_app_repository.dart';

final appRepositoryProvider = Provider<AppRepository>((ref) {
  if (Firebase.apps.isNotEmpty) {
    return FirebaseAppRepository(
      firebaseAuth: auth.FirebaseAuth.instance,
      firestore: FirebaseFirestore.instance,
      messaging: FirebaseMessaging.instance,
    );
  }

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

final publicBracketProfilesProvider =
    StreamProvider<List<PublicBracketProfile>>((ref) {
      return ref.watch(appRepositoryProvider).watchPublicBracketProfiles();
    });

final publicBracketProfileProvider =
    StreamProvider.family<PublicBracketProfile?, String>((ref, userId) {
      return ref.watch(appRepositoryProvider).watchPublicBracketProfile(userId);
    });

final fixturesProvider = StreamProvider<List<Fixture>>((ref) {
  return ref.watch(appRepositoryProvider).watchFixtures();
});

final standingsProvider = StreamProvider<List<GroupStanding>>((ref) {
  return ref.watch(appRepositoryProvider).watchStandings();
});

final officialResultsProvider = StreamProvider<OfficialResults>((ref) {
  return ref.watch(appRepositoryProvider).watchOfficialResults();
});

final adminAuditLogsProvider = StreamProvider<List<AdminAuditLog>>((ref) {
  return ref.watch(appRepositoryProvider).watchAdminAuditLogs();
});

final globalChatMessagesProvider = StreamProvider<List<ChatMessage>>((ref) {
  return ref.watch(appRepositoryProvider).watchGlobalChatMessages();
});
