import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../data/providers.dart';
import '../localization/app_strings.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final config = ref.watch(contestConfigProvider);
    final bracket = ref.watch(myBracketProvider);
    final strings = context.strings;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          strings.buildFullBracket,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(strings.homeIntro),
        const SizedBox(height: 24),
        user.when(
          data: (value) {
            if (value == null) {
              return _ActionCard(
                title: strings.startFree,
                body: strings.createUsernameBeforeBracket,
                actionLabel: strings.createUsername,
                onPressed: () => context.go('/onboarding'),
              );
            }
            return _ActionCard(
              title: strings.welcome(value.username),
              body: strings.profilePublicFree,
              actionLabel: strings.viewProfile,
              onPressed: () => context.go('/profile'),
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => Text(strings.couldNotLoad('profile', error)),
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
              ),
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => Text(strings.couldNotLoad('bracket', error)),
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
  });

  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onPressed;

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(body),
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
