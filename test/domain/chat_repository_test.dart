import 'package:flutter_test/flutter_test.dart';
import 'package:world_cup_bracket/src/admin/admin_access.dart';
import 'package:world_cup_bracket/src/data/in_memory_app_repository.dart';
import 'package:world_cup_bracket/src/domain/bracket_rules.dart';
import 'package:world_cup_bracket/src/domain/models.dart';

void main() {
  test('requires a username profile before sending chat messages', () async {
    final repository = InMemoryAppRepository();
    addTearDown(repository.dispose);

    expect(
      () => repository.sendChatMessage('hello'),
      throwsA(isA<StateError>()),
    );
  });

  test('sends, edits, deletes, and reacts to global chat messages', () async {
    final repository = InMemoryAppRepository();
    addTearDown(repository.dispose);
    await repository.createAccount(
      username: 'Ricky2026',
      password: 'secret1',
      email: 'ricky@example.com',
    );

    await repository.sendChatMessage('Vamos!');
    var messages = await repository.watchGlobalChatMessages().first;
    final created = messages.first;

    expect(created.username, 'Ricky2026');
    expect(created.text, 'Vamos!');

    await repository.editChatMessage(messageId: created.id, text: 'Vamos!!');
    await repository.reactToChatMessage(messageId: created.id, emoji: '⚽');
    messages = await repository.watchGlobalChatMessages().first;
    final edited = messages.firstWhere((message) => message.id == created.id);

    expect(edited.text, 'Vamos!!');
    expect(edited.isEdited, isTrue);
    expect(edited.reactions['⚽'], 1);

    await repository.deleteChatMessage(created.id);
    messages = await repository.watchGlobalChatMessages().first;
    final deleted = messages.firstWhere((message) => message.id == created.id);

    expect(deleted.isDeleted, isTrue);
    expect(deleted.text, isEmpty);
  });

  test('enforces message length limit', () async {
    final repository = InMemoryAppRepository();
    addTearDown(repository.dispose);
    await repository.createAccount(
      username: 'Ricky2026',
      password: 'secret1',
      email: 'ricky@example.com',
    );

    expect(
      () => repository.sendChatMessage('x' * (ChatMessage.maxTextLength + 1)),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('only exposes submitted brackets publicly', () async {
    final repository = InMemoryAppRepository();
    addTearDown(repository.dispose);
    await repository.createAccount(
      username: 'Ricky2026',
      password: 'secret1',
      email: 'ricky@example.com',
    );

    expect(await repository.watchPublicBracketProfiles().first, isEmpty);

    final bracket = await repository.watchMyBracket().first;
    await repository.submitBracket(
      bracket.copyWith(
        groupPicks: [
          for (final groupId in BracketRules.groupIds)
            GroupPick(
              groupId: groupId,
              firstCountryId: '${groupId}_1',
              secondCountryId: '${groupId}_2',
              thirdCountryId: '${groupId}_3',
            ),
        ],
        bestThirdGroupIds: BracketRules.groupIds.take(8).toList(),
        knockoutPicks: [
          for (final slot in BracketRules.knockoutSlots())
            KnockoutPick(
              slotId: slot.id,
              stage: slot.stage,
              winnerCountryId: 'usa',
            ),
        ],
      ),
    );

    final profiles = await repository.watchPublicBracketProfiles().first;
    expect(profiles, hasLength(1));
    expect(profiles.single.user.username, 'Ricky2026');
    expect(profiles.single.bracket.status, BracketStatus.submitted);
  });

  test(
    'submitted brackets can be edited and resubmitted before lock',
    () async {
      final repository = InMemoryAppRepository();
      addTearDown(repository.dispose);
      await repository.createAccount(
        username: 'Joran2026',
        password: 'secret1',
        email: 'joran@example.com',
      );

      final bracket = _completeBracket(await repository.watchMyBracket().first);
      await repository.submitBracket(bracket);
      final submitted = await repository.watchMyBracket().first;
      final originalSubmittedAt = submitted.submittedAt;

      final changed = submitted.copyWith(
        knockoutPicks: [
          for (final pick in submitted.knockoutPicks)
            if (pick.slotId == 'm73')
              const KnockoutPick(
                slotId: 'm73',
                stage: TournamentStage.roundOf32,
                winnerCountryId: 'mexico',
              )
            else
              pick,
        ],
      );
      await repository.saveBracket(changed);
      final saved = await repository.watchMyBracket().first;

      expect(saved.status, BracketStatus.submitted);
      expect(
        saved.knockoutPicks
            .firstWhere((pick) => pick.slotId == 'm73')
            .winnerCountryId,
        'mexico',
      );

      await Future<void>.delayed(const Duration(milliseconds: 1));
      await repository.submitBracket(saved);
      final resubmitted = await repository.watchMyBracket().first;

      expect(resubmitted.status, BracketStatus.submitted);
      expect(resubmitted.submittedAt!.isAfter(originalSubmittedAt!), isTrue);
    },
  );

  test('admin group results recalculate standings', () async {
    final repository = InMemoryAppRepository();
    addTearDown(repository.dispose);
    await repository.signInWithEmailAndPassword(
      email: 'rgw1985@hotmail.com',
      password: 'secret1',
    );

    await repository.saveFixtureResult(
      Fixture(
        id: 'm1',
        externalId: '1',
        stage: TournamentStage.group,
        roundLabel: 'Group A',
        kickoff: DateTime.utc(2026, 6, 11),
        status: FixtureStatus.finished,
        homeCountryId: 'mexico',
        awayCountryId: 'south_korea',
        homeScore: 2,
        awayScore: 1,
        winnerCountryId: 'mexico',
      ),
    );

    final standings = await repository.watchStandings().first;
    final groupA = standings.firstWhere((standing) => standing.groupId == 'A');

    expect(groupA.rows.first.countryId, 'mexico');
    expect(groupA.rows.first.points, 3);
    expect(groupA.rows.first.played, 1);
  });

  test('admin email sign-in exposes an admin profile', () async {
    final repository = InMemoryAppRepository();
    addTearDown(repository.dispose);

    await repository.signInWithEmailAndPassword(
      email: 'rgw1985@hotmail.com',
      password: 'secret1',
    );

    final user = await repository.watchCurrentUser().first;

    expect(user, isNotNull);
    expect(AdminAccess.isAdmin(user), isTrue);
    expect(user?.username, 'Admin');
  });

  test('signs in with username or email and signs out', () async {
    final repository = InMemoryAppRepository();
    addTearDown(repository.dispose);
    await repository.createAccount(
      username: 'Ricky2026',
      password: 'secret1',
      email: 'ricky@example.com',
    );

    await repository.signOut();
    expect(await repository.watchCurrentUser().first, isNull);

    await repository.signInWithIdentifierAndPassword(
      identifier: 'Ricky2026',
      password: 'secret1',
    );
    expect((await repository.watchCurrentUser().first)?.username, 'Ricky2026');

    await repository.signOut();
    await repository.signInWithIdentifierAndPassword(
      identifier: 'ricky@example.com',
      password: 'secret1',
    );
    expect((await repository.watchCurrentUser().first)?.username, 'Ricky2026');
  });

  test('requires email or phone and a six character password', () async {
    final repository = InMemoryAppRepository();
    addTearDown(repository.dispose);

    expect(
      () => repository.createAccount(
        username: 'Ricky2026',
        password: 'short',
        email: 'ricky@example.com',
      ),
      throwsA(isA<ArgumentError>()),
    );

    expect(
      () =>
          repository.createAccount(username: 'Ricky2026', password: 'secret1'),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('reuses username when old profile was deleted', () async {
    final repository = InMemoryAppRepository();
    addTearDown(repository.dispose);
    await repository.createAccount(
      username: 'Ricky2026',
      password: 'secret1',
      email: 'old@example.com',
    );

    repository.debugDeleteUserProfile('Ricky2026');

    final user = await repository.createAccount(
      username: 'Ricky2026',
      password: 'secret2',
      email: 'new@example.com',
    );

    expect(user.username, 'Ricky2026');
    expect(user.email, 'new@example.com');
  });
}

Bracket _completeBracket(Bracket bracket) {
  return bracket.copyWith(
    groupPicks: [
      for (final groupId in BracketRules.groupIds)
        GroupPick(
          groupId: groupId,
          firstCountryId: '${groupId}_1',
          secondCountryId: '${groupId}_2',
          thirdCountryId: '${groupId}_3',
        ),
    ],
    bestThirdGroupIds: BracketRules.groupIds.take(8).toList(),
    knockoutPicks: [
      for (final slot in BracketRules.knockoutSlots())
        KnockoutPick(
          slotId: slot.id,
          stage: slot.stage,
          winnerCountryId: 'usa',
        ),
    ],
  );
}
