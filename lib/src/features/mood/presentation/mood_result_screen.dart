import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_empty.dart';
import '../../../shared/widgets/app_error.dart';
import '../../../shared/widgets/app_loading.dart';
import 'quiz_provider.dart';
import 'widgets/pick_card.dart';

/// Quiz result: 3 picks with reasons. Watches the shared [quizProvider];
/// direct entry without answers shows a start-quiz CTA instead of crashing.
class MoodResultScreen extends ConsumerWidget {
  const MoodResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quiz = ref.watch(quizProvider);
    final notifier = ref.read(quizProvider.notifier);

    if (quiz.status == QuizStatus.answering && !quiz.isComplete) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pilihan buat kamu')),
        body: Column(
          children: [
            const Expanded(
              child: AppEmpty(
                title: 'Belum ada jawaban',
                subtitle: 'Mulai kuis dulu untuk dapat rekomendasi.',
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: ElevatedButton(
                onPressed: () => context.go('/mood'),
                child: const Text('Mulai kuis'),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Pilihan buat kamu')),
      body: switch (quiz.status) {
        QuizStatus.loading || QuizStatus.answering => const AppLoading(),
        QuizStatus.error => AppError(
          message: quiz.errorMessage ?? 'Gagal memuat.',
          onRetry: notifier.runQuiz,
        ),
        QuizStatus.result when quiz.picks.isEmpty => Column(
          children: [
            const Expanded(
              child: AppEmpty(
                title: 'Tidak ketemu yang cocok',
                subtitle: 'Coba ubah jawabanmu.',
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: OutlinedButton(
                onPressed: () {
                  notifier.restart();
                  context.pop();
                },
                child: const Text('Ubah jawaban'),
              ),
            ),
          ],
        ),
        QuizStatus.result => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '3 pilihan buat kamu malam ini',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            for (final pick in quiz.picks) ...[
              PickCard(pick: pick),
              const SizedBox(height: 12),
            ],
            OutlinedButton(
              onPressed: () {
                notifier.restart();
                context.pop();
              },
              child: const Text('Ulangi kuis'),
            ),
          ],
        ),
      },
    );
  }
}
