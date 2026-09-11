import 'package:fixlens_movie_app/src/core/backend/firebase_bootstrap.dart';
import 'package:fixlens_movie_app/src/core/result/app_result.dart';
import 'package:fixlens_movie_app/src/features/account/data/auth_repository.dart';
import 'package:fixlens_movie_app/src/features/account/presentation/account_provider.dart';
import 'package:fixlens_movie_app/src/features/account/presentation/profile_screen.dart';
import 'package:fixlens_movie_app/src/features/reviews/data/models/review.dart';
import 'package:fixlens_movie_app/src/features/reviews/data/review_repository.dart';
import 'package:fixlens_movie_app/src/features/reviews/presentation/reviews_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'account_test.dart' show FakeAuthRepository;

/// In-memory fake (no Firestore). The provider is overridden, so the real
/// repository is never constructed in these tests.
class FakeReviewRepository implements ReviewRepository {
  final Map<int, Review> store = {};

  @override
  Future<AppResult<void>> upsertReview({
    required int movieId,
    required String uid,
    required String displayName,
    required int rating,
    required String text,
  }) async {
    store[movieId] = Review(
      uid: uid,
      displayName: displayName,
      rating: rating,
      text: text,
      updatedAtMs: 1,
    );
    return const AppOk(null);
  }

  @override
  Future<AppResult<void>> deleteMyReview({
    required int movieId,
    required String uid,
  }) async {
    if (!store.containsKey(movieId)) {
      return const AppErr('tidak ada');
    }
    store.remove(movieId);
    return const AppOk(null);
  }

  @override
  Future<AppResult<List<OwnedReview>>> myReviews(
    String uid, {
    int limit = 20,
  }) async {
    return AppOk([
      for (final e in store.entries)
        OwnedReview(movieId: e.key, review: e.value),
    ]);
  }

  @override
  Future<AppResult<ReviewSummary>> summary(int movieId) =>
      throw UnimplementedError();

  @override
  Future<AppResult<List<Review>>> listRecent(int movieId, {int limit = 20}) =>
      throw UnimplementedError();

  @override
  Future<AppResult<Review?>> myReview({
    required int movieId,
    required String uid,
  }) => throw UnimplementedError();

  @override
  Stream<AppResult<ReviewSummary>> watchSummary(int movieId) =>
      throw UnimplementedError();

  @override
  Stream<AppResult<List<Review>>> watchRecent(int movieId, {int limit = 20}) =>
      throw UnimplementedError();
}

const _me = AppUser(
  uid: 'u9',
  displayName: 'Saya',
  email: null,
  photoUrl: null,
);

void main() {
  Future<void> pumpProfile(
    WidgetTester tester,
    FakeReviewRepository reviews,
  ) async {
    final auth = FakeAuthRepository()..emit(_me);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reviewRepositoryProvider.overrideWithValue(reviews),
          authRepositoryProvider.overrideWithValue(auth),
          firebaseReadyProvider.overrideWithValue(true),
        ],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('history row has delete action', (tester) async {
    final reviews = FakeReviewRepository()
      ..store[550] = const Review(
        uid: 'u9',
        displayName: 'Saya',
        rating: 8,
        text: 'Bagus',
        updatedAtMs: 1,
      );
    await pumpProfile(tester, reviews);

    expect(find.textContaining('★ 8'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  testWidgets('delete removes row, undo restores it', (tester) async {
    final reviews = FakeReviewRepository()
      ..store[550] = const Review(
        uid: 'u9',
        displayName: 'Saya',
        rating: 8,
        text: 'Bagus',
        updatedAtMs: 1,
      );
    await pumpProfile(tester, reviews);
    expect(find.textContaining('★ 8'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(find.textContaining('★ 8'), findsNothing);
    expect(find.text('Ulasan dihapus'), findsOneWidget);

    await tester.tap(find.text('Urungkan'));
    await tester.pumpAndSettle();

    expect(find.textContaining('★ 8'), findsOneWidget);
    expect(reviews.store.containsKey(550), isTrue);
  });
}
