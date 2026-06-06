import 'dart:async';

import '../domain/bracket_rules.dart';
import '../domain/models.dart';
import 'app_repository.dart';
import 'sample_data.dart';
import 'username_validator.dart';

class InMemoryAppRepository implements AppRepository {
  InMemoryAppRepository() {
    _configController.add(_config);
    _countriesController.add(sampleCountries);
    _fixturesController.add(sampleFixtures);
    _leaderboardController.add(_leaderboard);
    _bracketController.add(_bracket);
    _chatController.add(_chatMessages);
  }

  final _userController = StreamController<AppUser?>.broadcast();
  final _configController = StreamController<GlobalContestConfig>.broadcast();
  final _countriesController = StreamController<List<Country>>.broadcast();
  final _bracketController = StreamController<Bracket>.broadcast();
  final _leaderboardController =
      StreamController<List<LeaderboardEntry>>.broadcast();
  final _fixturesController = StreamController<List<Fixture>>.broadcast();
  final _chatController = StreamController<List<ChatMessage>>.broadcast();

  AppUser? _user;
  Bracket _bracket = Bracket.empty('demo-user');
  final _reservedUsernames = <String>{};
  final _leaderboard = <LeaderboardEntry>[
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

  final _config = GlobalContestConfig(lockAt: DateTime.utc(2026, 6, 11, 19));
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
  Stream<List<Fixture>> watchFixtures() async* {
    yield sampleFixtures;
    yield* _fixturesController.stream;
  }

  @override
  Stream<List<ChatMessage>> watchGlobalChatMessages() async* {
    yield _visibleChatMessages();
    yield* _chatController.stream;
  }

  @override
  Future<AppUser> createUsernameProfile(String username) async {
    final validationError = UsernameValidator.validate(username);
    if (validationError != null) {
      throw ArgumentError(validationError);
    }
    final normalized = UsernameValidator.normalize(username);
    if (_reservedUsernames.contains(normalized)) {
      throw StateError('That username is already taken.');
    }
    _reservedUsernames.add(normalized);
    _user = AppUser(
      id: 'demo-user',
      username: username.trim(),
      email: null,
      createdAt: DateTime.now(),
    );
    _bracket = Bracket.empty(_user!.id);
    _userController.add(_user);
    _bracketController.add(_bracket);
    return _user!;
  }

  @override
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    throw StateError('Admin login requires Firebase Authentication.');
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
    if (!_config.isAcceptingSubmissions || _config.isLocked) {
      throw StateError('This bracket is locked.');
    }
    _bracket = bracket.copyWith(updatedAt: DateTime.now());
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
    _bracketController.add(_bracket);
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

  void _emitChat() {
    _chatController.add(_visibleChatMessages());
  }

  void dispose() {
    _userController.close();
    _configController.close();
    _countriesController.close();
    _bracketController.close();
    _leaderboardController.close();
    _fixturesController.close();
    _chatController.close();
  }
}
