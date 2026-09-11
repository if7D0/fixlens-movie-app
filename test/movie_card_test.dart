import 'package:fixlens_movie_app/src/features/discover/data/models/movie.dart';
import 'package:fixlens_movie_app/src/shared/widgets/movie_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression tests for the review finding: MovieCard overflowed by 4px in
/// the 120x230 rail cell with 2-line titles. Layout bounds below must keep
/// headroom for long titles and larger font scales.
MovieSummary longTitle() => const MovieSummary(
  id: 1,
  title: 'Sebuah Judul Film Yang Sangat Panjang Sekali Untuk Test',
  posterPath: null,
  backdropPath: null,
  overview: '',
  releaseDate: '2024-01-01',
  voteAverage: 8.5,
  genreIds: [],
);

void main() {
  testWidgets('rail cell does not overflow with 2-line title', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 120,
            height: 252,
            child: MovieCard(movie: longTitle()),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('search grid cell does not overflow with 2-line title', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AspectRatio(
              aspectRatio: 0.48,
              child: MovieCard(movie: longTitle()),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
