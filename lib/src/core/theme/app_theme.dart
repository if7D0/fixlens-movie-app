import 'package:flutter/material.dart';

/// FixLens cinematic OLED design system (ui-ux-pro-max verified).
///
/// - Style: `dark-mode-oled` + cinematic layered depth
/// - Palette: deep bg `#0B0B14`, card `#1B1B30`, muted `#27273B`,
///   muted-text `#9AA3B2`, brand violet `#6C4CF1`, mood CTA `#F97316`,
///   rating amber `#FBBF24`
/// - Type: display-bold (Righteous role) + body-medium (Poppins role)
///   mapped onto system weights so no extra font dependency is needed.
/// - Rhythm: 4/8dp spacing, 12/14/16/20 radii, 48dp min touch targets.
abstract final class AppTheme {
  static const _seed = Color(0xFF6C4CF1);

  static ThemeData get dark {
    var scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    );
    scheme = scheme.copyWith(
      primary: const Color(0xFF8B7CFF),
      onPrimary: Colors.white,
      secondary: const Color(0xFFA5B4FC),
      onSecondary: const Color(0xFF0F0F23),
      tertiary: AppColors.accent,
      onTertiary: const Color(0xFF0F0F23),
      surface: AppColors.background,
      onSurface: const Color(0xFFF8FAFC),
      surfaceContainerLowest: const Color(0xFF08080F),
      surfaceContainerLow: const Color(0xFF12121E),
      surfaceContainer: AppColors.card,
      surfaceContainerHigh: AppColors.muted,
      surfaceContainerHighest: const Color(0xFF2E2E48),
      outlineVariant: const Color(0xFF34344E),
      error: const Color(0xFFEF4444),
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    final text = base.textTheme.copyWith(
      displaySmall: base.textTheme.displaySmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: scheme.onSurface,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
        color: scheme.onSurface,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: scheme.onSurface,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: scheme.onSurface,
      ),
      titleSmall: base.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w400,
        color: scheme.onSurface,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        color: const Color(0xFFD6DBE5),
      ),
      bodySmall: base.textTheme.bodySmall?.copyWith(
        color: AppColors.mutedText,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      labelSmall: base.textTheme.labelSmall?.copyWith(
        color: AppColors.mutedText,
        letterSpacing: 0.2,
      ),
    );

    return base.copyWith(
      textTheme: text,
      scaffoldBackgroundColor: AppColors.background,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(fontSize: 20),
        iconTheme: const IconThemeData(color: Color(0xFFF8FAFC)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF12121E),
        indicatorColor: _seed.withValues(alpha: 0.30),
        labelTextStyle: WidgetStatePropertyAll(
          text.labelSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Colors.white, size: 24);
          }
          return const IconThemeData(color: Color(0xFF9AA3B2), size: 24);
        }),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: const BorderSide(color: Color(0xFF2A2A42)),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.muted,
        selectedColor: _seed.withValues(alpha: 0.30),
        secondarySelectedColor: _seed.withValues(alpha: 0.30),
        labelStyle: text.labelLarge?.copyWith(fontSize: 13),
        secondaryLabelStyle: text.labelLarge?.copyWith(
          fontSize: 13,
          color: Colors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.full),
          side: const BorderSide(color: Color(0xFF34344E)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _seed,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 48),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: const Color(0xFF0F0F23),
          minimumSize: const Size(48, 48),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFF8FAFC),
          minimumSize: const Size(48, 48),
          side: const BorderSide(color: Color(0xFF4A4A68)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFFA5B4FC),
          minimumSize: const Size(48, 44),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      searchBarTheme: SearchBarThemeData(
        backgroundColor: const WidgetStatePropertyAll(AppColors.card),
        elevation: const WidgetStatePropertyAll(0),
        side: const WidgetStatePropertyAll(
          BorderSide(color: Color(0xFF2A2A42)),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.full),
          ),
        ),
        hintStyle: WidgetStatePropertyAll(
          text.bodyMedium?.copyWith(color: AppColors.mutedText),
        ),
      ),
      sliderTheme: base.sliderTheme.copyWith(
        activeTrackColor: AppColors.accent,
        thumbColor: AppColors.accent,
        inactiveTrackColor: AppColors.muted,
        valueIndicatorColor: AppColors.accent,
        valueIndicatorTextStyle: const TextStyle(
          color: Color(0xFF0F0F23),
          fontWeight: FontWeight.w700,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
        linearTrackColor: AppColors.muted,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF23233A),
        contentTextStyle: text.bodyMedium?.copyWith(color: Colors.white),
        actionTextColor: AppColors.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF23233A),
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        minVerticalPadding: 8,
        titleTextStyle: text.titleSmall,
        subtitleTextStyle: text.bodySmall,
        iconColor: AppColors.mutedText,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF151522),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        showDragHandle: true,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF151522),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      badgeTheme: const BadgeThemeData(
        backgroundColor: AppColors.accent,
        textColor: Color(0xFF0F0F23),
      ),
    );
  }
}

/// Semantic color tokens. Always read via `Theme.of(context).colorScheme`
/// first; use these only for brand moments the scheme cannot express
/// (rating amber, mood CTA gradient, cinematic scrims).
abstract final class AppColors {
  static const background = Color(0xFF0B0B14);
  static const card = Color(0xFF1B1B30);
  static const muted = Color(0xFF27273B);
  static const mutedText = Color(0xFF9AA3B2);
  static const accent = Color(0xFFF97316);
  static const accentDeep = Color(0xFFEA580C);
  static const rating = Color(0xFFFBBF24);
  static const success = Color(0xFF22C55E);
  static const brandViolet = Color(0xFF6C4CF1);
  static const brandVioletLight = Color(0xFF8B7CFF);

  static const moodGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6C4CF1), Color(0xFF9333EA), Color(0xFFF97316)],
  );
  static const heroScrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Color(0xCC0B0B14), Color(0xFF0B0B14)],
  );
  static const cardScrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Color(0xB3000000)],
  );
}

/// Spacing rhythm (4/8dp), radii, motion tokens.
abstract final class AppRadii {
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 14.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const full = 999.0;
}

abstract final class AppMotion {
  static const fast = Duration(milliseconds: 150);
  static const medium = Duration(milliseconds: 250);
  static const slow = Duration(milliseconds: 350);
}
