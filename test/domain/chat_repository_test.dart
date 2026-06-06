import 'package:flutter_test/flutter_test.dart';
import 'package:world_cup_bracket/src/data/in_memory_app_repository.dart';
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
    await repository.createUsernameProfile('Ricky2026');

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
    await repository.createUsernameProfile('Ricky2026');

    expect(
      () => repository.sendChatMessage('x' * (ChatMessage.maxTextLength + 1)),
      throwsA(isA<ArgumentError>()),
    );
  });
}
