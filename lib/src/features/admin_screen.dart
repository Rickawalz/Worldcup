import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin/admin_access.dart';
import '../data/providers.dart';
import '../localization/app_strings.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countries = ref.watch(countriesProvider);
    final fixtures = ref.watch(fixturesProvider);
    final user = ref.watch(currentUserProvider);
    final strings = context.strings;

    final currentUser = user.valueOrNull;
    if (!AdminAccess.isAdmin(currentUser)) {
      return const _AdminSignInGate();
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          strings.adminConsole,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(strings.adminExplainer),
        const SizedBox(height: 16),
        _AdminActionCard(
          title: strings.apiFootballSync,
          body: strings.apiFootballSyncBody,
          icon: Icons.sync_outlined,
          actionLabel: strings.syncNow,
          onPressed: () {},
        ),
        _AdminActionCard(
          title: strings.teamsAndFlags,
          body: strings.teamsAndFlagsBody,
          icon: Icons.flag_outlined,
          actionLabel: strings.reviewTeams,
          onPressed: () {},
        ),
        _AdminActionCard(
          title: strings.fixturesAndResults,
          body: strings.fixturesAndResultsBody,
          icon: Icons.event_outlined,
          actionLabel: strings.reviewFixtures,
          onPressed: () {},
        ),
        _AdminActionCard(
          title: strings.moderation,
          body: strings.moderationBody,
          icon: Icons.verified_user_outlined,
          actionLabel: strings.reviewReports,
          onPressed: () {},
        ),
        const SizedBox(height: 16),
        countries.when(
          data: (items) => Text(strings.loadedCountries(items.length)),
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => Text('Country load error: $error'),
        ),
        fixtures.when(
          data: (items) => Text(strings.loadedFixtures(items.length)),
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => Text('Fixture load error: $error'),
        ),
      ],
    );
  }
}

class _AdminSignInGate extends ConsumerStatefulWidget {
  const _AdminSignInGate();

  @override
  ConsumerState<_AdminSignInGate> createState() => _AdminSignInGateState();
}

class _AdminSignInGateState extends ConsumerState<_AdminSignInGate> {
  final _emailController = TextEditingController(text: AdminAccess.adminEmail);
  final _passwordController = TextEditingController();
  String? _error;
  bool _isSigningIn = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 48),
                const SizedBox(height: 16),
                Text(
                  strings.adminLogin,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  strings.adminAccessDeniedBody,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: strings.adminEmail,
                    helperText: strings.adminEmailLocked,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: strings.password,
                    errorText: _error,
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _signIn(),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _isSigningIn ? null : _signIn,
                  child:
                      _isSigningIn
                          ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : Text(strings.signIn),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signIn() async {
    final strings = context.strings;
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() => _error = strings.passwordRequired);
      return;
    }
    setState(() {
      _error = null;
      _isSigningIn = true;
    });
    try {
      await ref
          .read(appRepositoryProvider)
          .signInWithEmailAndPassword(
            email: AdminAccess.adminEmail,
            password: password,
          );
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isSigningIn = false);
      }
    }
  }
}

class _AdminActionCard extends StatelessWidget {
  const _AdminActionCard({
    required this.title,
    required this.body,
    required this.icon,
    required this.actionLabel,
    required this.onPressed,
  });

  final String title;
  final String body;
  final IconData icon;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(body),
        trailing: OutlinedButton(
          onPressed: onPressed,
          child: Text(actionLabel),
        ),
      ),
    );
  }
}
