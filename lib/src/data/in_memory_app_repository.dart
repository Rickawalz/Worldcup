import 'dart:async';

import '../admin/admin_access.dart';
import '../domain/admin_validators.dart';
import '../domain/bracket_rules.dart';
import '../domain/leaderboard_recalculator.dart';
import '../domain/models.dart';
import '../domain/standings_calculator.dart';
import 'app_repository.dart';
import 'sample_data.dart';
import 'username_validator.dart';

class InMemoryAppRepository implements AppRepository {
  InMemoryAppRepository() {
    _configController.add(_config);
    _countriesController.add(sampleCountries);
    _fixturesController.add(_fixtures);
    _standingsController.add(_standings);
    _leaderboardController.add(_leaderboard);
    _bracketController.add(_bracket);
    _officialResultsController.add(_officialResults);
    _chatController.add(_chatMessages);
    _syncStateController.add(_syncState);
  }

  final _userController = StreamController<AppUser?>.broadcast();
  final _configController = StreamController<GlobalContestConfig>.broadcast();
  final _countriesController = StreamController<List<Country>>.broadcast();
  final _bracketController = StreamController<Bracket>.broadcast();
  final _leaderboardController =
      StreamController<List<LeaderboardEntry>>.broadcast();
  final _fixturesController = StreamController<List<Fixture>>.broadcast();
  final _standingsController =
      StreamController<List<GroupStanding>>.broadcast();
  final _officialResultsController =
      StreamController<OfficialResults>.broadcast();
  final _auditController = StreamController<List<AdminAuditLog>>.broadcast();
  final _chatController = StreamController<List<ChatMessage>>.broadcast();
  final _syncStateController =
      StreamController<ApiFootballSyncState>.broadcast();

  AppUser? _user;
  GlobalContestConfig _config = GlobalContestConfig(
    lockAt: DateTime.utc(2026, 6, 11, 19),
  );
  Bracket _bracket = Bracket.empty('demo-user');
  final _accountsByUsername = <String, _MemoryAccount>{};
  final _accountsByEmail = <String, _MemoryAccount>{};
  final _usersById = <String, AppUser>{};
  final _bracketsByUserId = <String, Bracket>{};
  List<Fixture> _fixtures = [...sampleFixtures];
  List<GroupStanding> _standings = const StandingsCalculator().calculate(
    fixtures: sampleFixtures,
    overrideOrdersByGroup: const {},
  );
  OfficialResults _officialResults = const OfficialResults();
  List<LeaderboardEntry> _leaderboard = [
    const LeaderboardEntry(
      userId: 'demo-1',
      username: 'BracketBoss',
      score: 18,
      tiebreakerDistance: 1,
      rank: 1,
    ),
    const LeaderboardEntry(
      userId: 'demo-2',
      username: 'GoldenBoot',
      score: 16,
      tiebreakerDistance: 2,
      rank: 2,
    ),
  ];

