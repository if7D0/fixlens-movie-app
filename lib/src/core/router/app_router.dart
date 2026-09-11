import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/detail/presentation/detail_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/mood/presentation/mood_quiz_screen.dart';
import '../../features/mood/presentation/mood_result_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/watchlist/presentation/watchlist_provider.dart';
import '../../features/watchlist/presentation/watchlist_screen.dart';

/// App router (locked Phase 1). Bottom nav uses indexed-stack shell so tab
/// state is preserved. Detail lives outside the shell.
/// Watchlist tab icon with a count badge (hidden when empty).
class _WatchlistIcon extends StatelessWidget {
  final int count;
  final bool selected;

  const _WatchlistIcon({required this.count, required this.selected});

  @override
  Widget build(BuildContext context) {
    final icon = Icon(selected ? Icons.bookmark : Icons.bookmark_outline);
    if (count == 0) return icon;
    return Badge(label: Text('$count'), child: icon);
  }
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return Scaffold(
          body: navigationShell,
          // Consumer wraps ONLY the nav bar so badge updates don't rebuild tabs.
          bottomNavigationBar: Consumer(
            builder: (context, ref, _) {
              final savedCount = ref.watch(
                watchlistProvider.select((s) => s.ids.length),
              );
              return NavigationBar(
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: navigationShell.goBranch,
                destinations: [
                  const NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.search_outlined),
                    selectedIcon: Icon(Icons.search),
                    label: 'Search',
                  ),
                  NavigationDestination(
                    icon: _WatchlistIcon(
                      count: savedCount,
                      selected: false,
                    ),
                    selectedIcon: _WatchlistIcon(
                      count: savedCount,
                      selected: true,
                    ),
                    label: 'Watchlist',
                  ),
                ],
              );
            },
          ),
        );
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/search',
              builder: (context, state) => const SearchScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/watchlist',
              builder: (context, state) => const WatchlistScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/mood',
      builder: (context, state) => const MoodQuizScreen(),
    ),
    GoRoute(
      path: '/mood/result',
      builder: (context, state) => const MoodResultScreen(),
    ),
    GoRoute(
      path: '/movie/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return DetailScreen(movieId: id);
      },
    ),
  ],
);
