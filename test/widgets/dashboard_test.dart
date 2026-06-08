import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_cup_bracket/src/widgets/dashboard.dart';

void main() {
  testWidgets('dashboard header renders title subtitle and stat chips', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildDashboardTheme(),
        home: const Scaffold(
          body: DashboardBackground(
            child: DashboardHeader(
              title: 'Standings',
              subtitle: 'Group tables update from admin-entered results.',
              icon: Icons.table_rows_outlined,
              stats: [
                DashboardStat(
                  label: 'groups',
                  value: '12',
                  icon: Icons.grid_view_outlined,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Standings'), findsOneWidget);
    expect(
      find.text('Group tables update from admin-entered results.'),
      findsOneWidget,
    );
    expect(find.text('12'), findsOneWidget);
    expect(find.text('groups'), findsOneWidget);
  });
}
