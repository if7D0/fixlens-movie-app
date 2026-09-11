import 'dart:io';

import 'package:fixlens_movie_app/src/features/discover/data/models/movie.dart';
import 'package:fixlens_movie_app/src/features/watchlist/data/watchlist_repository.dart';
import 'package:fixlens_movie_app/src/features/watchlist/presentation/watchlist_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

const _movie = MovieSummary(
  id: 550,
  title: 'Fight Club',
  posterPath: '/p.jpg',
  backdropPath: null,
  overview: '',
  releaseDate: '1999-10-15',
  voteAverage: 8.4,
  genreIds: [18],
);

void main() {
  late Directory temp;
  late Box box;

  setUpAll(() async {
    temp = await Directory.systemTemp.createTemp('fixlens_watchlist_');
    Hive.init(temp.path);
  });

  setUp(() async {
    box = await Hive.openBox('wl_${DateTime.now().microsecondsSinceEpoch}');
  });

  tearDown(() => box.deleteFromDisk());

  tearDownAll(() => temp.delete(recursive: true));

  test('repository round-trip save/contains/remove', () async {
    final repo = WatchlistRepository(box);

    expect(repo.contains(550), isFalse);
    await repo.save(_movie);
    expect(repo.contains(550), isTrue);
    expect(repo.items().single.id, 550);
    await repo.remove(550);
    expect(repo.contains(550), isFalse);
    expect(repo.items(), isEmpty);
  });

  test('repository skips corrupt entries', () async {
    final repo = WatchlistRepository(box);
    await box.put('m_1', 'bukan-map');
    await repo.save(_movie);

    expect(repo.items().map((m) => m.id), [550]);
  });

  test('notifier toggles both ways', () async {
    final container = ProviderContainer(
      overrides: [watchlistBoxProvider.overrideWithValue(box)],
    );
    addTearDown(container.dispose);
    final notifier = container.read(watchlistProvider.notifier);

    expect(await notifier.toggle(_movie), isTrue);
    expect(container.read(watchlistProvider).ids, contains(550));
    expect(await notifier.toggle(_movie), isFalse);
    expect(container.read(watchlistProvider).items, isEmpty);
  });
}
