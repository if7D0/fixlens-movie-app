import 'package:fixlens_movie_app/src/features/detail/data/models/cast_member.dart';
import 'package:fixlens_movie_app/src/features/detail/data/models/movie_detail.dart';
import 'package:fixlens_movie_app/src/features/discover/data/models/genre.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> detailJson() => {
  'id': 550,
  'title': 'Fight Club',
  'overview': 'O',
  'release_date': '1999-10-15',
  'vote_average': 8.4,
  'runtime': 139,
  'genres': [
    {'id': 18, 'name': 'Drama'},
  ],
  'poster_path': '/p.jpg',
  'backdrop_path': '/b.jpg',
  'credits': {
    'cast': [
      {'name': 'Brad Pitt', 'character': 'Tyler', 'profile_path': '/a.jpg'},
      {'name': 'X', 'character': '', 'profile_path': null},
    ],
  },
  'videos': {
    'results': [
      {
        'site': 'YouTube',
        'type': 'Teaser',
        'key': 'teaser1',
        'official': true,
      },
      {
        'site': 'YouTube',
        'type': 'Trailer',
        'key': 'trailer1',
        'official': false,
      },
      {
        'site': 'YouTube',
        'type': 'Trailer',
        'key': 'official1',
        'official': true,
      },
      {'site': 'Vimeo', 'type': 'Trailer', 'key': 'vimeo1'},
    ],
  },
  'similar': {
    'results': [
      {
        'id': 2,
        'title': 'Y',
        'vote_average': 7,
        'genre_ids': [18],
      },
    ],
  },
};

void main() {
  test('genre and cast parse', () {
    final g = Genre.fromJson({'id': 18, 'name': 'Drama'});
    expect(g.id, 18);
    expect(Genre.fromJson({}).name, '');

    final c = CastMember.fromJson({
      'name': 'N',
      'character': 'C',
      'profile_path': null,
    });
    expect(c.profilePath, isNull);
  });

  test('detail parses full payload', () {
    final d = MovieDetail.fromJson(detailJson());
    expect(d.title, 'Fight Club');
    expect(d.runtimeLabel, '139 mnt');
    expect(d.genreNames, ['Drama']);
    expect(d.cast.length, 2);
    expect(d.similar.single.id, 2);
    expect(d.toSummary().id, 550);
  });

  test('trailerKey prefers official YouTube trailer', () {
    expect(MovieDetail.fromJson(detailJson()).trailerKey, 'official1');
  });

  test('trailerKey falls back to any YouTube trailer', () {
    final json = detailJson();
    (json['videos'] as Map)['results'] = [
      {'site': 'YouTube', 'type': 'Trailer', 'key': 'only1'},
    ];
    expect(MovieDetail.fromJson(json).trailerKey, 'only1');
  });

  test('trailerKey null without YouTube trailer', () {
    final json = detailJson();
    (json['videos'] as Map)['results'] = [
      {'site': 'Vimeo', 'type': 'Trailer', 'key': 'v1'},
    ];
    expect(MovieDetail.fromJson(json).trailerKey, isNull);

    final noVideos = detailJson()..remove('videos');
    expect(MovieDetail.fromJson(noVideos).trailerKey, isNull);
  });

  test('missing sections default safely', () {
    final d = MovieDetail.fromJson({'id': 1});
    expect(d.title, 'Tanpa judul');
    expect(d.runtimeLabel, '-');
    expect(d.cast, isEmpty);
    expect(d.trailerKey, isNull);
  });
}
