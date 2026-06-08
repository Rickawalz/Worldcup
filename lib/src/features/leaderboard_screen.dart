import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import '../localization/app_strings.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboard = ref.watch(leaderboardProvider);
    final strings = context.strings;
    return leaderboard.when(
      data:
          (entries) => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                strings.globalLeaderboard,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(strings.scoringExplainer),
              const SizedBox(height: 16),
              Card(
                child: DataTable(
                  columns: [
                    DataColumn(label: Text(strings.rank)),
                    DataColumn(label: Text(strings.username)),
                    DataColumn(label: Text(strings.score)),
                    const DataColumn(label: Text('Group')),
                    const DataColumn(label: Text('Knockout')),
                    DataColumn(label: Text(strings.tie)),
                  ],
                  rows: [
                    for (final entry in entries)
                      DataRow(
                        cells: [
                          DataCell(Text('#${entry.rank}')),
                          DataCell(Text(entry.username)),
                          DataCell(Text('${entry.score}')),
                          DataCell(Text('${entry.groupScore}')),
                          DataCell(Text('${entry.knockoutScore}')),
                          DataCell(Text('${entry.tiebreakerDistance}')),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Leaderboard error: $error')),
    );
  }
}
