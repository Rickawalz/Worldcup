import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_cup_bracket/src/admin/admin_access.dart';
import 'package:world_cup_bracket/src/data/in_memory_app_repository.dart';
import 'package:world_cup_bracket/src/data/providers.dart';
import 'package:world_cup_bracket/src/domain/models.dart';
import 'package:world_cup_bracket/src/features/admin_screen.dart';

void main() {
  testWidgets('admin settings shows score sync section', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = InMemoryAppRepository();
    await repository.signInWithEmailAndPassword(
      email: AdminAccess.adminEmail,
      password: 'secret',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(
          home: Scaffold(body: AdminScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Score sync'), findsOneWidget);
    expect(find.text('Sync now'), findsOneWidget);
    expect(find.text('No API sync has run yet.'), findsOneWidget);
  });

  testWidgets('accepting submissions toggle saves immediately', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = InMemoryAppRepository();
    await repository.signInWithEmailAndPassword(
      email: AdminAccess.adminEmail,
      password: 'secret',
    );
    final futureLock = DateTime.now().add(const Duration(days: 30));
    await repository.updateContestConfig(
      GlobalContestConfig(
        lockAt: futureLock,
        isAcceptingSubmissions: true,
      ),
      note: 'test setup',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(
          home: Scaffold(body: AdminScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Settings'));
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Accepting submissions'));
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    final config = await repository.watchGlobalContestConfig().first;
    expect(config.isAcceptingSubmissions, isFalse);
  });
}
