import 'package:dio/dio.dart';
import 'package:fixlens_movie_app/src/core/network/tmdb_client.dart';
import 'package:fixlens_movie_app/src/core/result/app_result.dart';
import 'package:fixlens_movie_app/src/features/discover/presentation/providers.dart';
import 'package:fixlens_movie_app/src/features/mood/presentation/quiz_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class QuizFakeClient extends TmdbClient {
  QuizFakeClient({this.fail = false, this.relaxAware = false}) : super(dio: Dio());

  final bool fail;
  final bool relaxAware;
  int calls = 0;

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
    calls++;
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (fail) return const AppErr('jaringan putus');
    var results = [movie(1), movie(2), movie(3)];
    if (relaxAware && query?['with_runtime.lte'] != null) {
      results = [movie(1)]; // strict runtime filters almost everything out
    }
    return AppOk({'results': results, 'page': 1, 'total_pages': 1});
  }
}

ProviderContainer makeQuizContainer(QuizFakeClient fake) {
  final container = ProviderContainer(
    overrides: [tmdbClientProvider.overrideWithValue(fake)],
  );
  addTearDown(container.dispose);
  return container;
}

Future<void> answerAll(QuizNotifier notifier) async {
  notifier.answerStep(0, 'tertawa');
  notifier.answerStep(1, 'solo');
  notifier.answerStep(2, 'cepat');
  await Future<void>.delayed(const Duration(milliseconds: 300));
}

void main() {
  test('three answers produce three picks with reasons', () async {
    final container = makeQuizContainer(QuizFakeClient());
    await answerAll(container.read(quizProvider.notifier));

    final state = container.read(quizProvider);
    expect(state.status, QuizStatus.result);
    expect(state.picks.length, 3);
    for (final p in state.picks) {
      expect(p.reason, isNotEmpty);
      expect(p.reason, contains('7.5'));
    }
  });

  test('repository error becomes error status with message', () async {
    final container = makeQuizContainer(QuizFakeClient(fail: true));
    await answerAll(container.read(quizProvider.notifier));

    final state = container.read(quizProvider);
    expect(state.status, QuizStatus.error);
    expect(state.errorMessage, 'jaringan putus');
  });

  test('thin results trigger one runtime-relaxed retry', () async {
    final fake = QuizFakeClient(relaxAware: true);
    final container = makeQuizContainer(fake);
    await answerAll(container.read(quizProvider.notifier));

    expect(fake.calls, 2);
    final state = container.read(quizProvider);
    expect(state.status, QuizStatus.result);
    expect(state.picks.length, 3);
  });

  test('runQuiz without complete answers stays answering', () async {
    final container = makeQuizContainer(QuizFakeClient());
    final notifier = container.read(quizProvider.notifier);

    notifier.answerStep(0, 'santai');
    await notifier.runQuiz();

    expect(container.read(quizProvider).status, QuizStatus.answering);
  });

  test('restart resets to initial state', () async {
    final container = makeQuizContainer(QuizFakeClient());
    final notifier = container.read(quizProvider.notifier);

    await answerAll(notifier);
    notifier.restart();

    final state = container.read(quizProvider);
    expect(state.step, 0);
    expect(state.status, QuizStatus.answering);
    expect(state.picks, isEmpty);
  });
}
