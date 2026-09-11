import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/backend/firebase_bootstrap.dart';
import '../../../core/result/app_result.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_empty.dart';
import '../../../shared/widgets/app_error.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../reviews/data/models/review.dart';
import '../../reviews/presentation/reviews_provider.dart';
import '../../watchlist/presentation/watchlist_provider.dart';
import 'account_provider.dart';

/// Fourth tab: Google sign-in, manual sync, my reviews, sign out.
/// Fully local-safe: without backend it explains local-only mode.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ready = ref.watch(firebaseReadyProvider);
    if (!ready) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(
                  'Profil',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const Expanded(
                child: AppEmpty(
                  title: 'Mode lokal',
                  subtitle: 'Backend tidak tersedia di build ini. '
                      'Watchlist tersimpan lokal di HP.',
                  icon: Icons.smartphone_outlined,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Auto-sync on login is owned by WatchlistNotifier (survives tab
    // switches); here only the manual button lives.
    final account = ref.watch(accountProvider);
    final user = account.user;

    if (account.status == AccountStatus.signingIn) {
      return const Scaffold(body: SafeArea(child: AppLoading(message: 'Login…')));
    }

    if (user == null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      gradient: AppColors.moodGradient,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(2),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.card,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.account_circle_outlined,
                        size: 56,
                        color: Color(0xFFA5B4FC),
                        semanticLabel: 'Ikon profil',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Simpan & sinkron di mana saja',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Login untuk sinkronisasi dan ulasan. '
                    'Tanpa login, aplikasi tetap jalan lokal.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.mutedText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (account.errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      account.errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () =>
                          ref.read(accountProvider.notifier).signIn(),
                      icon: const Icon(Icons.login, size: 20),
                      label: const Text('Login dengan Google'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final savedCount = ref.watch(
      watchlistProvider.select((s) => s.ids.length),
    );
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text('Profil', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.moodGradient,
                borderRadius: BorderRadius.circular(AppRadii.xl),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    backgroundImage: user.photoUrl != null
                        ? NetworkImage(user.photoUrl!)
                        : null,
                    child: user.photoUrl == null
                        ? const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 32,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName ?? 'Pengguna',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          user.email ?? '',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(AppRadii.full),
                          ),
                          child: Text(
                            '$savedCount film tersimpan',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _syncNow(context, ref, user.uid),
                    icon: const Icon(Icons.sync, size: 20),
                    label: const Text('Sinkronkan'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        ref.read(accountProvider.notifier).signOut(),
                    icon: const Icon(Icons.logout, size: 20),
                    label: const Text('Logout'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Ulasan saya',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            _MyReviews(uid: user.uid),
          ],
        ),
      ),
    );
  }

  Future<void> _syncNow(
    BuildContext context,
    WidgetRef ref,
    String uid,
  ) async {
    final res = await ref
        .read(watchlistProvider.notifier)
        .syncFromCloud(uid);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          switch (res) {
            AppOk(data: final m) => m,
            AppErr(message: final m) => m,
          },
        ),
      ),
    );
  }
}

class _MyReviews extends ConsumerWidget {
  final String uid;

  const _MyReviews({required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myReviewsProvider(uid));
    return switch (async) {
      AsyncData(value: AppOk(data: final items)) => items.isEmpty
          ? const Text('Belum ada ulasan.')
          : Column(
              children: [
                for (final item in items)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${item.review.displayName} • ★ ${item.review.rating}',
                    ),
                    subtitle: item.review.text.isEmpty
                        ? null
                        : Text(
                            item.review.text,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () =>
                              _deleteReview(context, ref, uid, item),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () => context.push('/movie/${item.movieId}'),
                  ),
              ],
            ),
      AsyncData(value: AppErr(message: final m)) => AppError(
        message: m,
        onRetry: () => ref.invalidate(myReviewsProvider(uid)),
      ),
      _ => const AppLoading(),
    };
  }
}

/// Deletes one history entry with undo (re-upserts the same content).
Future<void> _deleteReview(
  BuildContext context,
  WidgetRef ref,
  String uid,
  OwnedReview item,
) async {
  final res = await ref
      .read(reviewRepositoryProvider)
      .deleteMyReview(movieId: item.movieId, uid: uid);
  ref.invalidate(myReviewsProvider(uid));
  if (!context.mounted) return;
  switch (res) {
    case AppOk():
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Ulasan dihapus'),
          action: SnackBarAction(
            label: 'Urungkan',
            onPressed: () async {
              await ref.read(reviewRepositoryProvider).upsertReview(
                movieId: item.movieId,
                uid: uid,
                displayName: item.review.displayName,
                rating: item.review.rating,
                text: item.review.text,
              );
              ref.invalidate(myReviewsProvider(uid));
            },
          ),
        ),
      );
    case AppErr(message: final m):
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }
}
