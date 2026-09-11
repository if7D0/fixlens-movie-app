import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
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
    // Deferred: Riverpod forbids modifying providers during initState.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(quizProvider.notifier).restart();
    });
  }

  @override
  Widget build(BuildContext context) {
    final quiz = ref.watch(quizProvider);
    final notifier = ref.read(quizProvider.notifier);
    final step = quiz.step.clamp(0, 2);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find by Mood'),
        leading: IconButton(
          tooltip: step > 0 ? 'Kembali ke langkah sebelumnya' : 'Tutup kuis',
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
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Text(
                    'Langkah ${step + 1} dari 3',
                    style: textTheme.labelMedium?.copyWith(
                      color: AppColors.mutedText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Step dots: stable slots, no layout shift.
                  for (var i = 0; i < 3; i++)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      width: i == step ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadii.full),
                        gradient: i <= step ? AppColors.moodGradient : null,
                        color: i <= step ? null : AppColors.muted,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.full),
                child: LinearProgressIndicator(
                  value: (step + 1) / 3,
                  minHeight: 6,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Text(
                _stepTitles[step],
                style: textTheme.headlineSmall,
              ),
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
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

class _Tile extends StatefulWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;

  const _Tile({required this.emoji, required this.label, required this.onTap});

  @override
  State<_Tile> createState() => _TileState();
}

class _TileState extends State<_Tile> {
  double _scale = 1.0;

  void _press(bool down) {
    if (!mounted) return;
    setState(() => _scale = down ? 0.96 : 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // Emoji here is USER-DATA content from mood_map (the selectable answer),
    // not a structural nav icon — rendered large with a text label beside it.
    return AnimatedScale(
      scale: _scale,
      duration: AppMotion.fast,
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          onTap: widget.onTap,
          onHighlightChanged: _press,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: const Color(0xFF2A2A42)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.emoji,
                  style: const TextStyle(fontSize: 34),
                  semanticsLabel: widget.label,
                ),
                const SizedBox(height: 6),
                Text(
                  widget.label,
                  style: textTheme.titleSmall?.copyWith(fontSize: 14),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
