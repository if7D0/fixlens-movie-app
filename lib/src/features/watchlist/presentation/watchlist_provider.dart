import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive_ce.dart';

import '../../../core/backend/firebase_bootstrap.dart';
import '../../../core/result/app_result.dart';
import '../../../core/utils/app_log.dart';
import '../../account/presentation/account_provider.dart';
import '../../discover/data/models/movie.dart';
import '../data/watchlist_repository.dart';
import '../data/watchlist_sync.dart';

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
        _pushSync(movie, false);
        return false;
      }
      await _repo.save(movie);
      state = WatchlistState(
        items: [movie, ...state.items],
        ids: {...state.ids, movie.id},
      );
      _pushSync(movie, true);
      return true;
    } catch (e) {
      appLog('watchlist toggle failed: $e');
      return state.ids.contains(movie.id);
    }
  }

  /// Best-effort cloud push. Silent unless logged in with backend ready.
  void _pushSync(MovieSummary movie, bool saved) {
    if (!ref.read(firebaseReadyProvider)) return;
    final uid = ref.read(accountProvider).user?.uid;
    if (uid == null) return;
    unawaited(ref.read(watchlistSyncProvider).pushToggle(uid, movie, saved));
  }

  /// Pull-merge-push against the cloud copy. Caller passes uid explicitly
  /// to avoid a provider import cycle (account never imports watchlist).
  Future<AppResult<String>> syncFromCloud(String uid) async {
    if (!ref.read(firebaseReadyProvider)) {
      return const AppErr('Backend tidak tersedia.');
    }
    try {
      final res = await ref
          .read(watchlistSyncProvider)
          .syncOnLogin(uid, state.items, _repo.updatedAtMs());
      switch (res) {
        case AppOk(data: final movies):
          for (final m in movies) {
            await _repo.save(m);
          }
          state = WatchlistState(
            items: movies,
            ids: {for (final m in movies) m.id},
          );
          return const AppOk('Sinkronisasi selesai.');
        case AppErr(message: final m):
          return AppErr(m);
      }
    } catch (e) {
      appLog('watchlist syncFromCloud failed: $e');
      return const AppErr('Sinkronisasi gagal, coba lagi nanti.');
    }
  }

  Future<void> add(MovieSummary movie) async {
    if (state.ids.contains(movie.id)) return;
    await toggle(movie);
  }

  Future<void> remove(int id) async {
    if (!state.ids.contains(id)) return;
    MovieSummary? movie;
    for (final m in state.items) {
      if (m.id == id) {
        movie = m;
        break;
      }
    }
    try {
      await _repo.remove(id);
      state = WatchlistState(
        items: [for (final m in state.items) if (m.id != id) m],
        ids: {...state.ids}..remove(id),
      );
      if (movie != null) _pushSync(movie, false);
    } catch (e) {
      appLog('watchlist remove failed: $e');
    }
  }
}

final watchlistProvider =
    NotifierProvider<WatchlistNotifier, WatchlistState>(
      WatchlistNotifier.new,
    );
