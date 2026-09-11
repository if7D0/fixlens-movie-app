import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/mood_map.dart';
import 'quiz_provider.dart';

const _stepTitles = [
  'Lagi pengin ngerasain apa?',
  'Nonton sama siapa?',
  'Punya waktu berapa lama?',
];

/// 3-step mood quiz. Fresh answers on every entry (restart in initState —
/// the single justified local-state exception: one-shot init, not data).
class MoodQuizScreen extends ConsumerStatefulWidget {
  const MoodQuizScreen({super.key});

  @override
  ConsumerState<MoodQuizScreen> createState() => _MoodQuizScreenState();
}

class _MoodQuizScreenState extends ConsumerState<MoodQuizScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(quizProvider.notifier).restart();
  }

  @override
  Widget build(BuildContext context) {
    final quiz = ref.watch(quizProvider);
    final notifier = ref.read(quizProvider.notifier);
    final step = quiz.step.clamp(0, 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find by Mood'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (step > 0) {
              notifier.back();
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'Langkah ${step + 1} dari 3',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LinearProgressIndicator(value: (step + 1) / 3),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              _stepTitles[step],
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(16),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: [
                for (final o in _optionsFor(step))
                  _Tile(
                    emoji: o.$1,
                    label: o.$2,
                    onTap: () {
                      notifier.answerStep(step, o.$3);
                      if (step == 2) context.push('/mood/result');
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<(String, String, String)> _optionsFor(int step) {
    switch (step) {
      case 0:
        return [for (final m in moods) (m.emoji, m.label, m.id)];
      case 1:
        return [for (final c in companies) (c.emoji, c.label, c.id)];
      default:
        return [for (final d in durations) (d.emoji, d.label, d.id)];
    }
  }
}

class _Tile extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;

  const _Tile({required this.emoji, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
