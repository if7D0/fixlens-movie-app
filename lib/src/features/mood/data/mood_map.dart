// v1 mood→genre mapping table for the mood quiz (locked by plan).
//
// WARNING: values are best-effort defaults, NOT user-validated.
// Revisit after the 5-user test (PRD open question). All display labels
// live here as the single source (l10n-ready later).

/// Q1: current mood.
class MoodChoice {
  final String id;
  final String label;
  final String emoji;
  final List<int> genreIds;
  final String tone;
  final String? releaseDateLte;

  const MoodChoice({
    required this.id,
    required this.label,
    required this.emoji,
    required this.genreIds,
    required this.tone,
    this.releaseDateLte,
  });
}

const List<MoodChoice> moods = [
  MoodChoice(
    id: 'santai',
    label: 'Santai',
    emoji: '😌',
    genreIds: [35, 16, 10751],
    tone: 'Ringan dan menenangkan',
  ),
  MoodChoice(
    id: 'tertawa',
    label: 'Tertawa',
    emoji: '😂',
    genreIds: [35],
    tone: 'Lucu dan menghibur',
  ),
  MoodChoice(
    id: 'tegang',
    label: 'Tegang',
    emoji: '😬',
    genreIds: [53, 80, 9648],
    tone: 'Penuh ketegangan',
  ),
  MoodChoice(
    id: 'sedih',
    label: 'Sedih',
    emoji: '😢',
    genreIds: [18],
    tone: 'Menyentuh dan emosional',
  ),
  MoodChoice(
    id: 'romantis',
    label: 'Romantis',
    emoji: '🥰',
    genreIds: [10749, 18],
    tone: 'Hangat dan romantis',
  ),
  MoodChoice(
    id: 'nostalgia',
    label: 'Nostalgia',
    emoji: '🕰️',
    genreIds: [12, 18],
    tone: 'Klasik penuh kenangan',
    releaseDateLte: '2010-12-31',
  ),
  MoodChoice(
    id: 'penasaran',
    label: 'Penasaran',
    emoji: '🤔',
    genreIds: [9648, 878, 99],
    tone: 'Misterius dan bikin mikir',
  ),
  MoodChoice(
    id: 'semangat',
    label: 'Semangat',
    emoji: '🔥',
    genreIds: [28, 12],
    tone: 'Penuh aksi dan energi',
  ),
];

/// Q2: viewing company modifier.
class CompanyChoice {
  final String id;
  final String label;
  final String emoji;
  final String companyLabel;
  final List<int> bonusGenres;
  final Set<int> excludeGenres;
  final int minVotes;

  const CompanyChoice({
    required this.id,
    required this.label,
    required this.emoji,
    required this.companyLabel,
    this.bonusGenres = const [],
    this.excludeGenres = const {},
    this.minVotes = 100,
  });
}

const List<CompanyChoice> companies = [
  CompanyChoice(
    id: 'solo',
    label: 'Sendiri',
    emoji: '🧍',
    companyLabel: 'sendirian',
  ),
  CompanyChoice(
    id: 'pasangan',
    label: 'Pasangan',
    emoji: '💑',
    companyLabel: 'berdua',
    bonusGenres: [10749],
  ),
  CompanyChoice(
    id: 'keluarga',
    label: 'Keluarga',
    emoji: '👨‍👩‍👧',
    companyLabel: 'bareng keluarga',
    excludeGenres: {27},
    minVotes: 200,
  ),
  CompanyChoice(
    id: 'teman',
    label: 'Teman',
    emoji: '🧑‍🤝‍🧑',
    companyLabel: 'bareng teman',
    bonusGenres: [35, 28],
  ),
];

/// Q3: available time.
class DurationChoice {
  final String id;
  final String label;
  final String emoji;
  final String durationLabel;
  final int? runtimeLte;
  final int? runtimeGte;

  const DurationChoice({
    required this.id,
    required this.label,
    required this.emoji,
    required this.durationLabel,
    this.runtimeLte,
    this.runtimeGte,
  });
}

const List<DurationChoice> durations = [
  DurationChoice(
    id: 'cepat',
    label: 'Santai (< 100 mnt)',
    emoji: '☕',
    durationLabel: '< 100 menit',
    runtimeLte: 100,
  ),
  DurationChoice(
    id: 'standar',
    label: 'Standar (2 jam)',
    emoji: '🍿',
    durationLabel: 'sekitar 2 jam',
    runtimeGte: 80,
    runtimeLte: 150,
  ),
  DurationChoice(
    id: 'bebas',
    label: 'Bebas',
    emoji: '🌙',
    durationLabel: 'durasi bebas',
  ),
];

/// Resolved discover request from 3 answers.
class QuizRequest {
  final List<int> genreIds;
  final double minRating;
  final int minVotes;
  final int? runtimeLte;
  final int? runtimeGte;
  final String? releaseDateLte;
  final String tone;
  final String companyLabel;
  final String durationLabel;

  const QuizRequest({
    required this.genreIds,
    required this.minRating,
    required this.minVotes,
    required this.runtimeLte,
    required this.runtimeGte,
    required this.releaseDateLte,
    required this.tone,
    required this.companyLabel,
    required this.durationLabel,
  });
}

/// Resolves answers into a discover request. Unknown ids fall back to
/// neutral defaults instead of throwing.
QuizRequest buildRequest({
  required String moodId,
  required String companyId,
  required String durationId,
}) {
  final mood = _findMood(moodId);
  final company = _findCompany(companyId);
  final duration = _findDuration(durationId);

  final genres = <int>[
    ...mood.genreIds,
    ...company.bonusGenres.where((g) => !mood.genreIds.contains(g)),
  ].where((g) => !company.excludeGenres.contains(g)).take(3).toList();

  return QuizRequest(
    genreIds: genres,
    minRating: 6.5,
    minVotes: company.minVotes,
    runtimeLte: duration.runtimeLte,
    runtimeGte: duration.runtimeGte,
    releaseDateLte: mood.releaseDateLte,
    tone: mood.tone,
    companyLabel: company.companyLabel,
    durationLabel: duration.durationLabel,
  );
}

MoodChoice _findMood(String id) {
  for (final m in moods) {
    if (m.id == id) return m;
  }
  return const MoodChoice(
    id: 'netral',
    label: 'Netral',
    emoji: '🎬',
    genreIds: [],
    tone: 'Populer dan seru',
  );
}

CompanyChoice _findCompany(String id) {
  for (final c in companies) {
    if (c.id == id) return c;
  }
  return companies.first;
}

DurationChoice _findDuration(String id) {
  for (final d in durations) {
    if (d.id == id) return d;
  }
  return durations.last;
}

/// Deterministic match reason (no AI): tone + company + duration + rating.
String buildReason({
  required String tone,
  required String companyLabel,
  required String durationLabel,
  required double voteAverage,
}) {
  return '$tone buat $companyLabel • $durationLabel • '
      'rating ${voteAverage.toStringAsFixed(1)}';
}
