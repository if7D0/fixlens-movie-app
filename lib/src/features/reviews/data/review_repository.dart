import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/result/app_result.dart';
import '../../../core/utils/app_log.dart';
import 'models/review.dart';

/// Public reviews under `movie_reviews/{movieId}` (+`/reviews/{uid}`).
/// Summary aggregates are maintained in the SAME transaction as the write
/// (no Cloud Functions in v1). All failures map to [AppErr], never throw.
class ReviewRepository {
  ReviewRepository(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _summaryRef(int movieId) =>
      _db.collection('movie_reviews').doc('$movieId');

  CollectionReference<Map<String, dynamic>> _itemsRef(int movieId) =>
      _summaryRef(movieId).collection('reviews');

  Future<AppResult<void>> upsertReview({
    required int movieId,
    required String uid,
    required String displayName,
    required int rating,
    required String text,
  }) async {
    if (!Review.isValidRating(rating)) {
      return const AppErr('Rating harus 1-10.');
    }
    try {
      final summaryRef = _summaryRef(movieId);
      final myRef = _itemsRef(movieId).doc(uid);
      await _db.runTransaction((tx) async {
        final summarySnap = await tx.get(summaryRef);
        final mySnap = await tx.get(myRef);
        final current = summarySnap.exists && summarySnap.data() != null
            ? ReviewSummary.fromJson(summarySnap.data()!)
            : const ReviewSummary();
        final oldRating = mySnap.exists
            ? (mySnap.data()?['rating'] as num?)?.toInt()
            : null;
        final next = ReviewSummary.apply(
          current: current,
          oldRating: oldRating,
          newRating: rating,
        );
        tx.set(summaryRef, next.toJson());
        tx.set(myRef, Review(
          uid: uid,
          displayName: displayName.isEmpty ? 'Anonim' : displayName,
          rating: rating,
          text: Review.sanitizeText(text),
          updatedAtMs: DateTime.now().millisecondsSinceEpoch,
        ).toJson());
      });
      return const AppOk(null);
    } on FirebaseException catch (e) {
      appLog('review upsert failed: ${e.code}');
      return AppErr(_friendly(e.code));
    } catch (e) {
      appLog('review upsert failed: $e');
      return const AppErr('Gagal menyimpan ulasan.');
    }
  }

  Future<AppResult<void>> deleteMyReview({
    required int movieId,
    required String uid,
  }) async {
    try {
      final summaryRef = _summaryRef(movieId);
      final myRef = _itemsRef(movieId).doc(uid);
      await _db.runTransaction((tx) async {
        final summarySnap = await tx.get(summaryRef);
        final mySnap = await tx.get(myRef);
        if (!mySnap.exists) return;
        final current = summarySnap.exists && summarySnap.data() != null
            ? ReviewSummary.fromJson(summarySnap.data()!)
            : const ReviewSummary();
        final oldRating = (mySnap.data()?['rating'] as num?)?.toInt();
        final next = ReviewSummary.apply(
          current: current,
          oldRating: oldRating,
        );
        tx.set(summaryRef, next.toJson());
        tx.delete(myRef);
      });
      return const AppOk(null);
    } on FirebaseException catch (e) {
      appLog('review delete failed: ${e.code}');
      return AppErr(_friendly(e.code));
    } catch (e) {
      appLog('review delete failed: $e');
      return const AppErr('Gagal menghapus ulasan.');
    }
  }

  Future<AppResult<ReviewSummary>> summary(int movieId) async {
    try {
      final snap = await _summaryRef(movieId).get();
      if (!snap.exists || snap.data() == null) {
        return const AppOk(ReviewSummary());
      }
      return AppOk(ReviewSummary.fromJson(snap.data()!));
    } on FirebaseException catch (e) {
      return AppErr(_friendly(e.code));
    } catch (e) {
      return const AppErr('Gagal memuat ringkasan.');
    }
  }

  Future<AppResult<List<Review>>> listRecent(
    int movieId, {
    int limit = 20,
  }) async {
    try {
      final snap = await _itemsRef(movieId)
          .orderBy('updatedAt', descending: true)
          .limit(limit)
          .get();
      return AppOk([
        for (final d in snap.docs) Review.fromJson(d.id, d.data()),
      ]);
    } on FirebaseException catch (e) {
      return AppErr(_friendly(e.code));
    } catch (e) {
      return const AppErr('Gagal memuat ulasan.');
    }
  }

  Future<AppResult<Review?>> myReview({
    required int movieId,
    required String uid,
  }) async {
    try {
      final snap = await _itemsRef(movieId).doc(uid).get();
      if (!snap.exists || snap.data() == null) {
        return const AppOk<Review?>(null);
      }
      return AppOk(Review.fromJson(snap.id, snap.data()!));
    } on FirebaseException catch (e) {
      return AppErr(_friendly(e.code));
    } catch (e) {
      return const AppErr('Gagal memuat ulasanmu.');
    }
  }

  /// All reviews by one user (single-field where: no composite index).
  /// Sorted newest-first client-side.
  Future<AppResult<List<OwnedReview>>> myReviews(
    String uid, {
    int limit = 20,
  }) async {
    try {
      final snap = await _db
          .collectionGroup('reviews')
          .where('uid', isEqualTo: uid)
          .limit(limit)
          .get();
      final out = <OwnedReview>[];
      for (final d in snap.docs) {
        final movieId = int.tryParse(d.reference.parent.parent?.id ?? '');
        if (movieId == null) continue;
        out.add(OwnedReview(movieId: movieId, review: Review.fromJson(d.id, d.data())));
      }
      out.sort((a, b) => b.review.updatedAtMs.compareTo(a.review.updatedAtMs));
      return AppOk(out);
    } on FirebaseException catch (e) {
      return AppErr(_friendly(e.code));
    } catch (e) {
      return const AppErr('Gagal memuat ulasanmu.');
    }
  }

  String _friendly(String code) {
    if (code.contains('permission-denied')) {
      return 'Tidak punya akses, coba login ulang.';
    }
    if (code.contains('unavailable') || code.contains('network')) {
      return 'Tidak ada koneksi — coba lagi.';
    }
    return 'Operasi gagal ($code).';
  }
}
