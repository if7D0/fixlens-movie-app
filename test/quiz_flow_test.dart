import 'package:dio/dio.dart';
import 'package:fixlens_movie_app/src/app/app.dart';
import 'package:fixlens_movie_app/src/core/network/tmdb_client.dart';
import 'package:fixlens_movie_app/src/core/result/app_result.dart';
import 'package:fixlens_movie_app/src/features/discover/presentation/providers.dart';
import 'package:fixlens_movie_app/src/features/mood/presentation/mood_result_screen.dart';
import 'package:fixlens_movie_app/src/features/mood/presentation/widgets/pick_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake: every list endpoint returns 3 movies with null artwork
/// (no network images in widget tests).
class FlowFakeClient extends TmdbClient {
  FlowFakeClient() : super(dio: Dio());

  Map<String, dynamic> movie(int id) => {
    'id': id,
    'title': 'Film $id',
    'poster_path': null,
    'backdrop_path': null,
    'overview': '',
    'release_date': '2024-01-01',
    'vote_average': 7.5,
    'genre_ids': [35],
  };

  @override
  Future<AppResult<Map<String, dynamic>>> getJson(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (path == '/genre/movie/list') {
      return const AppOk({
        'genres': [
          {'id': 35, 'name': 'Comedy'},
        ],
      });
    }
    return AppOk({
      'results': [movie(1), movie(2), movie(3)],
      'page': 1,
      'total_pages': 1,
    });
  }
}

void main() {
  // NOTE: no Hive box override here. testWidgets runs in a fake-async zone
  // where real Hive disk IO never completes (hangs the runner); the app
  // degrades gracefully to an empty watchlist (verified by design) and the
  // quiz flow needs no box. Hive IO stays in plain test() files.
  Future<ProviderContainer> pumpApp(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [tmdbClientProvider.overrideWithValue(FlowFakeClient())],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const FixLensApp(),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('full quiz flow yields three picks', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Find by Mood'));
    await tester.pumpAndSettle();
    expect(find.text('Lagi pengin ngerasain apa?'), findsOneWidget);

    await tester.tap(find.text('Santai'));
    await tester.pumpAndSettle();
    expect(find.text('Nonton sama siapa?'), findsOneWidget);

    await tester.tap(find.text('Sendiri'));
    await tester.pumpAndSettle();
    expect(find.text('Punya waktu berapa lama?'), findsOneWidget);

    await tester.tap(find.text('Bebas'));
    await tester.pump(); // start navigation + loading state
    await tester.pump(const Duration(seconds: 1)); // fake delay + fetch
    await tester.pumpAndSettle();

    expect(find.byType(PickCard), findsNWidgets(3));
    // Button sits below the cards: ListView builds lazily, so scroll first.
    await tester.scrollUntilVisible(find.text('Ulangi kuis'), 300);
    expect(find.text('Ulangi kuis'), findsOneWidget);
  });

  testWidgets('result without answers shows start CTA', (tester) async {
    // Deep-link straight to result with fresh (empty) quiz state.
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: MoodResultScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Belum ada jawaban'), findsOneWidget);
    expect(find.text('Mulai kuis'), findsOneWidget);
  });
}
