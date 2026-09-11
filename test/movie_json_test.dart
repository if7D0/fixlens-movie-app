import 'package:fixlens_movie_app/src/features/discover/data/models/movie.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('toJson round-trip is stable', () {
    const original = MovieSummary(
      id: 550,
      title: 'Fight Club',
      posterPath: '/p.jpg',
      backdropPath: '/b.jpg',
      overview: 'O',
      releaseDate: '1999-10-15',
      voteAverage: 8.4,
      genreIds: [18, 53],
    );
    final restored = MovieSummary.fromJson(original.toJson());
    expect(restored.toJson(), original.toJson());
    expect(restored.year, '1999');
  });

  test('toJson tolerates null paths', () {
    final m = MovieSummary.fromJson(<String, dynamic>{'id': 1, 'title': 'X'});
    final json = m.toJson();
    expect(json['poster_path'], isNull);
    expect(MovieSummary.fromJson(json).id, 1);
  });
}
