import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/tmdb_client.dart';
import '../../../core/result/app_result.dart';
import '../data/models/genre.dart';
import '../data/models/movie.dart';
import '../data/movie_repository.dart';

final tmdbClientProvider = Provider<TmdbClient>((ref) => TmdbClient());

final movieRepositoryProvider = Provider<MovieRepository>(
  (ref) => MovieRepository(ref.watch(tmdbClientProvider)),
);

final genresProvider = FutureProvider.autoDispose<AppResult<List<Genre>>>((
  ref,
) {
  return ref.watch(movieRepositoryProvider).genres();
});

final trendingProvider =
    FutureProvider.autoDispose<AppResult<List<MovieSummary>>>((ref) {
      return ref.watch(movieRepositoryProvider).trending();
    });

final popularProvider =
    FutureProvider.autoDispose<AppResult<List<MovieSummary>>>((ref) {
      return ref.watch(movieRepositoryProvider).popular();
    });

/// Search section status. Mirrors the Phase 1 "one state, status per
/// section" convention at single-section scale.
enum SearchStatus { initial, loading, data, empty, error, loadingMore }

class SearchState {
  final String query;
  final Set<int> genres;
  final double minRating;
  final List<MovieSummary> results;
  final int page;
  final bool hasMore;
  final SearchStatus status;
  final String? errorMessage;

  const SearchState({
    this.query = '',
    this.genres = const {},
    this.minRating = 0,
    this.results = const [],
    this.page = 1,
    this.hasMore = false,
    this.status = SearchStatus.initial,
    this.errorMessage,
  });

  SearchState copyWith({
    String? query,
    Set<int>? genres,
    double? minRating,
    List<MovieSummary>? results,
    int? page,
    bool? hasMore,
    SearchStatus? status,
    String? errorMessage,
  }) {
    return SearchState(
      query: query ?? this.query,
      genres: genres ?? this.genres,
      minRating: minRating ?? this.minRating,
      results: results ?? this.results,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class SearchNotifier extends Notifier<SearchState> {
  Timer? _debounce;
  int _requestToken = 0;

  @override
  SearchState build() {
    ref.onDispose(() => _debounce?.cancel());
    return const SearchState();
  }

  void setQuery(String value) {
    state = state.copyWith(query: value);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _fetch());
  }

  void toggleGenre(int id) {
    final next = Set<int>.of(state.genres);
    if (!next.remove(id)) next.add(id);
    state = state.copyWith(genres: next);
    _fetch();
  }

  void setMinRating(double value) {
    // Slider fires per tick: update the label immediately but debounce the
    // fetch like text queries to avoid spamming the API while dragging.
    state = state.copyWith(minRating: value);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _fetch());
  }

  Future<void> refresh() => _fetch();

  Future<void> loadMore() async {
    if (state.status == SearchStatus.loadingMore || !state.hasMore) return;
    final token = ++_requestToken;
    state = state.copyWith(status: SearchStatus.loadingMore);
    final page = await _runQuery(state.page + 1);
    if (token != _requestToken || !ref.mounted) return;
    switch (page) {
      case AppOk(data: final p):
        state = state.copyWith(
          results: [...state.results, ...p.results],
          page: p.page,
          hasMore: p.hasMore,
          status: SearchStatus.data,
        );
      case AppErr(message: final m):
        state = state.copyWith(
          status: SearchStatus.data,
          errorMessage: m,
        );
    }
  }

  Future<void> _fetch() async {
    final token = ++_requestToken;
    state = state.copyWith(status: SearchStatus.loading, errorMessage: null);
    final page = await _runQuery(1);
    if (token != _requestToken || !ref.mounted) return;
    switch (page) {
      case AppOk(data: final p):
        state = state.copyWith(
          results: p.results,
          page: p.page,
          hasMore: p.hasMore,
          status: p.results.isEmpty
              ? SearchStatus.empty
              : SearchStatus.data,
        );
      case AppErr(message: final m):
        state = state.copyWith(
          status: SearchStatus.error,
          errorMessage: m,
        );
    }
  }

  Future<AppResult<MoviePage>> _runQuery(int page) {
    final repo = ref.read(movieRepositoryProvider);
    final q = state.query.trim();
    if (q.isEmpty) {
      return repo.discover(
        genreIds: state.genres,
        minRating: state.minRating,
        page: page,
      );
    }
    return repo.search(query: q, page: page).then((res) {
      // /search ignores genre/rating params: apply them client-side.
      return switch (res) {
        AppOk(data: final p) => AppOk(
          MoviePage(
            results: p.results.where(_matchesFilters).toList(),
            page: p.page,
            totalPages: p.totalPages,
          ),
        ),
        AppErr(message: final m) => AppErr(m),
      };
    });
  }

  bool _matchesFilters(MovieSummary m) {
    if (state.genres.isNotEmpty &&
        !m.genreIds.any(state.genres.contains)) {
      return false;
    }
    if (state.minRating > 0 && m.voteAverage < state.minRating) return false;
    return true;
  }
}

final searchProvider = NotifierProvider<SearchNotifier, SearchState>(
  SearchNotifier.new,
);
