import 'package:flutter_test/flutter_test.dart';
import 'package:world_cup_bracket/src/data/in_memory_app_repository.dart';
import 'package:world_cup_bracket/src/admin/admin_access.dart';

void main() {
  test('triggerApiFootballSync requires admin and updates sync state', () async {
    final repository = InMemoryAppRepository();
    await repository.signInWithEmailAndPassword(
      email: AdminAccess.adminEmail,
      password: 'secret',
    );

    final summary = await repository.triggerApiFootballSync();
    expect(summary.source, 'manual');

    final states = <dynamic>[];
    final subscription = repository.watchApiFootballSyncState().listen(states.add);
    await Future<void>.delayed(Duration.zero);
    await subscription.cancel();

    expect(states.last.lastSyncAt, isNotNull);
    expect(states.last.source, 'manual');
  });

  test('triggerApiFootballSync rejects non-admin users', () async {
    final repository = InMemoryAppRepository();
    await repository.createAccount(
      username: 'player1',
      password: 'secret',
      email: 'player1@example.com',
    );

    expect(
      repository.triggerApiFootballSync(),
      throwsStateError,
    );
  });
}
