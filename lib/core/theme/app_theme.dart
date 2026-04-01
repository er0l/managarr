import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../database/app_database.dart';
import 'app_colors.dart';

// ---------------------------------------------------------------------------
// Theme mode persistence
// ---------------------------------------------------------------------------

/// Loads theme mode from DB on app start; defaults to [ThemeMode.system].
final themeModeProvider =
    NotifierProvider<_ThemeModeNotifier, ThemeMode>(_ThemeModeNotifier.new);

class _ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    // Load persisted value asynchronously; keep system as default.
    _loadFromDb();
    return ThemeMode.system;
  }

  Future<void> _loadFromDb() async {
    final db = ref.read(dbProvider);
    final stored = await db.getSetting(_key);
    if (stored != null) {
      final mode = _fromString(stored);
      if (mode != state) {
        state = mode;
      }
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final db = ref.read(dbProvider);
    await db.setSetting(_key, _toString(mode));
  }

  static String _toString(ThemeMode m) => switch (m) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        _ => 'system',
      };

  static ThemeMode _fromString(String s) => switch (s) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
}

// ---------------------------------------------------------------------------
// Theme definitions
// ---------------------------------------------------------------------------

abstract final class AppTheme {
  static const _colors = FlexSchemeColor(
    primary:            AppColors.tealPrimary,
    primaryContainer:   AppColors.tealLight,
    secondary:          AppColors.orangeAccent,
    secondaryContainer: AppColors.orangeLight,
    tertiary:           AppColors.blueAccent,
  );

  static const _subThemes = FlexSubThemesData(
    cardRadius:                             16.0,
    inputDecoratorRadius:                   8.0,
    elevatedButtonRadius:                   100.0,
    filledButtonRadius:                     100.0,
    navigationBarIndicatorSchemeColor:      SchemeColor.primary,
    inputDecoratorBorderType:               FlexInputBorderType.outline,
    inputDecoratorUnfocusedBorderIsColored: false,
  );

  static ThemeData get light => FlexThemeData.light(
        colors: _colors,
        surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
        blendLevel: 4,
        subThemesData: _subThemes,
        textTheme: GoogleFonts.interTextTheme(),
        primaryTextTheme: GoogleFonts.interTextTheme(),
        appBarElevation: 0,
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        useMaterial3: true,
      );

  static ThemeData get dark => FlexThemeData.dark(
        colors: _colors,
        surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
        blendLevel: 8,
        subThemesData: _subThemes,
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        primaryTextTheme:
            GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        appBarElevation: 0,
        useMaterial3: true,
      );
}
