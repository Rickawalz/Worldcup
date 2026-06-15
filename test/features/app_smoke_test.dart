import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_cup_bracket/src/app.dart';

void main() {
  testWidgets('renders World Cup bracket home screen', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: WorldCupBracketApp()));
    await tester.pumpAndSettle();

    expect(find.text('Build your full 2026 World Cup bracket'), findsOneWidget);
    expect(find.text('You are signed out'), findsOneWidget);
    expect(find.text('Build your bracket'), findsOneWidget);
    expect(find.text("Amy's Calendar"), findsWidgets);
    expect(find.text('Sign in or create account'), findsOneWidget);
  });

  testWidgets('opens onboarding flow from home', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: WorldCupBracketApp()));
    await tester.pumpAndSettle();

    final signInButton = find.text('Sign in or create account');
    await tester.tap(signInButton);
    await tester.pumpAndSettle();

    expect(find.text('Bracket account access'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
    expect(find.byType(TextField), findsWidgets);
  });
}
