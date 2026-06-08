import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/providers.dart';
import '../domain/models.dart';
import '../localization/app_strings.dart';
import '../widgets/dashboard.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final bracket = ref.watch(myBracketProvider);
    final strings = context.strings;

    return user.when(
      data: (value) {
        if (value == null) {
          return Center(
            child: FilledButton(
              onPressed: () => context.go('/onboarding'),
              child: Text(strings.createFreeProfile),
            ),
          );
        }
        return DashboardPage(
          title: strings.publicProfile,
          subtitle:
              'Manage your account, bracket status, notifications, and profile reports.',
          icon: Icons.person_outline,
          stats: [
            DashboardStat(
              label: 'profile',
              value: value.username,
              icon: Icons.verified_user_outlined,
            ),
            if (bracket.valueOrNull != null)
              DashboardStat(
                label: bracket.valueOrNull!.status.name,
                value: 'Bracket',
                icon: Icons.account_tree_outlined,
                color: DashboardColors.sky,
              ),
          ],
          children: [
            Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(value.username),
                subtitle: Text(
                  value.linkedProviders.isEmpty
                      ? strings.noRecoveryLinked
                      : strings.linked(
                        value.linkedProviders.map((p) => p.name).join(', '),
                      ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const _AccountCard(),
            const SizedBox(height: 16),
            _NotificationCard(),
            const SizedBox(height: 16),
            bracket.when(
              data:
                  (myBracket) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.account_tree_outlined),
                      title: Text(strings.bracketStatus(myBracket.status.name)),
                      subtitle: Text(
                        strings.championPick(
                          myBracket.championCountryId ?? 'TBD',
                        ),
                      ),
                      trailing: TextButton(
                        onPressed: () => context.go('/bracket'),
                        child: Text(strings.view),
                      ),
                    ),
                  ),
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => Text('Bracket error: $error'),
            ),
            const SizedBox(height: 16),
            _ReportCard(targetId: value.id),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Profile error: $error')),
    );
  }
}

class _AccountCard extends ConsumerStatefulWidget {
  const _AccountCard();

  @override
  ConsumerState<_AccountCard> createState() => _AccountCardState();
}

class _AccountCardState extends ConsumerState<_AccountCard> {
  bool _isSigningOut = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.strings.accountRecovery,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(context.strings.accountRecoveryBody),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _isSigningOut ? null : _signOut,
                icon:
                    _isSigningOut
                        ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.logout),
                label: Text(context.strings.signOut),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    setState(() => _isSigningOut = true);
    try {
      await ref.read(appRepositoryProvider).signOut();
      ref.invalidate(currentUserProvider);
      ref.invalidate(myBracketProvider);
      ref.invalidate(globalChatMessagesProvider);
      if (mounted) {
        context.go('/');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not sign out: $error')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSigningOut = false);
      }
    }
  }
}

class _NotificationCard extends ConsumerStatefulWidget {
  @override
  ConsumerState<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends ConsumerState<_NotificationCard> {
  bool _enabled = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SwitchListTile(
        title: Text(context.strings.lockNotifications),
        subtitle: Text(context.strings.notificationBody),
        value: _enabled,
        onChanged: (value) async {
          setState(() => _enabled = value);
          await ref.read(appRepositoryProvider).setNotificationsEnabled(value);
        },
      ),
    );
  }
}

class _ReportCard extends ConsumerStatefulWidget {
  const _ReportCard({required this.targetId});

  final String targetId;

  @override
  ConsumerState<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends ConsumerState<_ReportCard> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.strings.reportProfile,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: context.strings.reason,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                await ref
                    .read(appRepositoryProvider)
                    .report(
                      targetType: ReportTargetType.user,
                      targetId: widget.targetId,
                      reason: _controller.text,
                    );
                _controller.clear();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.strings.reportSubmitted)),
                  );
                }
              },
              icon: const Icon(Icons.flag_outlined),
              label: Text(context.strings.submitReport),
            ),
          ],
        ),
      ),
    );
  }
}
