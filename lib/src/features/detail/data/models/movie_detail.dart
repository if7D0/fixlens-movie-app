import '../../../discover/data/models/movie.dart';
import 'cast_member.dart';

/// Full movie detail from `/movie/{id}?append_to_response=credits,videos,similar`.
class MovieDetail {
  final int id;
  final String title;
  final String overview;
  final String releaseDate;
  final double voteAverage;
  final int runtimeMinutes;
  final List<String> genreNames;
  final String? posterPath;
  final String? backdropPath;
  final List<CastMember> cast;
  final String? trailerKey;
  final List<MovieSummary> similar;

  const MovieDetail({
    required this.id,
    required this.title,
    required this.overview,
    required this.releaseDate,
    required this.voteAverage,
    required this.runtimeMinutes,
    required this.genreNames,
    required this.posterPath,
    required this.backdropPath,
    required this.cast,
    required this.trailerKey,
    required this.similar,
  });

  factory MovieDetail.fromJson(Map<String, dynamic> json) {
    final genres = json['genres'];
    final credits = json['credits'];
    final videos = json['videos'];
    final similar = json['similar'];
    return MovieDetail(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? 'Tanpa judul').toString(),
      overview: (json['overview'] ?? '').toString(),
      releaseDate: (json['release_date'] ?? '').toString(),
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      runtimeMinutes: (json['runtime'] as num?)?.toInt() ?? 0,
      genreNames: genres is List
          ? genres
                .whereType<Map<String, dynamic>>()
                .map((g) => (g['name'] ?? '').toString())
                .where((n) => n.isNotEmpty)
                .toList()
          : const [],
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      cast: credits is Map && credits['cast'] is List
          ? (credits['cast'] as List)
                .whereType<Map<String, dynamic>>()
                .take(15)
                .map(CastMember.fromJson)
                .toList()
          : const [],
      trailerKey: _trailerKey(videos),
      similar: similar is Map && similar['results'] is List
          ? (similar['results'] as List)
                .whereType<Map<String, dynamic>>()
                .take(10)
                .map(MovieSummary.fromJson)
                .toList()
          : const [],
    );
  }

  /// Prefers official YouTube trailers, falls back to any YouTube trailer.
  static String? _trailerKey(dynamic videos) {
    if (videos is! Map || videos['results'] is! List) return null;
    final list = (videos['results'] as List)
        .whereType<Map<String, dynamic>>()
        .where(
          (v) =>
              v['site'] == 'YouTube' &&
              v['type'] == 'Trailer' &&
              (v['key'] as String?)?.isNotEmpty == true,
        )
        .toList();
    if (list.isEmpty) return null;
    final official = list.where((v) => v['official'] == true).toList();
    return ((official.isNotEmpty ? official.first : list.first)['key'])
        as String;
  }

  String get year =>
      releaseDate.length >= 4 ? releaseDate.substring(0, 4) : '-';

  String get runtimeLabel =>
      runtimeMinutes > 0 ? '$runtimeMinutes mnt' : '-';

  /// Lightweight summary for watchlist persistence (genre ids unavailable
  /// here; watchlist display only needs poster/title).
  MovieSummary toSummary() => MovieSummary(
    id: id,
    title: title,
    posterPath: posterPath,
    backdropPath: backdropPath,
    overview: overview,
    releaseDate: releaseDate,
    voteAverage: voteAverage,
    genreIds: const [],
  );
}
