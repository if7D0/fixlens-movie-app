import 'package:flutter/material.dart';

/// Dark cinema theme (locked Phase 1, Material3).
abstract final class AppTheme {
  static const _seed = Color(0xFF6C4CF1);

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF0E0E14),
      appBarTheme: const AppBarTheme(centerTitle: false),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF16161F),
        indicatorColor: _seed.withValues(alpha: 0.25),
      ),
    );
  }
}
