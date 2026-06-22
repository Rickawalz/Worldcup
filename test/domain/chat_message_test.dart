import 'package:flutter_test/flutter_test.dart';
import 'package:world_cup_bracket/src/domain/models.dart';

void main() {
  test('aggregates reaction counts and tracks user reactions', () {
    final message = ChatMessage(
      id: 'chat-1',
      userId: 'author',
      username: 'Author',
      text: 'Hello',
      createdAt: _createdAt,
      updatedAt: _createdAt,
      reactionsByUser: {
        'user-a': ['⚽', '🔥'],
        'user-b': ['⚽'],
      },
    );

    expect(message.reactionCounts(), {'⚽': 2, '🔥': 1});
    expect(message.hasUserReacted('user-a', '⚽'), isTrue);
    expect(message.hasUserReacted('user-a', '🏆'), isFalse);
    expect(message.hasUserReacted('user-c', '⚽'), isFalse);
  });

  test('reads reactionsByUser from Firestore map', () {
    final message = ChatMessage.fromMap('chat-1', {
      'userId': 'author',
      'username': 'Author',
      'text': 'Hello',
      'createdAt': _createdAt.toIso8601String(),
      'updatedAt': _createdAt.toIso8601String(),
      'reactionsByUser': {
        'user-a': ['⚽'],
      },
    });

    expect(message.reactionCounts()['⚽'], 1);
    expect(message.hasUserReacted('user-a', '⚽'), isTrue);
  });
}

final _createdAt = DateTime.utc(2026, 6, 11, 19);
