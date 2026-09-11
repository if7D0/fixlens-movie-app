import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_empty.dart';
import '../../../shared/widgets/movie_card.dart';
import '../../../shared/widgets/section_header.dart';
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
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(
                  'Watchlist',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              Expanded(
                child: AppEmpty(
                  title: 'Watchlist kosong',
                  subtitle:
                      'Simpan film dari halaman detail atau hasil quiz, '
                      'semuanya tersimpan otomatis di HP.',
                  icon: Icons.bookmark_outline,
                  actionLabel: 'Cari film',
                  onAction: () => context.go('/search'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Watchlist',
              subtitle: 'Geser kartu ke samping untuk menghapus',
              count: watchlist.items.length,
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        gridDelegate: movieGridDelegate,
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
            ),
          ],
        ),
      ),
    );
  }
}
