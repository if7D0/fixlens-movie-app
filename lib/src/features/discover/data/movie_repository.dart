import '../../../core/network/tmdb_client.dart';
import '../../../core/result/app_result.dart';
import 'models/genre.dart';
import 'models/movie.dart';

/// Paginated movie list envelope from TMDB list endpoints.
class MoviePage {
  final List<MovieSummary> results;
  final int page;
  final int totalPages;

  const MoviePage({
    required this.results,
    required this.page,
    required this.totalPages,
  });

  bool get hasMore => page < totalPages;
}

/// Read-only TMDB movie catalog. UI never touches [TmdbClient] directly.
class MovieRepository {
  MovieRepository(this._client);

  final TmdbClient _client;

  Future<AppResult<List<Genre>>> genres() async {
    final res = await _client.getJson('/genre/movie/list');
    return switch (res) {
      AppOk(data: final data) => AppOk(_genreList(data)),
      AppErr(message: final m) => AppErr(m),
    };
  }

  Future<AppResult<List<MovieSummary>>> trending() async {
    final res = await _client.getJson('/trending/movie/week');
    return _movieList(res);
  }

  Future<AppResult<List<MovieSummary>>> popular() async {
    final res = await _client.getJson('/movie/popular');
    return _movieList(res);
  }

  Future<AppResult<MoviePage>> discover({
    Set<int> genreIds = const {},
    double minRating = 0,
    int page = 1,
    String sortBy = 'popularity.desc',
  }) async {
    final query = <String, dynamic>{'sort_by': sortBy, 'page': '$page'};
    if (genreIds.isNotEmpty) {
      query['with_genres'] = genreIds.join(',');
    }
    if (minRating > 0) query['vote_average.gte'] = '$minRating';
    final res = await _client.getJson('/discover/movie', query: query);
    return _moviePage(res);
  }

  Future<AppResult<MoviePage>> search({required String query, int page = 1}) {
    return _client
        .getJson(
          '/search/movie',
          query: {'query': query, 'page': '$page'},
        )
        .then(_moviePage);
  }

  AppResult<List<MovieSummary>> _movieList(
    AppResult<Map<String, dynamic>> res,
  ) {
    return switch (res) {
      AppOk(data: final data) => AppOk(_summaries(data)),
      AppErr(message: final m) => AppErr(m),
    };
  }

  AppResult<MoviePage> _moviePage(AppResult<Map<String, dynamic>> res) {
    return switch (res) {
      AppOk(data: final data) => AppOk(
        MoviePage(
          results: _summaries(data),
          page: (data['page'] as num?)?.toInt() ?? 1,
          totalPages: (data['total_pages'] as num?)?.toInt() ?? 1,
        ),
      ),
      AppErr(message: final m) => AppErr(m),
    };
  }

  List<MovieSummary> _summaries(Map<String, dynamic> data) {
    final list = data['results'];
    if (list is! List) return const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(MovieSummary.fromJson)
        .toList();
  }

  List<Genre> _genreList(Map<String, dynamic> data) {
    final list = data['genres'];
    if (list is! List) return const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(Genre.fromJson)
        .toList();
  }
}
