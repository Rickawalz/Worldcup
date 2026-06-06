import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/admin_screen.dart';
import 'features/bracket_screen.dart';
import 'features/chat_screen.dart';
import 'features/home_screen.dart';
import 'features/leaderboard_screen.dart';
import 'features/onboarding_screen.dart';
import 'features/profile_screen.dart';
import 'features/standings_screen.dart';
import 'localization/app_strings.dart';

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
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0B5D3B),
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0B5D3B),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
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
          builder: (context, state) => const BracketScreen(),
        ),
        GoRoute(
          path: '/standings',
          builder: (context, state) => const StandingsScreen(),
        ),
        GoRoute(
          path: '/leaderboard',
          builder: (context, state) => const LeaderboardScreen(),
        ),
        GoRoute(path: '/chat', builder: (context, state) => const ChatScreen()),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
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
        final selectedIndex = _destinations.indexWhere(
          (destination) => destination.path == location,
        );

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
                  child: Text(strings.isSpanish ? 'EN' : 'ES'),
                ),
              ),
            ],
          ),
          body: Row(
            children: [
              if (MediaQuery.sizeOf(context).width >= 900)
                NavigationRail(
                  selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
                  onDestinationSelected: (index) {
                    context.go(_destinations[index].path);
                  },
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final destination in _destinations)
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
          bottomNavigationBar:
              MediaQuery.sizeOf(context).width < 900
                  ? NavigationBar(
                    selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
                    onDestinationSelected: (index) {
                      context.go(_destinations[index].path);
                    },
                    destinations: [
                      for (final destination in _destinations)
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
  _Destination('/', _homeLabel, Icons.home_outlined),
  _Destination('/bracket', _bracketLabel, Icons.account_tree_outlined),
  _Destination('/standings', _standingsLabel, Icons.table_rows_outlined),
  _Destination('/leaderboard', _leadersLabel, Icons.emoji_events_outlined),
  _Destination('/chat', _chatLabel, Icons.chat_bubble_outline),
  _Destination('/profile', _profileLabel, Icons.person_outline),
];

class _Destination {
  const _Destination(this.path, this.label, this.icon);

  final String path;
  final String Function(AppStrings strings) label;
  final IconData icon;
}

String _homeLabel(AppStrings strings) => strings.home;
String _bracketLabel(AppStrings strings) => strings.bracket;
String _standingsLabel(AppStrings strings) => strings.standings;
String _leadersLabel(AppStrings strings) => strings.leaders;
String _chatLabel(AppStrings strings) => strings.chat;
String _profileLabel(AppStrings strings) => strings.profile;
