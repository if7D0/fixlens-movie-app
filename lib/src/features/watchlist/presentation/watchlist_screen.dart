import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/app_empty.dart';
import '../../../shared/widgets/movie_card.dart';
import 'watchlist_provider.dart';

/// Watchlist tab: persistent grid with swipe-to-remove + undo.
class WatchlistScreen extends ConsumerWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchlist = ref.watch(watchlistProvider);
    final notifier = ref.read(watchlistProvider.notifier);

    if (watchlist.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Watchlist')),
        body: const AppEmpty(
          title: 'Watchlist kosong',
          subtitle: 'Simpan film dari halaman detail atau hasil quiz.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Watchlist (${watchlist.items.length})')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.48,
        ),
        itemCount: watchlist.items.length,
        itemBuilder: (context, i) {
          final movie = watchlist.items[i];
          return Dismissible(
            key: ValueKey(movie.id),
            direction: DismissDirection.horizontal,
            background: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete_outline),
            ),
            onDismissed: (_) async {
              await notifier.remove(movie.id);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${movie.title} dihapus'),
                  action: SnackBarAction(
                    label: 'Urungkan',
                    onPressed: () => notifier.add(movie),
                  ),
                ),
              );
            },
            child: MovieCard(movie: movie),
          );
        },
      ),
    );
  }
}
