import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Explicit brand pairs prevent tonal controls inheriting an orange container
/// with a foreground intended for a different surface.
ThemeData applyBrandControlTheme(ThemeData theme) {
  final colors = theme.colorScheme;
  Color foreground(Set<WidgetState> states) =>
      states.contains(WidgetState.disabled)
      ? colors.onSurface.withAlpha(97)
      : AppColors.textOnPrimary;
  final chipLabelStyle = (theme.chipTheme.labelStyle ?? const TextStyle())
      .copyWith(
        color: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? colors.onSurface.withAlpha(97)
              : states.contains(WidgetState.selected)
              ? AppColors.textOnPrimary
              : colors.onSurface,
        ),
      );
  return theme.copyWith(
    navigationBarTheme: theme.navigationBarTheme.copyWith(
      indicatorColor: AppColors.tealPrimary,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? AppColors.textOnPrimary
              : colors.onSurfaceVariant,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => (theme.textTheme.labelMedium ?? const TextStyle()).copyWith(
          color: states.contains(WidgetState.selected)
              ? AppColors.tealPrimary
              : colors.onSurfaceVariant,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: (theme.filledButtonTheme.style ?? const ButtonStyle()).copyWith(
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? colors.surfaceContainerHighest
              : AppColors.tealPrimary,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(foreground),
        iconColor: WidgetStateProperty.resolveWith(foreground),
      ),
    ),
    chipTheme: theme.chipTheme.copyWith(
      color: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? colors.surfaceContainerHighest
            : states.contains(WidgetState.selected)
            ? AppColors.tealPrimary
            : Colors.transparent,
      ),
      selectedColor: AppColors.tealPrimary,
      backgroundColor: Colors.transparent,
      checkmarkColor: AppColors.textOnPrimary,
      secondarySelectedColor: AppColors.tealPrimary,
      labelStyle: chipLabelStyle,
      secondaryLabelStyle: chipLabelStyle,
    ),
  );
}
