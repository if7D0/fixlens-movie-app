import 'package:fixlens_movie_app/src/features/mood/data/mood_map.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every mood has genres and tone', () {
    expect(moods.length, 8);
    for (final m in moods) {
      expect(m.genreIds, isNotEmpty, reason: m.id);
      expect(m.tone, isNotEmpty, reason: m.id);
    }
  });

  test('keluarga excludes horror and raises vote floor', () {
    final req = buildRequest(
      moodId: 'tegang',
      companyId: 'keluarga',
      durationId: 'bebas',
    );
    expect(req.genreIds, isNot(contains(27)));
    expect(req.minVotes, 200);
  });

  test('pasangan adds romance when missing', () {
    final req = buildRequest(
      moodId: 'semangat',
      companyId: 'pasangan',
      durationId: 'bebas',
    );
    expect(req.genreIds, contains(10749));
  });

  test('nostalgia caps release year', () {
    final req = buildRequest(
      moodId: 'nostalgia',
      companyId: 'solo',
      durationId: 'bebas',
    );
    expect(req.releaseDateLte, '2010-12-31');
  });

  test('duration maps to runtime bounds', () {
    final cepat = buildRequest(
      moodId: 'santai',
      companyId: 'solo',
      durationId: 'cepat',
    );
    expect(cepat.runtimeLte, 100);
    expect(cepat.runtimeGte, isNull);
    final bebas = buildRequest(
      moodId: 'santai',
      companyId: 'solo',
      durationId: 'bebas',
    );
    expect(bebas.runtimeLte, isNull);
  });

  test('unknown ids fall back to neutral defaults', () {
    final req = buildRequest(
      moodId: '???',
      companyId: '???',
      durationId: '???',
    );
    expect(req.tone, 'Populer dan seru');
    expect(req.minRating, 6.5);
  });

  test('reason contains tone, company, duration, rating', () {
    final reason = buildReason(
      tone: 'Lucu dan menghibur',
      companyLabel: 'sendirian',
      durationLabel: '< 100 menit',
      voteAverage: 7.83,
    );
    expect(reason, contains('Lucu dan menghibur'));
    expect(reason, contains('sendirian'));
    expect(reason, contains('< 100 menit'));
    expect(reason, contains('7.8'));
  });
}
