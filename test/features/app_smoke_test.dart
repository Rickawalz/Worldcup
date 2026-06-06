import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_cup_bracket/src/app.dart';

void main() {
  testWidgets('renders World Cup bracket home screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: WorldCupBracketApp()));
    await tester.pumpAndSettle();

    expect(find.text('Build your full 2026 World Cup bracket'), findsOneWidget);
    expect(find.text('Create username'), findsOneWidget);
  });

  testWidgets('opens onboarding flow from home', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: WorldCupBracketApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create username'));
    await tester.pumpAndSettle();

    expect(find.text('Create your free bracket profile'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}
