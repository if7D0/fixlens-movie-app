import 'package:fixlens_movie_app/src/core/network/tmdb_image.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('poster uses w342', () {
    expect(
      TmdbImage.poster('/abc.jpg'),
      'https://image.tmdb.org/t/p/w342/abc.jpg',
    );
  });

  test('backdrop uses w780', () {
    expect(
      TmdbImage.backdrop('/abc.jpg'),
      'https://image.tmdb.org/t/p/w780/abc.jpg',
    );
  });

  test('still uses w500', () {
    expect(
      TmdbImage.still('/abc.jpg'),
      'https://image.tmdb.org/t/p/w500/abc.jpg',
    );
  });

  test('avatar uses w185', () {
    expect(
      TmdbImage.avatar('/abc.jpg'),
      'https://image.tmdb.org/t/p/w185/abc.jpg',
    );
  });

  test('null and empty paths yield null', () {
    expect(TmdbImage.poster(null), isNull);
    expect(TmdbImage.poster(''), isNull);
    expect(TmdbImage.backdrop(null), isNull);
    expect(TmdbImage.avatar(''), isNull);
  });
}
