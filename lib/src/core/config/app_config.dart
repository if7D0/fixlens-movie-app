import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized runtime configuration (locked Phase 1).
///
/// Token resolution order:
/// 1. `--dart-define=TMDB_READ_TOKEN=...` (recommended for CI / demo key)
/// 2. `.env` file (`TMDB_READ_TOKEN=...`, local only, never committed)
/// 3. Demo placeholder -> app runs in "demo mode" ([isConfigured] == false).
abstract final class AppConfig {
  static const _dartDefineKey = 'TMDB_READ_TOKEN';
  static const String _demoToken = 'DEMO_TOKEN_REPLACE_ME';

  static String get tmdbReadToken {
    const fromDefine = String.fromEnvironment(_dartDefineKey);
    if (fromDefine.isNotEmpty) return fromDefine;
    if (dotenv.isInitialized) {
      return dotenv.env['TMDB_READ_TOKEN'] ?? _demoToken;
    }
    return _demoToken;
  }

  static bool get isConfigured => tmdbReadToken != _demoToken;
}
