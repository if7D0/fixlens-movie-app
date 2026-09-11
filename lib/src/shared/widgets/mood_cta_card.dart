import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Hero "Find by Mood" CTA: gradient cinematic card, vector icon only
/// (no emoji-as-icon), 48dp+ target, pressed feedback without layout shift.
class MoodCtaCard extends StatelessWidget {
  final VoidCallback onTap;

  const MoodCtaCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Semantics(
        button: true,
        label: 'Find by Mood. Tiga pertanyaan, tiga rekomendasi.',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadii.xl),
            child: Ink(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.moodGradient,
                borderRadius: BorderRadius.circular(AppRadii.xl),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brandViolet.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 28,
                      semanticLabel: 'Ikon mood',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Find by Mood',
                          style: textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '3 pertanyaan • 3 rekomendasi • < 1 menit',
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppRadii.full),
                          ),
                          child: Text(
                            'Mulai kuis',
                            style: textTheme.labelLarge?.copyWith(
                              color: const Color(0xFF4C1D95),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Slim demo-mode banner (replaces the raw Card in Home).
class DemoBanner extends StatelessWidget {
  const DemoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.rating.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
            color: AppColors.rating.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.science_outlined,
              color: AppColors.rating,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Demo mode — TMDB key belum dikonfigurasi. Lihat README untuk cara menambahkannya.',
                style: textTheme.bodySmall?.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
