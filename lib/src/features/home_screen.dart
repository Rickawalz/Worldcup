import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../data/providers.dart';
import '../domain/models.dart';
import '../localization/app_strings.dart';
import '../widgets/dashboard.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final config = ref.watch(contestConfigProvider);
    final fixtures = ref.watch(fixturesProvider);
    final currentUser = user.isLoading ? null : user.valueOrNull;
    final firstKickoff = _firstKickoff(fixtures.valueOrNull ?? const []);

    if (user.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (currentUser == null) {
      return _WelcomeLanding(
        firstKickoff: firstKickoff,
        onSignIn: () => context.go('/onboarding'),
      );
    }

    return _SignedInHome(
      username: currentUser.username,
      config: config,
      firstKickoff: firstKickoff,
    );
  }
}

class _WelcomeLanding extends StatelessWidget {
  const _WelcomeLanding({required this.firstKickoff, required this.onSignIn});

  final DateTime? firstKickoff;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        DashboardHeader(
          title: strings.buildFullBracket,
          subtitle:
              'Make your picks, follow every game, and compete with friends through the 2026 World Cup.',
          icon: Icons.emoji_events_outlined,
          stats: [
            DashboardStat(
              label: 'first match',
              value: _countdownLabel(firstKickoff),
              icon: Icons.stadium_outlined,
            ),
            const DashboardStat(
              label: 'logged out',
              value: 'You are',
              icon: Icons.logout_outlined,
              color: DashboardColors.sky,
            ),
          ],
        ),
        const SizedBox(height: 18),
        DashboardSectionCard(
          child: Wrap(
            spacing: 18,
            runSpacing: 18,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 560,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Chip(
                      avatar: const Icon(Icons.info_outline, size: 18),
                      label: Text(strings.signedOutTitle),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'You are viewing the welcome page. Sign in to save picks, edit your bracket, and join the contest.',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      strings.signedOutBody,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: onSignIn,
                icon: const Icon(Icons.login),
                label: Text(strings.signInOrCreateAccount),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _PreviewGrid(
          items: const [
            _PreviewItem(
              icon: Icons.account_tree_outlined,
              title: 'Build your bracket',
              body:
                  'Pick group advancers, knockout winners, and your champion.',
            ),
            _PreviewItem(
              icon: Icons.calendar_month_outlined,
              title: 'Track the schedule',
              body:
                  'Browse matchdays, kickoff times, teams, flags, and venues.',
            ),
            _PreviewItem(
              icon: Icons.table_rows_outlined,
              title: 'Follow standings',
              body:
                  'See group tables and game results as the tournament moves.',
            ),
            _PreviewItem(
              icon: Icons.groups_outlined,
              title: 'Compare players',
              body: 'Check other submitted brackets and leaderboard scores.',
            ),
            _PreviewItem(
              icon: Icons.chat_bubble_outline,
              title: 'Join the chat',
              body: 'Talk through the tournament with everyone in the contest.',
            ),
          ],
        ),
      ],
    );
  }
}

class _SignedInHome extends ConsumerWidget {
  const _SignedInHome({
    required this.username,
    required this.config,
    required this.firstKickoff,
  });

