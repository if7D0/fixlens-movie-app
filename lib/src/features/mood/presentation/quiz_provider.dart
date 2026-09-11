import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/result/app_result.dart';
import '../../discover/data/models/movie.dart';
import '../../discover/data/movie_repository.dart';
import '../../discover/presentation/providers.dart';
import '../data/mood_map.dart';

enum QuizStatus { answering, loading, result, error }

/// One recommendation with its deterministic match reason.
class MoodPick {
  final MovieSummary movie;
  final String reason;

  const MoodPick({required this.movie, required this.reason});
}

class QuizState {
  final int step;
  final String? moodId;
  final String? companyId;
  final String? durationId;
  final QuizStatus status;
  final List<MoodPick> picks;
  final String? errorMessage;

  const QuizState({
    this.step = 0,
    this.moodId,
    this.companyId,
    this.durationId,
    this.status = QuizStatus.answering,
    this.picks = const [],
    this.errorMessage,
  });

  bool get isComplete =>
      moodId != null && companyId != null && durationId != null;

  QuizState copyWith({
    int? step,
    String? moodId,
    String? companyId,
    String? durationId,
    QuizStatus? status,
    List<MoodPick>? picks,
    String? errorMessage,
  }) {
    return QuizState(
      step: step ?? this.step,
      moodId: moodId ?? this.moodId,
      companyId: companyId ?? this.companyId,
      durationId: durationId ?? this.durationId,
      status: status ?? this.status,
      picks: picks ?? this.picks,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class QuizNotifier extends Notifier<QuizState> {
  @override
  QuizState build() => const QuizState();

  void answerStep(int step, String id) {
    switch (step) {
      case 0:
        state = state.copyWith(moodId: id, step: 1);
      case 1:
        state = state.copyWith(companyId: id, step: 2);
      case 2:
        state = state.copyWith(durationId: id);
        runQuiz();
      default:
        break;
    }
  }

  void back() {
    if (state.step > 0 && state.status == QuizStatus.answering) {
      state = state.copyWith(step: state.step - 1);
    }
  }

  void restart() {
    state = const QuizState();
  }

  Future<void> runQuiz() async {
    if (!state.isComplete) return;
    state = state.copyWith(status: QuizStatus.loading, errorMessage: null);
    final req = buildRequest(
      moodId: state.moodId!,
      companyId: state.companyId!,
      durationId: state.durationId!,
    );
    var page = await _discover(req, relaxRuntime: false);
    if (!ref.mounted) return;
    if (page is AppOk<MoviePage> && page.data.results.length < 3) {
      // One relax retry without runtime bounds before giving up.
      page = await _discover(req, relaxRuntime: true);
      if (!ref.mounted) return;
    }
    switch (page) {
      case AppOk(data: final p):
        final picks = p.results
            .take(3)
            .map(
              (m) => MoodPick(
                movie: m,
                reason: buildReason(
                  tone: req.tone,
                  companyLabel: req.companyLabel,
                  durationLabel: req.durationLabel,
                  voteAverage: m.voteAverage,
                ),
              ),
            )
            .toList();
        state = state.copyWith(status: QuizStatus.result, picks: picks);
      case AppErr(message: final m):
        state = state.copyWith(status: QuizStatus.error, errorMessage: m);
    }
  }

  Future<AppResult<MoviePage>> _discover(
    QuizRequest req, {
    required bool relaxRuntime,
  }) {
    return ref
        .read(movieRepositoryProvider)
        .discover(
          genreIds: req.genreIds.toSet(),
          minRating: req.minRating,
          voteCountGte: req.minVotes,
          runtimeLte: relaxRuntime ? null : req.runtimeLte,
          runtimeGte: relaxRuntime ? null : req.runtimeGte,
          releaseDateLte: req.releaseDateLte,
        );
  }
}

final quizProvider = NotifierProvider<QuizNotifier, QuizState>(
  QuizNotifier.new,
);
