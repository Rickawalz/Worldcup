import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'data/providers.dart';
import 'features/admin_screen.dart';
import 'features/bracket_screen.dart';
import 'features/chat_screen.dart';
import 'features/home_screen.dart';
import 'features/leaderboard_screen.dart';
import 'features/onboarding_screen.dart';
import 'features/players_screen.dart';
import 'features/profile_screen.dart';
import 'features/schedule_screen.dart';
import 'features/standings_screen.dart';
import 'localization/app_strings.dart';
import 'widgets/dashboard.dart';

class WorldCupBracketApp extends ConsumerWidget {
  const WorldCupBracketApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ValueListenableBuilder<Locale>(
      valueListenable: appLocaleNotifier,
      builder: (context, locale, _) {
        return MaterialApp.router(
          title: "Ricky's World Cup Bracket 2026",
          locale: locale,
          supportedLocales: const [Locale('en'), Locale('es')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: buildDashboardTheme(),
          darkTheme: buildDashboardTheme(),
          themeMode: ThemeMode.dark,
          builder:
              (context, child) => AppLocaleScope(
                locale: locale,
                child: child ?? const SizedBox.shrink(),
              ),
          routerConfig: _router,
        );
      },
    );
  }
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppScaffold(child: child),
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/bracket',
          builder:
              (context, state) =>
                  const _RequireSignedIn(child: BracketScreen()),
        ),
        GoRoute(
          path: '/standings',
          builder:
              (context, state) =>
                  const _RequireSignedIn(child: StandingsScreen()),
        ),
        GoRoute(
          path: '/schedule',
          builder:
              (context, state) =>
                  const _RequireSignedIn(child: ScheduleScreen()),
        ),
        GoRoute(
          path: '/leaderboard',
          builder:
              (context, state) =>
                  const _RequireSignedIn(child: LeaderboardScreen()),
        ),
        GoRoute(
          path: '/players',
          builder:
              (context, state) =>
                  const _RequireSignedIn(child: PlayersScreen()),
          routes: [
            GoRoute(
              path: ':userId',
              builder:
                  (context, state) => _RequireSignedIn(
                    child: PublicBracketScreen(
                      userId: state.pathParameters['userId'] ?? '',
                    ),
                  ),
            ),
          ],
        ),
        GoRoute(
          path: '/chat',
          builder:
              (context, state) => const _RequireSignedIn(child: ChatScreen()),
        ),
        GoRoute(
          path: '/profile',
          builder:
              (context, state) =>
                  const _RequireSignedIn(child: ProfileScreen()),
        ),
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminScreen(),
        ),
      ],
    ),
  ],
);

class AppScaffold extends ConsumerWidget {
  const AppScaffold({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ValueListenableBuilder<Locale>(
      valueListenable: appLocaleNotifier,
      builder: (context, locale, _) {
        final strings = AppStrings(locale);
        final location = GoRouterState.of(context).uri.path;
        final user = ref.watch(currentUserProvider);
        final currentUser = user.isLoading ? null : user.valueOrNull;
        final destinations =
            currentUser == null ? const [_homeDestination] : _destinations;
        final selectedIndex = destinations.indexWhere((destination) {
          if (destination.path == '/') {
            return location == destination.path;
          }
          return location == destination.path ||
              location.startsWith('${destination.path}/');
        });

        return Scaffold(
          appBar: AppBar(
            title: GestureDetector(
              onLongPress: () => context.go('/admin'),
              child: Text(strings.appName, overflow: TextOverflow.ellipsis),
            ),
            actions: [
              Tooltip(
                message: strings.languageButton,
                child: TextButton(
                  key: const ValueKey('language-toggle'),
                  onPressed: toggleAppLocale,
                  child: Text(strings.languageButton),
                ),
              ),
            ],
          ),
          body: DashboardBackground(
            child: Row(
              children: [
                if (MediaQuery.sizeOf(context).width >= 900 &&
                    destinations.length >= 2)
                  NavigationRail(
                    selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
                    onDestinationSelected: (index) {
                      context.go(destinations[index].path);
                    },
                    labelType: NavigationRailLabelType.all,
                    destinations: [
                      for (final destination in destinations)
                        NavigationRailDestination(
                          icon: Icon(destination.icon),
                          label: Text(destination.label(strings)),
                        ),
                    ],
                  ),
                Expanded(
                  child: KeyedSubtree(
                    key: ValueKey(locale.languageCode),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar:
              MediaQuery.sizeOf(context).width < 900 && destinations.length >= 2
                  ? NavigationBar(
                    selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
                    onDestinationSelected: (index) {
                      context.go(destinations[index].path);
                    },
                    destinations: [
                      for (final destination in destinations)
                        NavigationDestination(
                          icon: Icon(destination.icon),
                          label: destination.label(strings),
                        ),
                    ],
                  )
                  : null,
        );
      },
    );
  }
}

const _destinations = [
  _homeDestination,
  _Destination('/bracket', _bracketLabel, Icons.account_tree_outlined),
  _Destination('/standings', _standingsLabel, Icons.table_rows_outlined),
  _Destination('/schedule', _scheduleLabel, Icons.calendar_month_outlined),
  _Destination('/players', _playersLabel, Icons.groups_outlined),
  _Destination('/chat', _chatLabel, Icons.chat_bubble_outline),
  _Destination('/profile', _profileLabel, Icons.person_outline),
];

const _homeDestination = _Destination('/', _homeLabel, Icons.home_outlined);

class _Destination {
  const _Destination(this.path, this.label, this.icon);

  final String path;
  final String Function(AppStrings strings) label;
  final IconData icon;
}

String _homeLabel(AppStrings strings) => strings.home;
String _bracketLabel(AppStrings strings) => strings.bracket;
String _standingsLabel(AppStrings strings) => strings.standings;
String _scheduleLabel(AppStrings strings) => strings.schedule;
String _playersLabel(AppStrings strings) => strings.players;
String _chatLabel(AppStrings strings) => strings.chat;
String _profileLabel(AppStrings strings) => strings.profile;

class _RequireSignedIn extends ConsumerWidget {
  const _RequireSignedIn({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return user.when(
      data: (value) {
        if (value != null) {
          return child;
        }
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      context.strings.signInRequired,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Text(context.strings.signInRequiredBody),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => context.go('/onboarding'),
                      child: Text(context.strings.signIn),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Profile error: $error')),
    );
  }
}