  final String username;
  final AsyncValue<GlobalContestConfig> config;
  final DateTime? firstKickoff;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = context.strings;
    final bracket = ref.watch(myBracketProvider);
    return DashboardPage(
      title: strings.welcome(username),
      subtitle:
          'Your World Cup command center: finish picks, watch the schedule, and keep an eye on the contest.',
      icon: Icons.dashboard_outlined,
      stats: [
        DashboardStat(
          label: 'first match',
          value: _countdownLabel(firstKickoff),
          icon: Icons.stadium_outlined,
        ),
        if (config.valueOrNull != null)
          DashboardStat(
            label: config.valueOrNull!.isLocked ? 'locked' : 'picks lock',
            value:
                config.valueOrNull!.isLocked
                    ? 'Closed'
                    : DateFormat.MMMd().format(
                      config.valueOrNull!.lockAt.toLocal(),
                    ),
            icon: Icons.lock_clock_outlined,
            color: DashboardColors.sky,
          ),
      ],
      children: [
        _ActionCard(
          title: strings.openBracket,
          body: 'Jump back into your bracket and keep your picks ready.',
          actionLabel: strings.continuePicks,
          onPressed: () => context.go('/bracket'),
          icon: Icons.account_tree_outlined,
        ),
        const SizedBox(height: 16),
        config.when(
          data:
              (value) => _ActionCard(
                title:
                    value.isLocked
                        ? strings.bracketLocked
                        : strings.bracketLockDeadline,
                body: strings.picksLockAt(
                  DateFormat.yMMMd(
                    Localizations.localeOf(context).toLanguageTag(),
                  ).add_jm().format(value.lockAt.toLocal()),
                ),
                actionLabel: strings.openBracket,
                onPressed: () => context.go('/bracket'),
                icon: Icons.lock_clock_outlined,
              ),
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => Text(strings.couldNotLoad('contest', error)),
        ),
        const SizedBox(height: 16),
        bracket.when(
          data:
              (value) => _ActionCard(
                title: strings.bracketStatus(value.status.name),
                body: strings.savedPicks(
                  value.groupPicks.length,
                  value.knockoutPicks.length,
                ),
                actionLabel: strings.continuePicks,
                onPressed: () => context.go('/bracket'),
                icon: Icons.fact_check_outlined,
              ),
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => Text(strings.couldNotLoad('bracket', error)),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _MiniShortcut(
              icon: Icons.calendar_month_outlined,
              title: strings.schedule,
              body: 'Find upcoming games.',
              onPressed: () => context.go('/schedule'),
            ),
            _MiniShortcut(
              icon: Icons.table_rows_outlined,
              title: strings.standings,
              body: 'Follow group tables.',
              onPressed: () => context.go('/standings'),
            ),
            _MiniShortcut(
              icon: Icons.groups_outlined,
              title: strings.players,
              body: 'Compare brackets.',
              onPressed: () => context.go('/players'),
            ),
            _MiniShortcut(
              icon: Icons.person_outline,
              title: strings.profile,
              body: 'Manage your account.',
              onPressed: () => context.go('/profile'),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onPressed,
    required this.icon,
  });

  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 520,
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: DashboardColors.gold.withValues(
                      alpha: 0.18,
                    ),
                    foregroundColor: DashboardColors.gold,
                    child: Icon(icon),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(body),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            FilledButton(onPressed: onPressed, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

class _MiniShortcut extends StatelessWidget {
  const _MiniShortcut({
    required this.icon,
    required this.title,
    required this.body,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: DashboardSectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: DashboardColors.gold),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(body),
            const SizedBox(height: 12),
            TextButton(onPressed: onPressed, child: Text(context.strings.view)),
          ],
        ),
      ),
    );
  }
}

class _PreviewGrid extends StatelessWidget {
  const _PreviewGrid({required this.items});

  final List<_PreviewItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth >= 900 ? 280.0 : double.infinity;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final item in items)
              SizedBox(
                width: cardWidth,
                child: DashboardSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(item.icon, color: DashboardColors.gold),
                      const SizedBox(height: 12),
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(item.body),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PreviewItem {
  const _PreviewItem({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

DateTime? _firstKickoff(List<Fixture> fixtures) {
  final kickoffDates =
      fixtures
          .map((fixture) => fixture.kickoff)
          .where((kickoff) => kickoff.isAfter(DateTime.now()))
          .toList()
        ..sort();
  return kickoffDates.isEmpty ? null : kickoffDates.first;
}

String _countdownLabel(DateTime? kickoff) {
  if (kickoff == null) return 'Soon';
  final difference = kickoff.difference(DateTime.now());
  if (difference.isNegative) return 'Live';
  if (difference.inDays >= 1) return '${difference.inDays}d';
  if (difference.inHours >= 1) return '${difference.inHours}h';
  return '${difference.inMinutes.clamp(1, 59)}m';
}