  final _auditLogs = <AdminAuditLog>[];
  ApiFootballSyncState _syncState = const ApiFootballSyncState();
  final _chatMessages = <ChatMessage>[
    ChatMessage(
      id: 'chat-seed-1',
      userId: 'demo-1',
      username: 'BracketBoss',
      text: 'Who is everyone picking to win it all?',
      createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 12)),
      reactions: const {'⚽': 2},
    ),
    ChatMessage(
      id: 'chat-seed-2',
      userId: 'demo-2',
      username: 'GoldenBoot',
      text: 'Brazil looks dangerous, but France is hard to ignore.',
      createdAt: DateTime.now().subtract(const Duration(minutes: 8)),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 8)),
      reactions: const {'🔥': 1},
    ),
  ];

  @override
  Stream<AppUser?> watchCurrentUser() async* {
    yield _user;
    yield* _userController.stream;
  }

  @override
  Stream<GlobalContestConfig> watchGlobalContestConfig() async* {
    yield _config;
    yield* _configController.stream;
  }

  @override
  Stream<List<Country>> watchCountries() async* {
    yield sampleCountries;
    yield* _countriesController.stream;
  }

  @override
  Stream<Bracket> watchMyBracket() async* {
    yield _bracket;
    yield* _bracketController.stream;
  }

  @override
  Stream<List<LeaderboardEntry>> watchLeaderboard() async* {
    yield _leaderboard;
    yield* _leaderboardController.stream;
  }

  @override
  Stream<List<PublicBracketProfile>> watchPublicBracketProfiles() async* {
    yield _publicBracketProfiles();
    yield* _bracketController.stream.map((_) => _publicBracketProfiles());
  }

  @override
  Stream<PublicBracketProfile?> watchPublicBracketProfile(
    String userId,
  ) async* {
    yield _publicBracketProfile(userId);
    yield* _bracketController.stream.map((_) => _publicBracketProfile(userId));
  }

  @override
  Stream<List<Fixture>> watchFixtures() async* {
    yield _fixtures;
    yield* _fixturesController.stream;
  }

  @override
  Stream<List<GroupStanding>> watchStandings() async* {
    yield _standings;
    yield* _standingsController.stream;
  }

  @override
  Stream<OfficialResults> watchOfficialResults() async* {
    yield _officialResults;
    yield* _officialResultsController.stream;
  }

  @override
  Stream<List<AdminAuditLog>> watchAdminAuditLogs() async* {
    yield _auditLogs;
    yield* _auditController.stream;
  }

  @override
  Stream<ApiFootballSyncState> watchApiFootballSyncState() async* {
    yield _syncState;
    yield* _syncStateController.stream;
  }

  @override
  Stream<List<ChatMessage>> watchGlobalChatMessages() async* {
    yield _visibleChatMessages();
    yield* _chatController.stream;
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
    final existingAccount = _accountsByUsername[normalized];
    if (existingAccount != null &&
        _usersById.containsKey(existingAccount.user.id)) {
      throw StateError('That username is already taken.');
    }
    if (existingAccount != null && existingAccount.email != null) {
      _accountsByEmail.remove(existingAccount.email);
    }
    final user = AppUser(
      id: 'demo-user-$normalized',
      username: username.trim(),
      email: normalizedEmail,
      createdAt: DateTime.now(),
    );
    final account = _MemoryAccount(
      user: user,
      password: password,
      email: normalizedEmail,
      phone: normalizedPhone,
    );
    _accountsByUsername[normalized] = account;
    if (normalizedEmail != null) {
      _accountsByEmail[normalizedEmail] = account;
    }
    _usersById[user.id] = user;
    _bracket = Bracket.empty(user.id);
    _bracketsByUserId[user.id] = _bracket;
    _user = user;
    _userController.add(_user);
    _bracketController.add(_bracket);
    return user;
  }

  @override
  Future<void> signInWithIdentifierAndPassword({
    required String identifier,
    required String password,
  }) async {
    final account = _accountForIdentifier(identifier);
    if (account == null || account.password != password) {
      throw StateError('Invalid username/email or password.');
    }
    _user = account.user;
    _bracket =
        _bracketsByUserId[account.user.id] ?? Bracket.empty(account.user.id);
    _bracketsByUserId[account.user.id] = _bracket;
    _userController.add(_user);
    _bracketController.add(_bracket);
  }

  @override
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (email.trim().toLowerCase() != AdminAccess.adminEmail.toLowerCase() ||
        password.isEmpty) {
      throw StateError('Invalid admin email or password.');
    }
    final user = AppUser(
      id: 'demo-admin',
      username: 'Admin',
      email: AdminAccess.adminEmail,
      createdAt: DateTime.now(),
    );
    _user = user;
    _usersById[user.id] = user;
    _bracket = _bracketsByUserId[user.id] ?? Bracket.empty(user.id);
    _bracketsByUserId[user.id] = _bracket;
    _userController.add(_user);
    _bracketController.add(_bracket);
  }

  @override
  Future<void> sendPasswordReset(String identifier) async {
    final account = _accountForIdentifier(identifier);
    if (account == null) {
      throw StateError('No account found for that username or email.');
    }
    if (account.email == null) {
      throw StateError(
        'This account uses phone contact only. Ask the bracket admin to help recover it.',
      );
    }
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _userController.add(null);
  }

  @override
  Future<void> linkAccount(AuthProviderLink provider) async {
    final user = _user;
    if (user == null) {
      throw StateError('Create a profile before linking an account.');
    }
    _user = AppUser(
      id: user.id,
      username: user.username,
      email: user.email,
      createdAt: user.createdAt,
      linkedProviders: {...user.linkedProviders, provider},
      isHidden: user.isHidden,
    );
    _userController.add(_user);
  }

  @override
  Future<void> saveBracket(Bracket bracket) async {
    if (!_config.areSubmissionsOpen) {
      throw StateError('This bracket is locked.');
    }
    _bracket = bracket.copyWith(updatedAt: DateTime.now());
    _bracketsByUserId[_bracket.userId] = _bracket;
    _bracketController.add(_bracket);
  }

  @override
  Future<void> submitBracket(Bracket bracket) async {
    if (!BracketRules.canSubmit(bracket, _config)) {
      throw StateError('Complete every group and knockout pick before submit.');
    }
    _bracket = bracket.copyWith(
      status: BracketStatus.submitted,
      submittedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _bracketsByUserId[_bracket.userId] = _bracket;
    _bracketController.add(_bracket);
  }

  @override
  Future<void> saveFixtureResult(Fixture fixture, {String? note}) async {
    _requireAdmin();
    final validationError = AdminValidators.validateFixtureResult(fixture);
    if (validationError != null) {
      throw ArgumentError(validationError);
    }
    final now = DateTime.now();
    final before =
        _fixtures.where((item) => item.id == fixture.id).firstOrNull?.toMap();
    final updated = fixture.copyWith(updatedAt: now, updatedBy: _user!.id);
    final index = _fixtures.indexWhere((item) => item.id == fixture.id);
    if (index == -1) {
      _fixtures = [..._fixtures, updated]
        ..sort((a, b) => a.kickoff.compareTo(b.kickoff));
    } else {
      _fixtures = [..._fixtures]..[index] = updated;
    }
    if (updated.stage != TournamentStage.group &&
        updated.status == FixtureStatus.finished &&
        updated.winnerCountryId != null) {
      final winners = {..._officialResults.knockoutWinnersBySlot};
      winners[updated.id] = updated.winnerCountryId!;
      _officialResults = _officialResults.copyWith(
        knockoutWinnersBySlot: winners,
        finalChampionScore:
            updated.stage == TournamentStage.finalMatch
                ? _winnerScore(updated)
                : _officialResults.finalChampionScore,
        finalRunnerUpScore:
            updated.stage == TournamentStage.finalMatch
                ? _runnerUpScore(updated)
                : _officialResults.finalRunnerUpScore,
        updatedAt: now,
        updatedBy: _user!.id,
      );
      _officialResultsController.add(_officialResults);
    }
    _fixturesController.add(_fixtures);
    if (updated.stage == TournamentStage.group) {
      await recalculateStandings(note: 'Group result save');
    }
    _appendAuditLog(
      operationType: AdminAuditOperation.fixtureResult,
      before: before,
      after: updated.toMap(),
      note: note,
      now: now,
    );
    await recalculateLeaderboard(note: 'Result save');
  }

  @override
  Future<StandingsRecalculationSummary> recalculateStandings({
    String? note,
  }) async {
    _requireAdmin();
    final now = DateTime.now();
    final overrides = {
      for (final standing in _standings)
        standing.groupId: standing.overrideOrderCountryIds,
    };
    _standings = const StandingsCalculator().calculate(
      fixtures: _fixtures,
      overrideOrdersByGroup: overrides,
      updatedAt: now,
      updatedBy: _user!.id,
    );
    _standingsController.add(_standings);
    _appendAuditLog(
      operationType: AdminAuditOperation.standingsRecalculation,
      after: {'groupsUpdated': _standings.length},
      note: note,
      now: now,
    );
    return StandingsRecalculationSummary(
      groupsUpdated: _standings.length,
      recalculatedAt: now,
    );
  }

  @override
  Future<void> saveStandingOverrideOrder({
    required String groupId,
    required List<String> countryIds,
    String? note,
  }) async {
    _requireAdmin();
    final allowed = BracketRules.groupCountryIds[groupId] ?? const [];
    if (countryIds.toSet().length != allowed.length ||
        !countryIds.toSet().containsAll(allowed)) {
      throw ArgumentError(
        'Override order must include every team in Group $groupId.',
      );
    }
    final now = DateTime.now();
    final before =
        _standings.where((standing) => standing.groupId == groupId).firstOrNull;
    final overrides = {
      for (final standing in _standings)
        standing.groupId:
            standing.groupId == groupId
                ? countryIds
                : standing.overrideOrderCountryIds,
      if (!_standings.any((standing) => standing.groupId == groupId))
        groupId: countryIds,
    };
    _standings = const StandingsCalculator().calculate(
      fixtures: _fixtures,
      overrideOrdersByGroup: overrides,
      updatedAt: now,
      updatedBy: _user!.id,
    );
    _standingsController.add(_standings);
    _appendAuditLog(
      operationType: AdminAuditOperation.standingsOverride,
      before: before?.toMap(),
      after:
          _standings
              .firstWhere((standing) => standing.groupId == groupId)
              .toMap(),
      note: note,
      now: now,
    );
  }

  @override
  Future<void> saveGroupAdvancers(
    OfficialGroupPlacements placements, {
    String? note,
  }) async {
    _requireAdmin();
    final validationError = AdminValidators.validateGroupPlacements(placements);
    if (validationError != null) {
      throw ArgumentError(validationError);
    }
    final now = DateTime.now();
    final before = _officialResults.toMap();
    _officialResults = _officialResults.copyWith(
      advancingCountryIds: placements.advancingCountryIds,
      groupPlacements: placements,
      updatedAt: now,
      updatedBy: _user!.id,
    );
    _officialResultsController.add(_officialResults);
    _appendAuditLog(
      operationType: AdminAuditOperation.groupAdvancers,
      before: before,
      after: _officialResults.toMap(),
      note: note,
      now: now,
    );
    await recalculateLeaderboard(note: 'Group advancers save');
  }

  @override
  Future<LeaderboardRecalculationSummary> recalculateLeaderboard({
    String? note,
  }) async {
    _requireAdmin();
    final now = DateTime.now();
    final submittedBrackets = _bracketsByUserId.values.where(
      (bracket) => bracket.status == BracketStatus.submitted,
    );
    final recalculator = const LeaderboardRecalculator();
    final scored = recalculator.scoreBrackets(
      brackets: submittedBrackets,
      officialResults: _officialResults,
      pointsPerCorrectPick: _config.pointsPerCorrectPick,
    );
    for (final scoredBracket in scored) {
      _bracketsByUserId[scoredBracket.bracket.userId] = scoredBracket.bracket
          .copyWith(
            totalScore: scoredBracket.breakdown.totalScore,
            groupScore: scoredBracket.breakdown.groupScore,
            knockoutScore: scoredBracket.breakdown.knockoutScore,
            tiebreakerDistance: scoredBracket.breakdown.tiebreakerDistance,
            updatedAt: now,
          );
    }
    _leaderboard = recalculator.buildEntries(
      scoredBrackets: scored,
      usersById: _usersById,
      updatedAt: now,
    );
    _officialResults = _officialResults.copyWith(leaderboardUpdatedAt: now);
    _leaderboardController.add(_leaderboard);
    _bracketController.add(_bracket);
    _officialResultsController.add(_officialResults);
    _appendAuditLog(
      operationType: AdminAuditOperation.leaderboardRecalculation,
      after: {'entriesUpdated': _leaderboard.length},
      note: note,
      now: now,
    );
    return LeaderboardRecalculationSummary(
      entriesUpdated: _leaderboard.length,
      recalculatedAt: now,
    );
  }

  @override
  Future<ApiFootballSyncSummary> triggerApiFootballSync() async {
    _requireAdmin();
    final now = DateTime.now();
    _syncState = ApiFootballSyncState(
      lastSyncAt: now,
      fixturesUpdated: 0,
      skippedAdmin: 0,
      skippedUnmatched: 0,
      skippedUnchanged: 0,
      knockoutResultsUpdated: 0,
      source: 'manual',
    );
    _syncStateController.add(_syncState);
    return ApiFootballSyncSummary(
      fixturesUpdated: 0,
      skippedAdmin: 0,
      skippedUnmatched: 0,
      skippedUnchanged: 0,
      knockoutResultsUpdated: 0,
      apiFixturesReceived: 0,
      localFixturesLoaded: _fixtures.length,
      countriesWithApiId: sampleCountries.where((c) => c.apiFootballTeamId > 0).length,
      countriesEnrichedFromApi: 0,
      source: 'manual',
    );
  }

  @override
  Future<void> updateContestConfig(
    GlobalContestConfig config, {
    String? note,
    bool recalculateAfterSave = false,
  }) async {
    _requireAdmin();
    if (config.pointsPerCorrectPick <= 0) {
      throw ArgumentError('Points per correct pick must be greater than zero.');
    }
    final now = DateTime.now();
    final before = _config.toMap();
    _config = config.copyWith(updatedAt: now, updatedBy: _user!.id);
    _configController.add(_config);
    _appendAuditLog(
      operationType: AdminAuditOperation.contestSettings,
      before: before,
      after: _config.toMap(),
      note: note,
      now: now,
    );
    if (recalculateAfterSave) {
      await recalculateLeaderboard(note: 'Contest settings save');
    }
  }

  @override
  Future<void> sendChatMessage(String text) async {
    final user = _requireProfile();
    final normalized = _normalizeMessageText(text);
    final now = DateTime.now();
    _chatMessages.insert(
      0,
      ChatMessage(
        id: 'chat-${now.microsecondsSinceEpoch}',
        userId: user.id,
        username: user.username,
        text: normalized,
        createdAt: now,
        updatedAt: now,
      ),
    );
    _emitChat();
  }

  @override
  Future<void> editChatMessage({
    required String messageId,
    required String text,
  }) async {
    final user = _requireProfile();
    final index = _chatMessages.indexWhere(
      (message) => message.id == messageId,
    );
    if (index == -1) return;
    final message = _chatMessages[index];
    if (!message.canBeChangedBy(user.id)) {
      throw StateError('You can only edit your own messages.');
    }
    _chatMessages[index] = message.copyWith(
      text: _normalizeMessageText(text),
      updatedAt: DateTime.now(),
      isEdited: true,
    );
    _emitChat();
  }

  @override
  Future<void> deleteChatMessage(String messageId) async {
    final user = _requireProfile();
    final index = _chatMessages.indexWhere(
      (message) => message.id == messageId,
    );
    if (index == -1) return;
    final message = _chatMessages[index];
    if (!message.canBeChangedBy(user.id)) {
      throw StateError('You can only delete your own messages.');
    }
    _chatMessages[index] = message.copyWith(
      text: '',
      updatedAt: DateTime.now(),
      isDeleted: true,
    );
    _emitChat();
  }

  @override
  Future<void> reactToChatMessage({
    required String messageId,
    required String emoji,
  }) async {
    _requireProfile();
    final trimmedEmoji = emoji.trim();
    if (trimmedEmoji.isEmpty) return;
    final index = _chatMessages.indexWhere(
      (message) => message.id == messageId,
    );
    if (index == -1) return;
    final message = _chatMessages[index];
    final reactions = {...message.reactions};
    reactions[trimmedEmoji] = (reactions[trimmedEmoji] ?? 0) + 1;
    _chatMessages[index] = message.copyWith(
      reactions: reactions,
      updatedAt: DateTime.now(),
    );
    _emitChat();
  }

  @override
  Future<void> report({
    required ReportTargetType targetType,
    required String targetId,
    required String reason,
  }) async {
    if (reason.trim().isEmpty) {
      throw ArgumentError('Report reason is required.');
    }
  }

  @override
  Future<void> setNotificationsEnabled(bool enabled) async {}

  AppUser _requireProfile() {
    final user = _user;
    if (user == null) {
      throw StateError('Create a username profile before posting in chat.');
    }
    return user;
  }

  AppUser _requireAdmin() {
    final user = _requireProfile();
    if (!AdminAccess.isAdmin(user)) {
      throw StateError('Admin access is required.');
    }
    return user;
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

  List<ChatMessage> _visibleChatMessages() {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    return _chatMessages
        .where((message) => message.createdAt.isAfter(cutoff))
        .take(500)
        .toList(growable: false);
  }

  List<PublicBracketProfile> _publicBracketProfiles() {
    final profiles = <PublicBracketProfile>[];
    for (final bracket in _bracketsByUserId.values) {
      final user = _usersById[bracket.userId];
      if (user != null &&
          !user.isHidden &&
          bracket.status == BracketStatus.submitted) {
        profiles.add(PublicBracketProfile(user: user, bracket: bracket));
      }
    }
    profiles.sort(
      (a, b) => a.user.username.toLowerCase().compareTo(
        b.user.username.toLowerCase(),
      ),
    );
    return profiles;
  }

  PublicBracketProfile? _publicBracketProfile(String userId) {
    final user = _usersById[userId];
    final bracket = _bracketsByUserId[userId];
    if (user == null ||
        bracket == null ||
        user.isHidden ||
        bracket.status != BracketStatus.submitted) {
      return null;
    }
    return PublicBracketProfile(user: user, bracket: bracket);
  }

  _MemoryAccount? _accountForIdentifier(String identifier) {
    final trimmed = identifier.trim();
    if (trimmed.contains('@')) {
      return _accountsByEmail[trimmed.toLowerCase()];
    }
    final validationError = UsernameValidator.validate(trimmed);
    if (validationError != null) {
      throw ArgumentError(validationError);
    }
    return _accountsByUsername[UsernameValidator.normalize(trimmed)];
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

  void _emitChat() {
    _chatController.add(_visibleChatMessages());
  }

  void _appendAuditLog({
    required AdminAuditOperation operationType,
    required Map<String, Object?> after,
    required DateTime now,
    Map<String, Object?>? before,
    String? note,
  }) {
    final admin = _requireAdmin();
    _auditLogs.insert(
      0,
      AdminAuditLog(
        id: 'audit-${now.microsecondsSinceEpoch}',
        operationType: operationType,
        before: before,
        after: after,
        adminUserId: admin.id,
        adminEmail: admin.email ?? '',
        createdAt: now,
        note: note?.trim().isEmpty ?? true ? null : note!.trim(),
      ),
    );
    _auditController.add(_auditLogs);
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

  void debugDeleteUserProfile(String username) {
    final account = _accountsByUsername[UsernameValidator.normalize(username)];
    if (account == null) {
      return;
    }
    _usersById.remove(account.user.id);
    _bracketsByUserId.remove(account.user.id);
    if (_user?.id == account.user.id) {
      _user = null;
      _userController.add(null);
    }
    _bracketController.add(_bracket);
  }

  void dispose() {
    _userController.close();
    _configController.close();
    _countriesController.close();
    _bracketController.close();
    _leaderboardController.close();
    _fixturesController.close();
    _standingsController.close();
    _officialResultsController.close();
    _auditController.close();
    _chatController.close();
    _syncStateController.close();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _MemoryAccount {
  const _MemoryAccount({
    required this.user,
    required this.password,
    this.email,
    this.phone,
  });

  final AppUser user;
  final String password;
  final String? email;
  final String? phone;
}
