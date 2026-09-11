import 'package:fixlens_movie_app/src/features/discover/data/models/movie.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> fixture() => {
    'id': 550,
    'title': 'Fight Club',
    'poster_path': '/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg',
    'backdrop_path': '/hZkgoQYus5vegHoetLkCJzb17zJ.jpg',
    'overview': 'An insomniac office worker...',
    'release_date': '1999-10-15',
    'vote_average': 8.433,
    'genre_ids': [18, 53],
  };

  test('fromJson parses full payload', () {
    final m = MovieSummary.fromJson(fixture());
    expect(m.id, 550);
    expect(m.title, 'Fight Club');
    expect(m.posterPath, '/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg');
    expect(m.voteAverage, 8.433);
    expect(m.genreIds, [18, 53]);
    expect(m.year, '1999');
  });

  test('fromJson tolerates missing fields', () {
    final m = MovieSummary.fromJson({'id': 1, 'title': 'X'});
    expect(m.posterPath, isNull);
    expect(m.overview, '');
    expect(m.voteAverage, 0.0);
    expect(m.genreIds, isEmpty);
    expect(m.year, '-');
  });

  test('genre_ids filters non-numeric entries', () {
    final m = MovieSummary.fromJson({
      'id': 2,
      'title': 'Y',
      'genre_ids': [28, null, 'x'],
    });
    expect(m.genreIds, [28]);
  });
}
