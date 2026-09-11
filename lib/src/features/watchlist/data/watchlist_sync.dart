import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/result/app_result.dart';
import '../../../core/utils/app_log.dart';
import '../../discover/data/models/movie.dart';

/// One watchlist entry with a millisecond timestamp for last-write-wins.
class SyncedEntry {
  final Map<String, dynamic> movieJson;
  final int updatedAtMs;

  const SyncedEntry({required this.movieJson, required this.updatedAtMs});
}

/// Pure union merge: every id survives, newer `updatedAtMs` wins per id.
/// v1 limitation: deletions don't propagate (no tombstones). Deleting while
/// offline then logging in can resurrect the entry — documented in README.
Map<int, SyncedEntry> mergeWatchlists({
  required Map<int, SyncedEntry> local,
  required Map<int, SyncedEntry> remote,
}) {
  final merged = Map<int, SyncedEntry>.of(local);
  for (final entry in remote.entries) {
    final existing = merged[entry.key];
    if (existing == null || entry.value.updatedAtMs > existing.updatedAtMs) {
      merged[entry.key] = entry.value;
    }
  }
  return merged;
}

/// Sync contract (abstract for test fakes; production = Firestore below).
abstract class WatchlistSync {
  Future<AppResult<List<MovieSummary>>> syncOnLogin(
    String uid,
    List<MovieSummary> localItems,
    Map<int, int> localUpdatedAtMs,
  );

  Future<void> pushToggle(String uid, MovieSummary movie, bool saved);
}

/// Hive <-> Firestore sync. All failures are logged, never thrown.
class FirestoreWatchlistSync implements WatchlistSync {
  FirestoreWatchlistSync(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('watchlist');

  /// Pull remote, union-merge with [localItems], write winners back to
  /// both sides. Returns merged list (newest first).
  @override
  Future<AppResult<List<MovieSummary>>> syncOnLogin(
    String uid,
    List<MovieSummary> localItems,
    Map<int, int> localUpdatedAtMs,
  ) async {
    try {
      final snap = await _col(uid).get();
      final remote = <int, SyncedEntry>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        final id = int.tryParse(doc.id);
        if (id == null) continue;
        remote[id] = SyncedEntry(
          movieJson: Map<String, dynamic>.from(data)..remove('updatedAt'),
          updatedAtMs: (data['updatedAt'] as num?)?.toInt() ?? 0,
        );
      }
      final local = <int, SyncedEntry>{
        for (final m in localItems)
          m.id: SyncedEntry(
            movieJson: m.toJson(),
            updatedAtMs: localUpdatedAtMs[m.id] ?? 0,
          ),
      };
      final merged = mergeWatchlists(local: local, remote: remote);
      final batch = _db.batch();
      final now = DateTime.now().millisecondsSinceEpoch;
      for (final entry in merged.entries) {
        batch.set(_col(uid).doc('${entry.key}'), {
          ...entry.value.movieJson,
          'updatedAt': entry.value.updatedAtMs == 0
              ? now
              : entry.value.updatedAtMs,
        }, SetOptions(merge: true));
      }
      await batch.commit();
      final movies = merged.values
          .map((e) => MovieSummary.fromJson(e.movieJson))
          .toList();
      return AppOk(movies);
    } catch (e) {
      appLog('watchlist sync failed: $e');
      return const AppErr('Sinkronisasi gagal, coba lagi nanti.');
    }
  }

  /// Push a single toggle. Fire-and-forget from UI (errors logged only).
  @override
  Future<void> pushToggle(
    String uid,
    MovieSummary movie,
    bool saved,
  ) async {
    try {
      final doc = _col(uid).doc('${movie.id}');
      if (saved) {
        await doc.set({
          ...movie.toJson(),
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });
      } else {
        await doc.delete();
      }
    } catch (e) {
      appLog('watchlist push failed: $e');
    }
  }
}

final firestoreProvider = Provider<FirebaseFirestore>(
  (_) => throw UnimplementedError('Override firestoreProvider'),
);

final watchlistSyncProvider = Provider<WatchlistSync>(
  (ref) => FirestoreWatchlistSync(ref.watch(firestoreProvider)),
);
