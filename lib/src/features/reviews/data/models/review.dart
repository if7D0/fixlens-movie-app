/// Public movie review (rating 1-10 + text ≤500). Timestamps are plain
/// millisecond ints (no Timestamp coupling) for deterministic tests.
class Review {
  static const int maxTextLength = 500;

  final String uid;
  final String displayName;
  final int rating;
  final String text;
  final int updatedAtMs;

  const Review({
    required this.uid,
    required this.displayName,
    required this.rating,
    required this.text,
    required this.updatedAtMs,
  });

  /// Trims and caps length (never rejects — UI stays friendly).
  static String sanitizeText(String value) {
    final trimmed = value.trim();
    if (trimmed.length <= maxTextLength) return trimmed;
    return trimmed.substring(0, maxTextLength);
  }

  static bool isValidRating(int rating) => rating >= 1 && rating <= 10;

  factory Review.fromJson(String uid, Map<String, dynamic> json) {
    return Review(
      uid: uid,
      displayName: (json['displayName'] ?? 'Anonim').toString(),
      rating: (json['rating'] as num?)?.toInt().clamp(1, 10) ?? 5,
      text: (json['text'] ?? '').toString(),
      updatedAtMs: (json['updatedAt'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'uid': uid, // duplicated for collectionGroup queries
    'displayName': displayName,
    'rating': rating,
    'text': text,
    'updatedAt': updatedAtMs,
  };
}

/// A review coupled with its movie id (for "my reviews" lists built from
/// collectionGroup queries where the parent id is the movie id).
class OwnedReview {
  final int movieId;
  final Review review;

  const OwnedReview({required this.movieId, required this.review});
}

/// Denormalized aggregate stored at `movie_reviews/{movieId}`.
/// Sum-based for exact transactional math; UI reads [avg].
class ReviewSummary {
  final double sum;
  final int count;

  const ReviewSummary({this.sum = 0, this.count = 0});

  double get avg => count <= 0 ? 0 : sum / count;

  factory ReviewSummary.fromJson(Map<String, dynamic> json) {
    return ReviewSummary(
      sum: (json['sum'] as num?)?.toDouble() ?? 0,
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {'sum': sum, 'count': count};

  /// Pure transition: remove [oldRating] (change/delete), add [newRating]
  /// (change/create). Null on both sides = no-op.
  static ReviewSummary apply({
    required ReviewSummary current,
    int? oldRating,
    int? newRating,
  }) {
    var sum = current.sum;
    var count = current.count;
    if (oldRating != null) {
      sum -= oldRating;
      count -= 1;
    }
    if (newRating != null) {
      sum += newRating;
      count += 1;
    }
    if (count <= 0) return const ReviewSummary();
    return ReviewSummary(sum: sum < 0 ? 0 : sum, count: count);
  }
}
