import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/backend/firebase_bootstrap.dart';
import '../../../core/result/app_result.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/section_header.dart';
import '../../account/presentation/account_provider.dart';
import '../data/models/review.dart';
import 'review_sheet.dart';
import 'reviews_provider.dart';

/// Public reviews section for a movie: average badge, preview list,
/// write CTA (login-gated).
class ReviewSection extends ConsumerWidget {
  final int movieId;

  const ReviewSection({super.key, required this.movieId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ready = ref.watch(firebaseReadyProvider);
    if (!ready) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Text(
          'Ulasan membutuhkan koneksi backend.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
        ),
      );
    }

    final account = ref.watch(accountProvider);
    final uid = account.user?.uid;
    final summary = ref.watch(summaryProvider(movieId));
    final list = ref.watch(reviewsProvider(movieId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Ulasan',
          subtitle: 'Dari penonton buat penonton',
          actionLabel:
              switch (summary) {
                AsyncData(value: AppOk(data: final s)) when s.count > 0 =>
                  '★ ${s.avg.toStringAsFixed(1)} (${s.count})',
                AsyncData(value: AppOk()) => 'Baru',
                _ => null,
              },
        ),
        switch (list) {
          AsyncData(value: AppOk(data: final reviews)) =>
            reviews.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Jadilah yang pertama mengulas.'),
                  )
                : Column(
                    children: [
                      for (final r in reviews.take(3)) _ReviewRow(review: r),
                    ],
                  ),
          AsyncData(value: AppErr(message: final m)) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextButton(
              onPressed: () {
                ref.invalidate(summaryProvider(movieId));
                ref.invalidate(reviewsProvider(movieId));
              },
              child: Text('Gagal memuat: $m. Coba lagi.'),
            ),
          ),
          _ => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: LinearProgressIndicator(),
          ),
        },
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: SizedBox(
            width: double.infinity,
            child: uid == null
                ? OutlinedButton.icon(
                    onPressed: () => context.push('/profile'),
                    icon: const Icon(Icons.login, size: 20),
                    label: const Text('Login untuk menulis ulasan'),
                  )
                : FilledButton.icon(
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => ReviewSheet(movieId: movieId, uid: uid),
                    ),
                    icon: const Icon(Icons.rate_review_outlined, size: 20),
                    label: const Text('Tulis ulasan'),
                  ),
          ),
        ),
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final Review review;

  const _ReviewRow({required this.review});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final initial = review.displayName.isNotEmpty
        ? review.displayName[0].toUpperCase()
        : '?';
    return ListTile(
      leading: CircleAvatar(child: Text(initial)),
      title: Text(
        '${review.displayName} • ★ ${review.rating}',
        style: textTheme.bodyMedium,
      ),
      subtitle: review.text.isEmpty
          ? null
          : Text(
              review.text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
      dense: true,
    );
  }
}
