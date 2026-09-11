import 'package:hive_ce/hive_ce.dart';

import '../../../core/utils/app_log.dart';
import '../../discover/data/models/movie.dart';

/// Local watchlist persistence as JSON maps (no codegen).
/// Corrupt entries are skipped with a log instead of throwing.
class WatchlistRepository {
  WatchlistRepository(this._box);

  final Box _box;

  static String _key(int id) => 'm_$id';

  List<MovieSummary> items() {
    final dated = <({DateTime savedAt, MovieSummary movie})>[];
    for (final k in _box.keys) {
      try {
        final v = _box.get(k);
        if (v is! Map) continue;
        final map = Map<String, dynamic>.from(v);
        final savedAt =
            DateTime.tryParse('${map['savedAt']}') ?? DateTime(1970);
        dated.add((
          savedAt: savedAt,
          movie: MovieSummary.fromJson(map),
        ));
      } catch (e) {
        appLog('watchlist skip corrupt entry $k: $e');
      }
    }
    dated.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return [for (final d in dated) d.movie];
  }

  bool contains(int id) => _box.containsKey(_key(id));

  Future<void> save(MovieSummary movie) {
    return _box.put(_key(movie.id), {
      ...movie.toJson(),
      'savedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> remove(int id) => _box.delete(_key(id));
}
