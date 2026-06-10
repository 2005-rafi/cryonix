import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'app_custom_colors.dart';

class AppTheme {
  final TextTheme textTheme;

  const AppTheme(this.textTheme);

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff320034),
      surfaceTint: Color(0xff844981),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff4b164c),
      onPrimaryContainer: Color(0xffffdcf8),
      secondary: Color(0xff510a4d),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff742c6d),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff332934),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff514651),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff600004),
      onError: Color(0xffffffff),
      errorContainer: Color(0xff98000a),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfffcf8f8),
      onSurface: Color(0xff000000),
      onSurfaceVariant: Color(0xff000000),
      outline: Color(0xff292d2d),
      outlineVariant: Color(0xff464a4a),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff313030),
      inversePrimary: Color(0xfff6afef),
      primaryFixed: Color(0xff6c346b),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff521d52),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff742c6d),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff591355),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff514651),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff3a2f3a),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffbbb8b7),
      surfaceBright: Color(0xfffcf8f8),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff4f0ef),
      surfaceContainer: Color(0xffe5e2e1),
      surfaceContainerHigh: Color(0xffd7d4d3),
      surfaceContainerHighest: Color(0xffc9c6c5),
    );
  }

  ThemeData light() {
    return theme(lightScheme());
  }

  ThemeData dark() {
    return theme(darkScheme());
  }

  static ThemeData get lightTheme => AppTheme(Typography.material2021().black).light();
  static ThemeData get darkTheme => AppTheme(Typography.material2021().white).dark();

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffffeaf9),
      surfaceTint: Color(0xfff6afef),
      onPrimary: Color(0xff000000),
      primaryContainer: Color(0xfff2aceb),
      onPrimaryContainer: Color(0xff1c001e),
      secondary: Color(0xffffeaf7),
      onSecondary: Color(0xff000000),
      secondaryContainer: Color(0xfffea5ee),
      onSecondaryContainer: Color(0xff1d001b),
      tertiary: Color(0xffffffff),
      onTertiary: Color(0xff000000),
      tertiaryContainer: Color(0xffeedeec),
      onTertiaryContainer: Color(0xff312732),
      error: Color(0xffffece9),
      onError: Color(0xff000000),
      errorContainer: Color(0xffffaea4),
      onErrorContainer: Color(0xff220001),
      surface: Color(0xff141313),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffffffff),
      outline: Color(0xffeef0f1),
      outlineVariant: Color(0xffc0c3c4),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe5e2e1),
      inversePrimary: Color(0xff6a3369),
      primaryFixed: Color(0xffffd6f8),
      onPrimaryFixed: Color(0xff000000),
      primaryFixedDim: Color(0xfff6afef),
      onPrimaryFixedVariant: Color(0xff260028),
      secondaryFixed: Color(0xffffd7f4),
      onSecondaryFixed: Color(0xff000000),
      secondaryFixedDim: Color(0xffffabef),
      onSecondaryFixedVariant: Color(0xff270025),
      tertiaryFixed: Color(0xffeedeec),
      onTertiaryFixed: Color(0xff000000),
      tertiaryFixedDim: Color(0xffd2c2d0),
      onTertiaryFixedVariant: Color(0xff170e18),
      surfaceDim: Color(0xff141313),
      surfaceBright: Color(0xff51504f),
      surfaceContainerLowest: Color(0xff000000),
      surfaceContainerLow: Color(0xff201f1f),
      surfaceContainer: Color(0xff313030),
      surfaceContainerHigh: Color(0xff3c3b3b),
      surfaceContainerHighest: Color(0xff474646),
    );
  }

  ThemeData theme(ColorScheme colorScheme) => ThemeData(
    useMaterial3: true,
    splashFactory: InkRipple.splashFactory,
    brightness: colorScheme.brightness,
    colorScheme: colorScheme,
    extensions: [
      colorScheme.brightness == Brightness.light
          ? AppCustomColors.light
          : AppCustomColors.dark,
    ],
    textTheme: textTheme.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    ),
    scaffoldBackgroundColor: colorScheme.surfaceContainerLow,
    canvasColor: colorScheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surfaceContainer,
      foregroundColor: colorScheme.onSurface,
      scrolledUnderElevation: AppElevation.flat,
      elevation: AppElevation.flat,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: colorScheme.surfaceContainer,
      elevation: AppElevation.flat,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.lg,
        side: BorderSide(color: colorScheme.outlineVariant, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerLowest,
      border: OutlineInputBorder(borderRadius: AppRadius.md),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.md,
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.md,
        borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: colorScheme.surfaceContainerHigh,
      selectedColor: colorScheme.secondaryContainer,
      secondarySelectedColor: colorScheme.secondaryContainer,
      labelStyle: textTheme.labelMedium?.copyWith(color: colorScheme.onSurface),
      secondaryLabelStyle: textTheme.labelMedium?.copyWith(
        color: colorScheme.onSecondaryContainer,
      ),
      deleteIconColor: colorScheme.onSurfaceVariant,
      checkmarkColor: colorScheme.onSecondaryContainer,
      side: BorderSide(color: colorScheme.outlineVariant),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.sm),
    ),
    listTileTheme: ListTileThemeData(
      textColor: colorScheme.onSurface,
      iconColor: colorScheme.onSurfaceVariant,
      selectedColor: colorScheme.onSecondaryContainer,
      selectedTileColor: colorScheme.secondaryContainer.withAlpha(90),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, AppLayout.minButtonHeight),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, AppLayout.minButtonHeight),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(0, AppLayout.minButtonHeight),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
      },
    ),
  );

  List<ExtendedColor> get extendedColors => [];
}

class ExtendedColor {
  final Color seed, value;
  final ColorFamily light;
  final ColorFamily lightHighContrast;
  final ColorFamily lightMediumContrast;
  final ColorFamily dark;
  final ColorFamily darkHighContrast;
  final ColorFamily darkMediumContrast;

  const ExtendedColor({
    required this.seed,
    required this.value,
    required this.light,
    required this.lightHighContrast,
    required this.lightMediumContrast,
    required this.dark,
    required this.darkHighContrast,
    required this.darkMediumContrast,
  });
}

class ColorFamily {
  const ColorFamily({
    required this.color,
    required this.onColor,
    required this.colorContainer,
    required this.onColorContainer,
  });

  final Color color;
  final Color onColor;
  final Color colorContainer;
  final Color onColorContainer;
}
