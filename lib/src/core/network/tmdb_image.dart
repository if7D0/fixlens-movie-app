/// TMDB image URL builder. Null/empty paths yield null so UI can fall
/// back to placeholders instead of broken images.
abstract final class TmdbImage {
  static const _base = 'https://image.tmdb.org/t/p';

  static String? poster(String? path) => _sized(path, 'w342');
  static String? backdrop(String? path) => _sized(path, 'w780');
  static String? still(String? path) => _sized(path, 'w500');
  static String? avatar(String? path) => _sized(path, 'w185');

  static String? _sized(String? path, String size) {
    if (path == null || path.isEmpty) return null;
    return '$_base/$size$path';
  }
}
