import 'package:dio/dio.dart';
import 'package:fixlens_movie_app/src/core/network/tmdb_client.dart';
import 'package:fixlens_movie_app/src/core/result/app_result.dart';
import 'package:fixlens_movie_app/src/features/discover/presentation/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake client: no network, deterministic envelopes.
class FakeTmdbClient extends TmdbClient {
  FakeTmdbClient() : super(dio: Dio());

  int calls = 0;
  final List<String> paths = [];

  Map<String, dynamic> movie(int id, {List<int> genres = const [28]}) => {
    'id': id,
    'title': 'Film $id',
    'poster_path': null,
    'backdrop_path': null,
    'overview': '',
    'release_date': '2024-01-01',
    'vote_average': id % 10 == 1 ? 9.0 : 5.0,
    'genre_ids': genres,
  };

  @override
  Future<AppResult<Map<String, dynamic>>> getJson(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    calls++;
    paths.add(path);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final page = int.tryParse('${query?['page'] ?? 1}') ?? 1;
    if (path == '/genre/movie/list') {
      return const AppOk({
        'genres': [
          {'id': 28, 'name': 'Action'},
          {'id': 18, 'name': 'Drama'},
        ],
      });
    }
    return AppOk({
      'results': [movie(page * 10 + 1), movie(page * 10 + 2)],
      'page': page,
      'total_pages': 2,
    });
  }
}

ProviderContainer makeContainer(FakeTmdbClient fake) {
  final container = ProviderContainer(
    overrides: [tmdbClientProvider.overrideWithValue(fake)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('rapid typing collapses to a single fetch (debounce)', () async {
    final fake = FakeTmdbClient();
    final container = makeContainer(fake);
    final notifier = container.read(searchProvider.notifier);

    notifier.setQuery('d');
    notifier.setQuery('du');
    notifier.setQuery('dune');
    await Future<void>.delayed(const Duration(milliseconds: 700));

    expect(fake.calls, 1);
    expect(fake.paths.single, '/search/movie');
    final state = container.read(searchProvider);
    expect(state.status, SearchStatus.data);
    expect(state.results.length, 2);
  });

  test('genre toggle fetches immediately via discover', () async {
    final fake = FakeTmdbClient();
    final container = makeContainer(fake);

    container.read(searchProvider.notifier).toggleGenre(28);
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final state = container.read(searchProvider);
    expect(state.status, SearchStatus.data);
    expect(fake.paths.single, '/discover/movie');
  });

  test('loadMore appends page 2 and clears hasMore', () async {
    final fake = FakeTmdbClient();
    final container = makeContainer(fake);
    final notifier = container.read(searchProvider.notifier);

    notifier.toggleGenre(28);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(container.read(searchProvider).hasMore, isTrue);

    await notifier.loadMore();
    final state = container.read(searchProvider);
    expect(state.results.length, 4);
    expect(state.page, 2);
    expect(state.hasMore, isFalse);
    expect(state.status, SearchStatus.data);
  });

  test('search results are filtered client-side by genre and rating', () async {
    final fake = FakeTmdbClient();
    final container = makeContainer(fake);
    final notifier = container.read(searchProvider.notifier);

    // Movie 11 has vote 9.0, movie 12 has 5.0; both genre 28.
    notifier.setMinRating(8.0);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    notifier.setQuery('dune');
    await Future<void>.delayed(const Duration(milliseconds: 700));

    final state = container.read(searchProvider);
    expect(state.status, SearchStatus.data);
    expect(state.results.map((m) => m.id), [11]);
  });

  test('rating slider drag collapses to a single fetch (debounce)', () async {
    final fake = FakeTmdbClient();
    final container = makeContainer(fake);
    final notifier = container.read(searchProvider.notifier);

    notifier.setMinRating(5.0);
    notifier.setMinRating(6.0);
    notifier.setMinRating(7.0);
    await Future<void>.delayed(const Duration(milliseconds: 700));

    expect(fake.calls, 1);
    expect(container.read(searchProvider).minRating, 7.0);
  });
}
