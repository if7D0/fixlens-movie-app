import 'package:fixlens_movie_app/src/features/reviews/data/models/review.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('summary add math', () {
    const empty = ReviewSummary();
    final one = ReviewSummary.apply(current: empty, newRating: 8);
    expect(one.count, 1);
    expect(one.avg, 8);

    final two = ReviewSummary.apply(current: one, newRating: 6);
    expect(two.count, 2);
    expect(two.avg, 7);
  });

  test('summary change math', () {
    final s = ReviewSummary.apply(
      current: const ReviewSummary(sum: 14, count: 2),
      oldRating: 8,
      newRating: 10,
    );
    expect(s.count, 2);
    expect(s.avg, 8);
  });

  test('summary delete math empties to zero', () {
    final s = ReviewSummary.apply(
      current: const ReviewSummary(sum: 10, count: 1),
      oldRating: 10,
    );
    expect(s.count, 0);
    expect(s.avg, 0);
  });

  test('text sanitized to 500 chars', () {
    expect(Review.sanitizeText('  hi  '), 'hi');
    expect(Review.sanitizeText('a' * 600).length, 500);
    expect(Review.isValidRating(0), isFalse);
    expect(Review.isValidRating(11), isFalse);
    expect(Review.isValidRating(7), isTrue);
  });

  test('review json round-trip', () {
    const r = Review(
      uid: 'u1',
      displayName: 'A',
      rating: 9,
      text: 'Bagus',
      updatedAtMs: 123,
    );
    final restored = Review.fromJson('u1', r.toJson());
    expect(restored.rating, 9);
    expect(restored.text, 'Bagus');
    expect(ReviewSummary.fromJson(const ReviewSummary(sum: 9, count: 1).toJson()).avg, 9);
  });
}
