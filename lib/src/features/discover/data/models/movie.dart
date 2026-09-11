/// Lightweight movie entry used by lists, search, and similar rails.
/// All JSON parsing is null-safe: missing fields fall back to defaults
/// instead of throwing.
class MovieSummary {
  final int id;
  final String title;
  final String? posterPath;
  final String? backdropPath;
  final String overview;
  final String releaseDate;
  final double voteAverage;
  final List<int> genreIds;

  const MovieSummary({
    required this.id,
    required this.title,
    required this.posterPath,
    required this.backdropPath,
    required this.overview,
    required this.releaseDate,
    required this.voteAverage,
    required this.genreIds,
  });

  factory MovieSummary.fromJson(Map<String, dynamic> json) {
    final rawGenres = json['genre_ids'];
    return MovieSummary(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? json['name'] ?? 'Tanpa judul').toString(),
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      overview: (json['overview'] ?? '').toString(),
      releaseDate: (json['release_date'] ?? '').toString(),
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      genreIds: rawGenres is List
          ? rawGenres
                .whereType<num>()
                .map((e) => e.toInt())
                .where((e) => e != 0)
                .toList()
          : const [],
    );
  }

  /// Serializes for Hive watchlist persistence (JSON maps, no codegen).
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'poster_path': posterPath,
    'backdrop_path': backdropPath,
    'overview': overview,
    'release_date': releaseDate,
    'vote_average': voteAverage,
    'genre_ids': genreIds,
  };

  /// Release year (yyyy) or '-' when unknown.
  String get year =>
      releaseDate.length >= 4 ? releaseDate.substring(0, 4) : '-';
}
