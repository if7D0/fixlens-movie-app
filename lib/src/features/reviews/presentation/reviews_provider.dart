import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/backend/firebase_bootstrap.dart';
import '../../../core/result/app_result.dart';
import '../../watchlist/data/watchlist_sync.dart';
import '../data/models/review.dart';
import '../data/review_repository.dart';

String _reviewFriendly(String code) {
  if (code.contains('permission-denied')) {
    return 'Tidak punya akses, coba login ulang.';
  }
  if (code.contains('unavailable') || code.contains('network')) {
    return 'Tidak ada koneksi — coba lagi.';
  }
  return 'Operasi gagal ($code).';
}

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  // Guarded: only watched after callers verify firebaseReadyProvider.
  ref.watch(firebaseReadyProvider);
  return ReviewRepository(ref.watch(firestoreProvider));
});

final summaryProvider =
    StreamProvider.autoDispose.family<AppResult<ReviewSummary>, int>((
      ref,
      movieId,
    ) async* {
      if (!ref.watch(firebaseReadyProvider)) {
        yield const AppErr('Backend tidak tersedia.');
        return;
      }
      yield* ref
          .watch(reviewRepositoryProvider)
          .watchSummary(movieId)
          .handleError(
            (Object e) => AppErr<ReviewSummary>(
              e is FirebaseException
                  ? _reviewFriendly(e.code)
                  : 'Gagal memuat ringkasan.',
            ),
          );
    });

final reviewsProvider =
    StreamProvider.autoDispose.family<AppResult<List<Review>>, int>((
      ref,
      movieId,
    ) async* {
      if (!ref.watch(firebaseReadyProvider)) {
        yield const AppErr('Backend tidak tersedia.');
        return;
      }
      yield* ref
          .watch(reviewRepositoryProvider)
          .watchRecent(movieId)
          .handleError(
            (Object e) => AppErr<List<Review>>(
              e is FirebaseException
                  ? _reviewFriendly(e.code)
                  : 'Gagal memuat ulasan.',
            ),
          );
    });

final myReviewProvider =
    FutureProvider.autoDispose
        .family<AppResult<Review?>, ({int movieId, String uid})>(
          (ref, key) {
            if (!ref.watch(firebaseReadyProvider)) {
              return const AppErr<Review?>('Backend tidak tersedia.');
            }
            return ref
                .watch(reviewRepositoryProvider)
                .myReview(movieId: key.movieId, uid: key.uid);
          },
        );

final myReviewsProvider =
    FutureProvider.autoDispose.family<AppResult<List<OwnedReview>>, String>((
      ref,
      uid,
    ) {
      if (!ref.watch(firebaseReadyProvider)) {
        return const AppErr('Backend tidak tersedia.');
      }
      return ref.watch(reviewRepositoryProvider).myReviews(uid);
    });
