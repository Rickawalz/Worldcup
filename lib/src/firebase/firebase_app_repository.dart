import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_messaging/firebase_messaging.dart';

import '../data/app_repository.dart';
import '../data/username_validator.dart';
import '../domain/bracket_rules.dart';
import '../domain/models.dart';

class FirebaseAppRepository implements AppRepository {
  FirebaseAppRepository({
    required auth.FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
    required FirebaseMessaging messaging,
  }) : _auth = firebaseAuth,
       _firestore = firestore,
       _messaging = messaging;

  final auth.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseMessaging _messaging;

  String get _userId {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('User must be signed in.');
    }
    return user.uid;
  }

  @override
  Stream<AppUser?> watchCurrentUser() {
    return _auth.authStateChanges().asyncExpand((firebaseUser) {
      if (firebaseUser == null) {
        return Stream.value(null);
      }
      return _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .snapshots()
          .map((snapshot) {
            final data = snapshot.data();
            if (data == null) {
              return null;
            }
            return AppUser.fromMap(snapshot.id, {
              ...data,
              'email': firebaseUser.email,
            });
          });
    });
  }

  @override
  Stream<GlobalContestConfig> watchGlobalContestConfig() {
    return _firestore.doc('globalContest/config/current').snapshots().map((
      snapshot,
    ) {
      return GlobalContestConfig.fromMap(snapshot.data() ?? const {});
    });
  }

  @override
  Stream<List<Country>> watchCountries() {
    return _firestore
        .collection('countries')
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Country.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  @override
  Stream<Bracket> watchMyBracket() {
    return _firestore.doc('globalContest/brackets/$_userId').snapshots().map((
      snapshot,
    ) {
      final data = snapshot.data();
      if (data == null) {
        return Bracket.empty(_userId);
      }
      return Bracket.fromMap(snapshot.id, data);
    });
  }

  @override
  Stream<List<LeaderboardEntry>> watchLeaderboard() {
    return _firestore
        .collection('leaderboards/global/entries')
        .orderBy('score', descending: true)
        .orderBy('tiebreakerDistance')
        .limit(100)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => LeaderboardEntry.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  @override
  Stream<List<Fixture>> watchFixtures() {
    return _firestore.collection('fixtures').orderBy('kickoff').snapshots().map(
      (snapshot) {
        return snapshot.docs
            .map((doc) => Fixture.fromMap(doc.id, doc.data()))
            .toList();
      },
    );
  }

  @override
  Stream<List<ChatMessage>> watchGlobalChatMessages() {
    return _firestore
        .collection('globalChat')
        .orderBy('createdAt', descending: true)
        .limit(500)
        .snapshots()
        .map((snapshot) {
          final cutoff = DateTime.now().subtract(const Duration(days: 30));
          return snapshot.docs
              .map((doc) => ChatMessage.fromMap(doc.id, doc.data()))
              .where((message) => message.createdAt.isAfter(cutoff))
              .toList();
        });
  }

  @override
  Future<AppUser> createUsernameProfile(String username) async {
    final validationError = UsernameValidator.validate(username);
    if (validationError != null) {
      throw ArgumentError(validationError);
    }
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
    final userId = _userId;
    final normalized = UsernameValidator.normalize(username);
    final now = DateTime.now();
    final profile = AppUser(
      id: userId,
      username: username.trim(),
      email: _auth.currentUser?.email,
      createdAt: now,
    );

    await _firestore.runTransaction((transaction) async {
      final usernameRef = _firestore.doc('usernames/$normalized');
      final usernameDoc = await transaction.get(usernameRef);
      if (usernameDoc.exists) {
        throw StateError('That username is already taken.');
      }
      transaction.set(usernameRef, {
        'userId': userId,
        'createdAt': now.toIso8601String(),
      });
      transaction.set(_firestore.doc('users/$userId'), profile.toMap());
      transaction.set(
        _firestore.doc('globalContest/brackets/$userId'),
        Bracket.empty(userId).toMap(),
      );
    });

    return profile;
  }

  @override
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> linkAccount(AuthProviderLink provider) async {
    // The platform-specific OAuth credential flow belongs in the UI layer.
    // This placeholder keeps the repository contract explicit for Firebase.
    await _firestore.doc('users/$_userId').update({
      'linkedProviders': FieldValue.arrayUnion([provider.name]),
    });
  }

  @override
  Future<void> saveBracket(Bracket bracket) async {
    final config = await _currentConfig();
    if (!config.isAcceptingSubmissions || config.isLocked) {
      throw StateError('This bracket is locked.');
    }
    await _firestore
        .doc('globalContest/brackets/${bracket.userId}')
        .set(
          bracket.copyWith(updatedAt: DateTime.now()).toMap(),
          SetOptions(merge: true),
        );
  }

  @override
  Future<void> submitBracket(Bracket bracket) async {
    final config = await _currentConfig();
    if (!BracketRules.canSubmit(bracket, config)) {
      throw StateError('Complete every group and knockout pick before submit.');
    }
    await _firestore
        .doc('globalContest/brackets/${bracket.userId}')
        .set(
          bracket
              .copyWith(
                status: BracketStatus.submitted,
                submittedAt: DateTime.now(),
                updatedAt: DateTime.now(),
              )
              .toMap(),
          SetOptions(merge: true),
        );
  }

  @override
  Future<void> sendChatMessage(String text) async {
    final profile = await _requireProfile();
    final normalized = _normalizeMessageText(text);
    final now = DateTime.now();
    await _firestore
        .collection('globalChat')
        .add(
          ChatMessage(
            id: '',
            userId: profile.id,
            username: profile.username,
            text: normalized,
            createdAt: now,
            updatedAt: now,
          ).toMap(),
        );
  }

  @override
  Future<void> editChatMessage({
    required String messageId,
    required String text,
  }) async {
    final profile = await _requireProfile();
    final ref = _firestore.collection('globalChat').doc(messageId);
    final snapshot = await ref.get();
    final message = ChatMessage.fromMap(
      snapshot.id,
      snapshot.data() ?? const {},
    );
    if (!message.canBeChangedBy(profile.id)) {
      throw StateError('You can only edit your own messages.');
    }
    await ref.update({
      'text': _normalizeMessageText(text),
      'updatedAt': DateTime.now().toIso8601String(),
      'isEdited': true,
    });
  }

  @override
  Future<void> deleteChatMessage(String messageId) async {
    final profile = await _requireProfile();
    final ref = _firestore.collection('globalChat').doc(messageId);
    final snapshot = await ref.get();
    final message = ChatMessage.fromMap(
      snapshot.id,
      snapshot.data() ?? const {},
    );
    if (!message.canBeChangedBy(profile.id)) {
      throw StateError('You can only delete your own messages.');
    }
    await ref.update({
      'text': '',
      'updatedAt': DateTime.now().toIso8601String(),
      'isDeleted': true,
    });
  }

  @override
  Future<void> reactToChatMessage({
    required String messageId,
    required String emoji,
  }) async {
    await _requireProfile();
    final trimmedEmoji = emoji.trim();
    if (trimmedEmoji.isEmpty) return;
    await _firestore.collection('globalChat').doc(messageId).update({
      'reactions.$trimmedEmoji': FieldValue.increment(1),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> report({
    required ReportTargetType targetType,
    required String targetId,
    required String reason,
  }) async {
    await _firestore
        .collection('reports')
        .add(
          ModerationReport(
            id: '',
            reporterId: _userId,
            targetType: targetType,
            targetId: targetId,
            reason: reason,
            status: ReportStatus.open,
            createdAt: DateTime.now(),
          ).toMap(),
        );
  }

  @override
  Future<void> setNotificationsEnabled(bool enabled) async {
    if (enabled) {
      await _messaging.requestPermission();
      final token = await _messaging.getToken();
      if (token != null) {
        await _firestore.doc('users/$_userId').set({
          'messagingTokens': FieldValue.arrayUnion([token]),
          'notificationsEnabled': true,
        }, SetOptions(merge: true));
      }
    } else {
      await _firestore.doc('users/$_userId').set({
        'notificationsEnabled': false,
      }, SetOptions(merge: true));
    }
  }

  Future<GlobalContestConfig> _currentConfig() async {
    final snapshot = await _firestore.doc('globalContest/config/current').get();
    return GlobalContestConfig.fromMap(snapshot.data() ?? const {});
  }

  Future<AppUser> _requireProfile() async {
    final snapshot = await _firestore.doc('users/$_userId').get();
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Create a username profile before posting in chat.');
    }
    return AppUser.fromMap(snapshot.id, data);
  }

  String _normalizeMessageText(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Message cannot be empty.');
    }
    if (trimmed.length > ChatMessage.maxTextLength) {
      throw ArgumentError(
        'Message must be ${ChatMessage.maxTextLength} characters or fewer.',
      );
    }
    return trimmed;
  }
}
