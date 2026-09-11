import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.moodGradient,
                borderRadius: BorderRadius.circular(AppRadii.xl),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.celebration_outlined,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '3 pilihan buat kamu malam ini',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        Text(
                          'Dipilih dari jawaban kuismu',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < quiz.picks.length; i++) ...[
              PickCard(pick: quiz.picks[i], rank: i + 1),
              const SizedBox(height: 12),
            ],
            OutlinedButton.icon(
              onPressed: () {
                notifier.restart();
                context.pop();
              },
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Ulangi kuis'),
            ),
          ],
        ),
      },
    );
  }
}
