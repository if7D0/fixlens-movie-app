import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/backend/firebase_bootstrap.dart';
import '../../../core/result/app_result.dart';
import '../../watchlist/data/watchlist_sync.dart';
import '../data/models/review.dart';
import '../data/review_repository.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  // Guarded: only watched after callers verify firebaseReadyProvider.
  ref.watch(firebaseReadyProvider);
  return ReviewRepository(ref.watch(firestoreProvider));
});

final summaryProvider =
    FutureProvider.autoDispose.family<AppResult<ReviewSummary>, int>((
      ref,
      movieId,
    ) {
      if (!ref.watch(firebaseReadyProvider)) {
        return const AppErr('Backend tidak tersedia.');
      }
      return ref.watch(reviewRepositoryProvider).summary(movieId);
    });

final reviewsProvider =
    FutureProvider.autoDispose.family<AppResult<List<Review>>, int>((
      ref,
      movieId,
    ) {
      if (!ref.watch(firebaseReadyProvider)) {
        return const AppErr('Backend tidak tersedia.');
      }
      return ref.watch(reviewRepositoryProvider).listRecent(movieId);
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
