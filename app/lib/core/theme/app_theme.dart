import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// design.md 토큰으로 구성한 앱 테마. 다크모드는 v1 비범위(밝은 베이스 고정).
abstract final class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    fontFamily: AppTypography.fontFamily,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      error: AppColors.danger,
      surface: AppColors.bgBase,
    ),
    scaffoldBackgroundColor: AppColors.bgBase,
    dividerColor: AppColors.borderDefault,
    textTheme: const TextTheme(
      displaySmall: AppTypography.display,
      headlineMedium: AppTypography.h1,
      headlineSmall: AppTypography.h2,
      titleMedium: AppTypography.title,
      bodyMedium: AppTypography.body,
      labelLarge: AppTypography.bodyStrong,
      bodySmall: AppTypography.caption,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.bgBase,
        minimumSize: const Size.fromHeight(AppSpacing.touchTarget),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        textStyle: AppTypography.bodyStrong,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.bgElevated,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: const BorderSide(color: AppColors.borderDefault),
      ),
    ),
  );
}
