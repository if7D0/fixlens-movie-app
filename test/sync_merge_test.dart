import 'package:fixlens_movie_app/src/features/watchlist/data/watchlist_sync.dart';
import 'package:flutter_test/flutter_test.dart';

SyncedEntry entry(int updatedAtMs) => SyncedEntry(
  movieJson: {'id': 1, 'title': 'X'},
  updatedAtMs: updatedAtMs,
);

void main() {
  test('newer side wins per id', () {
    final merged = mergeWatchlists(
      local: {1: entry(100)},
      remote: {1: entry(200)},
    );
    expect(merged[1]!.updatedAtMs, 200);

    final merged2 = mergeWatchlists(
      local: {1: entry(300)},
      remote: {1: entry(200)},
    );
    expect(merged2[1]!.updatedAtMs, 300);
  });

  test('disjoint ids union', () {
    final merged = mergeWatchlists(
      local: {1: entry(100)},
      remote: {2: entry(50)},
    );
    expect(merged.keys, {1, 2});
  });

  test('empty sides yield the other side', () {
    expect(mergeWatchlists(local: {}, remote: {1: entry(5)}).keys, {1});
    expect(mergeWatchlists(local: {1: entry(5)}, remote: {}).keys, {1});
    expect(mergeWatchlists(local: {}, remote: {}), isEmpty);
  });
}
