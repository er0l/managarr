import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../database/app_database.dart';
import 'app_colors.dart';

// ---------------------------------------------------------------------------
// Theme mode persistence
// ---------------------------------------------------------------------------

enum AppThemeMode {
  system('System'),
  light('Light'),
  dark('Dark'),
  amoled('Amoled');

  const AppThemeMode(this.label);
  final String label;
  ThemeMode get materialMode => switch (this) {
    AppThemeMode.system => ThemeMode.system,
    AppThemeMode.light => ThemeMode.light,
    _ => ThemeMode.dark,
  };
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, AppThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<AppThemeMode> {
  bool _edited = false;
  @override
  AppThemeMode build() {
    _load();
    return AppThemeMode.system;
  }

  Future<void> _load() async {
    final db = ref.read(dbProvider);
    final stored = await db.getSetting('appearance');
    final legacy = stored == null ? await db.getSetting('theme_mode') : null;
    if (_edited) return;
    // The former Dark palette is now named Amoled.
    final name = stored ?? (legacy == 'dark' ? 'amoled' : legacy);
    state =
        AppThemeMode.values.where((m) => m.name == name).firstOrNull ??
        AppThemeMode.system;
  }

  Future<void> setMode(AppThemeMode mode) async {
    _edited = true;
    state = mode;
    await ref.read(dbProvider).setSetting('appearance', mode.name);
  }
}

// ---------------------------------------------------------------------------
// Theme definitions
// ---------------------------------------------------------------------------

abstract final class AppTheme {
  /// Stronger heading hierarchy applied on top of the Inter text theme.
  static TextTheme _applyHierarchy(TextTheme t) => t.copyWith(
    titleLarge: t.titleLarge?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
    ),
    titleMedium: t.titleMedium?.copyWith(fontWeight: FontWeight.w600),
  );

  /// Flat cards with a subtle hairline border instead of elevation shadows.
  static CardThemeData _cardTheme(Color borderColor) => CardThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: borderColor),
    ),
  );

  static const _colors = FlexSchemeColor(
    primary: AppColors.tealPrimary,
    primaryContainer: AppColors.tealLight,
    secondary: AppColors.orangeAccent,
    secondaryContainer: AppColors.orangeLight,
    tertiary: AppColors.blueAccent,
  );

  static const _subThemes = FlexSubThemesData(
    cardRadius: 16.0,
    inputDecoratorRadius: 8.0,
    elevatedButtonRadius: 100.0,
    filledButtonRadius: 100.0,
    // Active nav indicator uses secondary (orange) instead of primary (teal).
    navigationBarIndicatorSchemeColor: SchemeColor.secondary,
    inputDecoratorBorderType: FlexInputBorderType.outline,
    inputDecoratorUnfocusedBorderIsColored: false,
  );

  static ThemeData get light => FlexThemeData.light(
    colors: _colors,
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    blendLevel: 4,
    subThemesData: _subThemes,
    textTheme: _applyHierarchy(GoogleFonts.interTextTheme()),
    primaryTextTheme: GoogleFonts.interTextTheme(),
    appBarElevation: 0,
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    useMaterial3: true,
  ).copyWith(cardTheme: _cardTheme(AppColors.divider));

  /// LunaSea Midnight surfaces, retaining managarr's accent colors.
  static ThemeData get dark {
    final base = amoled;
    const background = Color(0xFF32323E);
    const surface = Color(0xFF282834);
    const elevated = Color(0xFF3B3B49);
    const border = Color(0x24FFFFFF);
    return base.copyWith(
      scaffoldBackgroundColor: background,
      canvasColor: background,
      cardColor: surface,
      cardTheme: _cardTheme(border),
      dividerColor: border,
      dialogTheme: base.dialogTheme.copyWith(backgroundColor: surface),
      bottomSheetTheme: base.bottomSheetTheme.copyWith(
        backgroundColor: surface,
        modalBackgroundColor: surface,
      ),
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: surface,
        foregroundColor: Colors.white,
      ),
      navigationBarTheme: base.navigationBarTheme.copyWith(
        backgroundColor: surface,
      ),
      colorScheme: base.colorScheme.copyWith(
        surface: surface,
        surfaceContainer: elevated,
        surfaceContainerHighest: elevated,
        surfaceContainerLow: surface,
        surfaceContainerLowest: surface,
        surfaceContainerHigh: elevated,
        outlineVariant: border,
        onSurface: const Color(0xFFF2F2F5),
        onSurfaceVariant: const Color(0xFFBBBBBB),
      ),
    );
  }

  static ThemeData get amoled {
    final base = FlexThemeData.dark(
      colors: _colors,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 8,
      subThemesData: _subThemes,
      textTheme: _applyHierarchy(
        GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      ),
      primaryTextTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      appBarElevation: 0,
      useMaterial3: true,
    );
    // Apply v2 cinematic dark surface palette.
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.backgroundDark,
      cardColor: AppColors.surfaceCardDark,
      cardTheme: _cardTheme(AppColors.borderDark),
      dividerColor: AppColors.borderDark,
      navigationBarTheme: base.navigationBarTheme.copyWith(
        backgroundColor: AppColors.chromeDark,
      ),
      colorScheme: base.colorScheme.copyWith(
        surface: AppColors.surfaceCardDark,
        surfaceContainerHighest: AppColors.surfaceElevatedDark,
        surfaceContainer: AppColors.surfaceElevatedDark,
        outlineVariant: AppColors.borderDark,
        secondary: AppColors.orangeAccent,
        secondaryContainer: AppColors.orangeAccent.withAlpha(45),
      ),
    );
  }
}
