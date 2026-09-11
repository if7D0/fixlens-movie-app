import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/backend/firebase_bootstrap.dart';
import '../../../core/result/app_result.dart';
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
        appBar: AppBar(title: const Text('Profil')),
        body: const AppEmpty(
          title: 'Mode lokal',
          subtitle: 'Backend tidak tersedia di build ini. '
              'Watchlist tersimpan lokal di HP.',
        ),
      );
    }

    // Auto-sync on login is owned by WatchlistNotifier (survives tab
    // switches); here only the manual button lives.
    final account = ref.watch(accountProvider);
    final user = account.user;

    if (account.status == AccountStatus.signingIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil')),
        body: const AppLoading(),
      );
    }

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_circle_outlined, size: 72),
                const SizedBox(height: 12),
                const Text(
                  'Login untuk sinkronisasi dan ulasan. '
                  'Tanpa login, aplikasi tetap jalan lokal.',
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
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      ref.read(accountProvider.notifier).signIn(),
                  child: const Text('Login dengan Google'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundImage: user.photoUrl != null
                  ? NetworkImage(user.photoUrl!)
                  : null,
              child: user.photoUrl == null
                  ? const Icon(Icons.person)
                  : null,
            ),
            title: Text(user.displayName ?? 'Pengguna'),
            subtitle: Text(user.email ?? ''),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _syncNow(context, ref, user.uid),
                  child: const Text('Sinkronkan watchlist'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      ref.read(accountProvider.notifier).signOut(),
                  child: const Text('Logout'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Ulasan saya',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          _MyReviews(uid: user.uid),
        ],
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
