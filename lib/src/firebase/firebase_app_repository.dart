import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_messaging/firebase_messaging.dart';

import '../admin/admin_access.dart';
import '../data/app_repository.dart';
import '../data/sample_data.dart';
import '../data/username_validator.dart';
import '../domain/admin_validators.dart';
import '../domain/bracket_rules.dart';
import '../domain/leaderboard_recalculator.dart';
import '../domain/models.dart';
import '../domain/standings_calculator.dart';

class FirebaseAppRepository implements AppRepository {
  FirebaseAppRepository({
    required auth.FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
    required FirebaseMessaging messaging,
    FirebaseFunctions? functions,
  }) : _auth = firebaseAuth,
       _firestore = firestore,
       _messaging = messaging,
       _functions =
           functions ??
           FirebaseFunctions.instanceFor(region: 'us-central1');

  final auth.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseMessaging _messaging;
  final FirebaseFunctions _functions;

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
              'email': _publicEmailFor(firebaseUser.email),
            });
          });
    });
  }

  @override
  Stream<GlobalContestConfig> watchGlobalContestConfig() {
    return _firestore
        .doc('globalContest/current/config/current')
        .snapshots()
        .map((snapshot) {
          return GlobalContestConfig.fromMap(snapshot.data() ?? const {});
        });
  }

  @override
  Stream<List<Country>> watchCountries() {
    return _firestore.collection('countries').orderBy('name').snapshots().map((
      snapshot,
    ) {
      final countries =
          snapshot.docs
              .map((doc) => Country.fromMap(doc.id, doc.data()))
              .where((country) => country.isActive)
              .toList();
      return _officialCountries(countries);
    });
  }

  @override
  Stream<Bracket> watchMyBracket() {
    return _auth.authStateChanges().asyncExpand((firebaseUser) {
      if (firebaseUser == null) {
        return Stream.error(StateError('Sign in before opening your bracket.'));
      }
      final userId = firebaseUser.uid;
      return _firestore
          .doc('globalContest/current/brackets/$userId')
          .snapshots()
          .map((snapshot) {
            final data = snapshot.data();
            if (data == null) {
              return Bracket.empty(userId);
            }
            return Bracket.fromMap(snapshot.id, data);
          });
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
  Stream<List<PublicBracketProfile>> watchPublicBracketProfiles() {
    return _firestore
        .collection('globalContest/current/brackets')
        .where('status', isEqualTo: BracketStatus.submitted.name)
        .snapshots()
        .asyncMap((snapshot) async {
          final profiles = <PublicBracketProfile>[];
          for (final doc in snapshot.docs) {
            final bracket = Bracket.fromMap(doc.id, doc.data());
            final user = await _userForBracket(bracket.userId);
            if (user != null && !user.isHidden) {
              profiles.add(PublicBracketProfile(user: user, bracket: bracket));
            }
          }
          profiles.sort(
            (a, b) => a.user.username.toLowerCase().compareTo(
              b.user.username.toLowerCase(),
            ),
          );
          return profiles;
        });
  }

  @override
  Stream<PublicBracketProfile?> watchPublicBracketProfile(String userId) {
    return _firestore
        .doc('globalContest/current/brackets/$userId')
        .snapshots()
        .asyncMap((snapshot) async {
          final data = snapshot.data();
          if (data == null) {
            return null;
          }
          final bracket = Bracket.fromMap(snapshot.id, data);
          if (bracket.status != BracketStatus.submitted) {
            return null;
          }
          final user = await _userForBracket(bracket.userId);
          if (user == null || user.isHidden) {
            return null;
          }
          return PublicBracketProfile(user: user, bracket: bracket);
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
  Stream<List<GroupStanding>> watchStandings() {
    return _firestore.collection('standings').snapshots().map((snapshot) {
      final byGroupId = {
        for (final doc in snapshot.docs)
          doc.id: GroupStanding.fromMap(doc.id, doc.data()),
      };
      return [
        for (final groupId in BracketRules.groupIds)
          byGroupId[groupId] ??
              GroupStanding(
                groupId: groupId,
                rows: [
                  for (
                    var index = 0;
                    index <
                        (BracketRules.groupCountryIds[groupId] ?? const [])
                            .length;
                    index++
                  )
                    StandingRow.empty(
                      BracketRules.groupCountryIds[groupId]![index],
                      index + 1,
                    ),
                ],
              ),
      ];
    });
  }

  @override
  Stream<OfficialResults> watchOfficialResults() {
    return _firestore
        .doc('globalContest/current/officialResults/current')
        .snapshots()
        .map((snapshot) {
          return OfficialResults.fromMap(snapshot.data() ?? const {});
        });
  }

  @override
  Stream<List<AdminAuditLog>> watchAdminAuditLogs() {
    return _firestore
        .collection('adminAuditLogs')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => AdminAuditLog.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  @override
  Stream<ApiFootballSyncState> watchApiFootballSyncState() {
    return _firestore.doc('syncState/current').snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) {
        return const ApiFootballSyncState();
      }
      final normalized = Map<String, Object?>.from(data);
      final lastSyncAt = normalized['lastSyncAt'];
      if (lastSyncAt is Timestamp) {
        normalized['lastSyncAt'] = lastSyncAt.toDate().toIso8601String();
      }
      return ApiFootballSyncState.fromMap(normalized);
    });
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
  Future<AppUser> createAccount({
    required String username,
    required String password,
    String? email,
    String? phone,
  }) async {
    final validationError = UsernameValidator.validate(username);
    if (validationError != null) {
      throw ArgumentError(validationError);
    }
    final normalizedEmail = _normalizeOptionalEmail(email);
    final normalizedPhone = _normalizeOptionalPhone(phone);
    if (password.length < 6) {
      throw ArgumentError('Password must be at least 6 characters.');
    }
    if (normalizedEmail == null && normalizedPhone == null) {
      throw ArgumentError('Enter an email or phone number.');
    }
    final normalized = UsernameValidator.normalize(username);
    final usernameRef = _firestore.doc('usernames/$normalized');
    final existingUsername = await usernameRef.get();
    if (await _activeUsernameReservationExists(existingUsername)) {
      throw StateError('That username is already taken.');
    }

    final authEmail = normalizedEmail ?? _syntheticAuthEmail(normalized);
    final credential = await _auth.createUserWithEmailAndPassword(
      email: authEmail,
      password: password,
    );
    final userId = credential.user?.uid ?? _userId;
    final now = DateTime.now();
    final profile = AppUser(
      id: userId,
      username: username.trim(),
      email: normalizedEmail,
      createdAt: now,
    );

    var usernameExists = false;
    try {
      await _firestore.runTransaction((transaction) async {
        final usernameDoc = await transaction.get(usernameRef);
        if (usernameDoc.exists) {
          final reservedUserId = usernameDoc.data()?['userId'] as String?;
          if (reservedUserId == null) {
            usernameExists = true;
            return;
          }
          final reservedUserDoc = await transaction.get(
            _firestore.doc('users/$reservedUserId'),
          );
          if (reservedUserDoc.exists) {
            usernameExists = true;
            return;
          }
        }
        transaction.set(usernameRef, {
          'userId': userId,
          'authEmail': authEmail,
          'createdAt': now.toIso8601String(),
        });
        transaction.set(_firestore.doc('users/$userId'), {
          ...profile.toMap(),
          'email': null,
        });
        transaction.set(_firestore.doc('users/$userId/private/account'), {
          'email': normalizedEmail,
          'phone': normalizedPhone,
          'authEmail': authEmail,
          'createdAt': now.toIso8601String(),
        });
        transaction.set(
          _firestore.doc('globalContest/current/brackets/$userId'),
          Bracket.empty(userId).toMap(),
        );
      });
    } catch (_) {
      await _discardCreatedAuthUser(credential);
      rethrow;
    }

    if (usernameExists) {
      await _discardCreatedAuthUser(credential);
      throw StateError('That username is already taken.');
    }

    return profile;
  }

  @override
  Future<void> signInWithIdentifierAndPassword({
    required String identifier,
    required String password,
  }) async {
    final authEmail = await _authEmailForIdentifier(identifier);
    final credential = await _auth.signInWithEmailAndPassword(
      email: authEmail,
      password: password,
    );
    final userId = credential.user?.uid ?? _userId;
    final profile = await _profileForUserId(userId);
    if (profile == null) {
      await _auth.signOut();
      throw StateError(
        'Sign-in worked, but no bracket profile was found. Create a new account or ask the bracket admin to repair this account.',
      );
    }
  }

  @override
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user ?? _auth.currentUser;
    if (user != null && _isConfiguredAdminEmail(user.email)) {
      try {
        await _ensureAdminProfile(user);
      } catch (error) {
        await _auth.signOut();
        throw StateError(
          'Admin sign-in worked, but the admin profile could not be prepared: $error',
        );
      }
    }
  }

  @override
  Future<void> sendPasswordReset(String identifier) async {
    final authEmail = await _authEmailForIdentifier(identifier);
    if (_isSyntheticAuthEmail(authEmail)) {
      throw StateError(
        'This account uses phone contact only. Ask the bracket admin to help recover it.',
      );
    }
    await _auth.sendPasswordResetEmail(email: authEmail);
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
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
        .doc('globalContest/current/brackets/${bracket.userId}')
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
        .doc('globalContest/current/brackets/${bracket.userId}')
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
  Future<void> saveFixtureResult(Fixture fixture, {String? note}) async {
    final admin = await _requireAdminProfile();
    final validationError = AdminValidators.validateFixtureResult(fixture);
    if (validationError != null) {
      throw ArgumentError(validationError);
    }
    final now = DateTime.now();
    final fixtureRef = _firestore.doc('fixtures/${fixture.id}');
    final beforeSnapshot = await fixtureRef.get();
    final before = beforeSnapshot.data();
    final updated = fixture.copyWith(updatedAt: now, updatedBy: admin.id);
    final batch = _firestore.batch();
    batch.set(fixtureRef, updated.toMap(), SetOptions(merge: true));

    if (updated.stage != TournamentStage.group &&
        updated.status == FixtureStatus.finished &&
        updated.winnerCountryId != null) {
      final officialRef = _officialResultsRef();
      final official = await _currentOfficialResults();
      final winners = {...official.knockoutWinnersBySlot};
      winners[updated.id] = updated.winnerCountryId!;
      batch.set(
        officialRef,
        official
            .copyWith(
              knockoutWinnersBySlot: winners,
              finalChampionScore:
                  updated.stage == TournamentStage.finalMatch
                      ? _winnerScore(updated)
                      : official.finalChampionScore,
              finalRunnerUpScore:
                  updated.stage == TournamentStage.finalMatch
                      ? _runnerUpScore(updated)
                      : official.finalRunnerUpScore,
              updatedAt: now,
              updatedBy: admin.id,
            )
            .toMap(),
        SetOptions(merge: true),
      );
    }

    _writeAuditLog(
      batch,
      operationType: AdminAuditOperation.fixtureResult,
      before: before,
      after: updated.toMap(),
      admin: admin,
      note: note,
      now: now,
    );
    await batch.commit();
    if (updated.stage == TournamentStage.group) {
      await recalculateStandings(note: 'Group result save');
    }
    await recalculateLeaderboard(note: 'Result save');
  }

  @override
  Future<StandingsRecalculationSummary> recalculateStandings({
    String? note,
  }) async {
    final admin = await _requireAdminProfile();
    final now = DateTime.now();
    final fixturesSnapshot = await _firestore.collection('fixtures').get();
    final fixtures =
        fixturesSnapshot.docs
            .map((doc) => Fixture.fromMap(doc.id, doc.data()))
            .toList();
    final existing = await _currentStandings();
    final overrides = {
      for (final standing in existing)
        standing.groupId: standing.overrideOrderCountryIds,
    };
    final standings = const StandingsCalculator().calculate(
      fixtures: fixtures,
      overrideOrdersByGroup: overrides,
      updatedAt: now,
      updatedBy: admin.id,
    );
    final writes = <void Function(WriteBatch)>[
      for (final standing in standings)
        (batch) => batch.set(
          _firestore.doc('standings/${standing.groupId}'),
          standing.toMap(),
          SetOptions(merge: true),
        ),
      (batch) => _writeAuditLog(
        batch,
        operationType: AdminAuditOperation.standingsRecalculation,
        after: {'groupsUpdated': standings.length},
        admin: admin,
        note: note,
        now: now,
      ),
    ];
    await _commitInChunks(writes);
    return StandingsRecalculationSummary(
      groupsUpdated: standings.length,
      recalculatedAt: now,
    );
  }

  @override
  Future<void> saveStandingOverrideOrder({
    required String groupId,
    required List<String> countryIds,
    String? note,
  }) async {
    final admin = await _requireAdminProfile();
    final allowed = BracketRules.groupCountryIds[groupId] ?? const [];
    if (countryIds.toSet().length != allowed.length ||
        !countryIds.toSet().containsAll(allowed)) {
      throw ArgumentError(
        'Override order must include every team in Group $groupId.',
      );
    }
    final now = DateTime.now();
    final standings = await _currentStandings();
    final before =
        standings.where((standing) => standing.groupId == groupId).firstOrNull;
    final overrides = {
      for (final standing in standings)
        standing.groupId:
            standing.groupId == groupId
                ? countryIds
                : standing.overrideOrderCountryIds,
      if (!standings.any((standing) => standing.groupId == groupId))
        groupId: countryIds,
    };
    final fixturesSnapshot = await _firestore.collection('fixtures').get();
    final fixtures =
        fixturesSnapshot.docs
            .map((doc) => Fixture.fromMap(doc.id, doc.data()))
            .toList();
    final updated = const StandingsCalculator()
        .calculate(
          fixtures: fixtures,
          overrideOrdersByGroup: overrides,
          updatedAt: now,
          updatedBy: admin.id,
        )
        .firstWhere((standing) => standing.groupId == groupId);
    final batch = _firestore.batch();
    batch.set(
      _firestore.doc('standings/$groupId'),
      updated.toMap(),
      SetOptions(merge: true),
    );
    _writeAuditLog(
      batch,
      operationType: AdminAuditOperation.standingsOverride,
      before: before?.toMap(),
      after: updated.toMap(),
      admin: admin,
      note: note,
      now: now,
    );
    await batch.commit();
  }

  @override
  Future<void> saveGroupAdvancers(
    OfficialGroupPlacements placements, {
    String? note,
  }) async {
    final admin = await _requireAdminProfile();
    final validationError = AdminValidators.validateGroupPlacements(placements);
    if (validationError != null) {
      throw ArgumentError(validationError);
    }
    final now = DateTime.now();
    final officialRef = _officialResultsRef();
    final before = (await officialRef.get()).data();
    final updated = OfficialResults.fromMap(before ?? const {}).copyWith(
      advancingCountryIds: placements.advancingCountryIds,
      groupPlacements: placements,
      updatedAt: now,
      updatedBy: admin.id,
    );
    final batch = _firestore.batch();
    batch.set(officialRef, updated.toMap(), SetOptions(merge: true));
    _writeAuditLog(
      batch,
      operationType: AdminAuditOperation.groupAdvancers,
      before: before,
      after: updated.toMap(),
      admin: admin,
      note: note,
      now: now,
    );
    await batch.commit();
    await recalculateLeaderboard(note: 'Group advancers save');
  }

  @override
  Future<LeaderboardRecalculationSummary> recalculateLeaderboard({
    String? note,
  }) async {
    final admin = await _requireAdminProfile();
    final now = DateTime.now();
    final config = await _currentConfig();
    final officialResults = await _currentOfficialResults();
    final bracketsSnapshot =
        await _firestore
            .collection('globalContest/current/brackets')
            .where('status', isEqualTo: BracketStatus.submitted.name)
            .get();
    final brackets =
        bracketsSnapshot.docs
            .map((doc) => Bracket.fromMap(doc.id, doc.data()))
            .toList();
    final usersById = await _usersById();
    final recalculator = const LeaderboardRecalculator();
    final scored = recalculator.scoreBrackets(
      brackets: brackets,
      officialResults: officialResults,
      pointsPerCorrectPick: config.pointsPerCorrectPick,
    );
    final entries = recalculator.buildEntries(
      scoredBrackets: scored,
      usersById: usersById,
      updatedAt: now,
    );

    final writes = <void Function(WriteBatch)>[
      for (final scoredBracket in scored)
        (batch) => batch.set(
          _firestore.doc(
            'globalContest/current/brackets/${scoredBracket.bracket.userId}',
          ),
          scoredBracket.bracket
              .copyWith(
                totalScore: scoredBracket.breakdown.totalScore,
                groupScore: scoredBracket.breakdown.groupScore,
                knockoutScore: scoredBracket.breakdown.knockoutScore,
                tiebreakerDistance: scoredBracket.breakdown.tiebreakerDistance,
                updatedAt: now,
              )
              .toMap(),
          SetOptions(merge: true),
        ),
      for (final entry in entries)
        (batch) => batch.set(
          _firestore.doc('leaderboards/global/entries/${entry.userId}'),
          entry.toMap(),
          SetOptions(merge: true),
        ),
      (batch) => batch.set(_officialResultsRef(), {
        'leaderboardUpdatedAt': now.toIso8601String(),
      }, SetOptions(merge: true)),
      (batch) => _writeAuditLog(
        batch,
        operationType: AdminAuditOperation.leaderboardRecalculation,
        after: {'entriesUpdated': entries.length},
        admin: admin,
        note: note,
        now: now,
      ),
    ];
    await _commitInChunks(writes);
    return LeaderboardRecalculationSummary(
      entriesUpdated: entries.length,
      recalculatedAt: now,
    );
  }

  @override
  Future<ApiFootballSyncSummary> triggerApiFootballSync() async {
    await _requireAdminProfile();
    await _auth.currentUser?.getIdToken(true);
    final result = await _functions
        .httpsCallable('syncWorldCupDataNow')
        .call();
    final data = Map<String, Object?>.from(result.data as Map);
    return ApiFootballSyncSummary.fromMap(data);
  }

  @override
  Future<void> updateContestConfig(
    GlobalContestConfig config, {
    String? note,
    bool recalculateAfterSave = false,
  }) async {
    final admin = await _requireAdminProfile();
    if (config.pointsPerCorrectPick <= 0) {
      throw ArgumentError('Points per correct pick must be greater than zero.');
    }
    final now = DateTime.now();
    final configRef = _firestore.doc('globalContest/current/config/current');
    final before = (await configRef.get()).data();
    final updated = config.copyWith(updatedAt: now, updatedBy: admin.id);
    final batch = _firestore.batch();
    batch.set(configRef, updated.toMap(), SetOptions(merge: true));
    _writeAuditLog(
      batch,
      operationType: AdminAuditOperation.contestSettings,
      before: before,
      after: updated.toMap(),
      admin: admin,
      note: note,
      now: now,
    );
    await batch.commit();
    if (recalculateAfterSave) {
      await recalculateLeaderboard(note: 'Contest settings save');
    }
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
    final snapshot =
        await _firestore.doc('globalContest/current/config/current').get();
    return GlobalContestConfig.fromMap(snapshot.data() ?? const {});
  }

  DocumentReference<Map<String, dynamic>> _officialResultsRef() {
    return _firestore.doc('globalContest/current/officialResults/current');
  }

  Future<OfficialResults> _currentOfficialResults() async {
    final snapshot = await _officialResultsRef().get();
    return OfficialResults.fromMap(snapshot.data() ?? const {});
  }

  Future<List<GroupStanding>> _currentStandings() async {
    final snapshot = await _firestore.collection('standings').get();
    return snapshot.docs
        .map((doc) => GroupStanding.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<AppUser> _requireProfile() async {
    final profile = await _profileForUserId(_userId);
    if (profile == null) {
      throw StateError('Create a username profile before posting in chat.');
    }
    return profile;
  }

  Future<AppUser> _requireAdminProfile() async {
    final profile = await _requireProfile();
    final firebaseEmail = _publicEmailFor(_auth.currentUser?.email);
    final adminProfile = AppUser(
      id: profile.id,
      username: profile.username,
      email: firebaseEmail ?? profile.email,
      createdAt: profile.createdAt,
      linkedProviders: profile.linkedProviders,
      isHidden: profile.isHidden,
    );
    if (!AdminAccess.isAdmin(adminProfile)) {
      throw StateError('Admin access is required.');
    }
    return adminProfile;
  }

  Future<AppUser?> _profileForUserId(String userId) async {
    final snapshot = await _firestore.doc('users/$userId').get();
    final data = snapshot.data();
    if (data == null) {
      return null;
    }
    return AppUser.fromMap(snapshot.id, data);
  }

  Future<void> _ensureAdminProfile(auth.User firebaseUser) async {
    final email = _publicEmailFor(firebaseUser.email);
    if (!_isConfiguredAdminEmail(email)) {
      return;
    }
    final userRef = _firestore.doc('users/${firebaseUser.uid}');
    final snapshot = await userRef.get();
    if (!snapshot.exists) {
      final now = DateTime.now();
      await userRef.set(
        AppUser(
          id: firebaseUser.uid,
          username: 'AdminUser',
          email: null,
          createdAt: now,
        ).toMap(),
      );
      await _firestore.doc('users/${firebaseUser.uid}/private/account').set({
        'email': email,
        'authEmail': email,
        'createdAt': now.toIso8601String(),
      });
    }
  }

  bool _isConfiguredAdminEmail(String? email) {
    return email?.trim().toLowerCase() ==
        AdminAccess.adminEmail.trim().toLowerCase();
  }

  Future<AppUser?> _userForBracket(String userId) async {
    final snapshot = await _firestore.doc('users/$userId').get();
    final data = snapshot.data();
    if (data == null) {
      return null;
    }
    return AppUser.fromMap(snapshot.id, data);
  }

  Future<Map<String, AppUser>> _usersById() async {
    final snapshot = await _firestore.collection('users').get();
    return {
      for (final doc in snapshot.docs)
        doc.id: AppUser.fromMap(doc.id, doc.data()),
    };
  }

  void _writeAuditLog(
    WriteBatch batch, {
    required AdminAuditOperation operationType,
    required Map<String, Object?> after,
    required AppUser admin,
    required DateTime now,
    Map<String, Object?>? before,
    String? note,
  }) {
    batch.set(
      _firestore.collection('adminAuditLogs').doc(),
      AdminAuditLog(
        id: '',
        operationType: operationType,
        before: before,
        after: after,
        adminUserId: admin.id,
        adminEmail: admin.email ?? '',
        createdAt: now,
        note: note?.trim().isEmpty ?? true ? null : note!.trim(),
      ).toMap(),
    );
  }

  Future<void> _commitInChunks(
    List<void Function(WriteBatch batch)> writes,
  ) async {
    const maxWritesPerBatch = 450;
    for (var index = 0; index < writes.length; index += maxWritesPerBatch) {
      final batch = _firestore.batch();
      for (final write in writes.skip(index).take(maxWritesPerBatch)) {
        write(batch);
      }
      await batch.commit();
    }
  }

  int? _winnerScore(Fixture fixture) {
    if (fixture.winnerCountryId == fixture.homeCountryId) {
      return fixture.homeScore;
    }
    if (fixture.winnerCountryId == fixture.awayCountryId) {
      return fixture.awayScore;
    }
    return null;
  }

  int? _runnerUpScore(Fixture fixture) {
    if (fixture.winnerCountryId == fixture.homeCountryId) {
      return fixture.awayScore;
    }
    if (fixture.winnerCountryId == fixture.awayCountryId) {
      return fixture.homeScore;
    }
    return null;
  }

  List<Country> _officialCountries(List<Country> firestoreCountries) {
    final byId = {
      for (final country in sampleCountries) country.id: country,
      for (final country in firestoreCountries) country.id: country,
    };
    return [
      for (final countryId in BracketRules.officialCountryIds)
        if (byId[countryId] != null) byId[countryId]!,
    ];
  }

  Future<bool> _activeUsernameReservationExists(
    DocumentSnapshot<Map<String, dynamic>> usernameSnapshot,
  ) async {
    if (!usernameSnapshot.exists) {
      return false;
    }
    final reservedUserId = usernameSnapshot.data()?['userId'] as String?;
    if (reservedUserId == null) {
      return true;
    }
    final reservedUser = await _firestore.doc('users/$reservedUserId').get();
    return reservedUser.exists;
  }

  Future<void> _discardCreatedAuthUser(auth.UserCredential credential) async {
    try {
      await credential.user?.delete();
    } catch (_) {
      // If cleanup fails, still sign out so the app does not keep an orphaned
      // Firebase Auth session without a matching bracket profile.
    }
    await _auth.signOut();
  }

  Future<String> _authEmailForIdentifier(String identifier) async {
    final trimmed = identifier.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Enter your username or email.');
    }
    if (trimmed.contains('@')) {
      final email = _normalizeOptionalEmail(trimmed);
      if (email == null) {
        throw ArgumentError('Enter a valid email address.');
      }
      return email;
    }

    final validationError = UsernameValidator.validate(trimmed);
    if (validationError != null) {
      throw ArgumentError(validationError);
    }
    final normalized = UsernameValidator.normalize(trimmed);
    final snapshot = await _firestore.doc('usernames/$normalized').get();
    final data = snapshot.data();
    final authEmail = data?['authEmail'] as String?;
    if (authEmail == null || authEmail.isEmpty) {
      throw StateError('No account found for that username.');
    }
    return authEmail;
  }

  String? _normalizeOptionalEmail(String? email) {
    final trimmed = email?.trim().toLowerCase();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    final hasBasicShape = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(trimmed);
    if (!hasBasicShape) {
      throw ArgumentError('Enter a valid email address.');
    }
    return trimmed;
  }

  String? _normalizeOptionalPhone(String? phone) {
    final trimmed = phone?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) {
      throw ArgumentError('Enter a valid phone number.');
    }
    return trimmed;
  }

  String _syntheticAuthEmail(String normalizedUsername) {
    return '$normalizedUsername@users.rickyworldcupbracket.com';
  }

  bool _isSyntheticAuthEmail(String email) {
    return email.toLowerCase().endsWith('@users.rickyworldcupbracket.com');
  }

  String? _publicEmailFor(String? email) {
    if (email == null || _isSyntheticAuthEmail(email)) {
      return null;
    }
    return email;
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
