import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive_ce.dart';

import '../../../core/utils/app_log.dart';
import '../../discover/data/models/movie.dart';
import '../data/watchlist_repository.dart';

/// Overridden in main() with the opened box (and in tests with a temp box).
final watchlistBoxProvider = Provider<Box>(
  (_) => throw UnimplementedError('Override watchlistBoxProvider'),
);

class WatchlistState {
  final List<MovieSummary> items;
  final Set<int> ids;

  const WatchlistState({this.items = const [], this.ids = const {}});
}

class WatchlistNotifier extends Notifier<WatchlistState> {
  WatchlistRepository get _repo =>
      WatchlistRepository(ref.read(watchlistBoxProvider));

  @override
  WatchlistState build() {
    try {
      final items = _repo.items();
      return WatchlistState(
        items: items,
        ids: {for (final m in items) m.id},
      );
    } catch (e) {
      appLog('watchlist load failed: $e');
      return const WatchlistState();
    }
  }

  /// Returns true when the movie ended up saved, false when removed/failed.
  Future<bool> toggle(MovieSummary movie) async {
    try {
      if (state.ids.contains(movie.id)) {
        await _repo.remove(movie.id);
        state = WatchlistState(
          items: [for (final m in state.items) if (m.id != movie.id) m],
          ids: {...state.ids}..remove(movie.id),
        );
        return false;
      }
      await _repo.save(movie);
      state = WatchlistState(
        items: [movie, ...state.items],
        ids: {...state.ids, movie.id},
      );
      return true;
    } catch (e) {
      appLog('watchlist toggle failed: $e');
      return state.ids.contains(movie.id);
    }
  }

  Future<void> add(MovieSummary movie) async {
    if (state.ids.contains(movie.id)) return;
    await toggle(movie);
  }

  Future<void> remove(int id) async {
    if (!state.ids.contains(id)) return;
    try {
      await _repo.remove(id);
      state = WatchlistState(
        items: [for (final m in state.items) if (m.id != id) m],
        ids: {...state.ids}..remove(id),
      );
    } catch (e) {
      appLog('watchlist remove failed: $e');
    }
  }
}

final watchlistProvider =
    NotifierProvider<WatchlistNotifier, WatchlistState>(
      WatchlistNotifier.new,
    );
