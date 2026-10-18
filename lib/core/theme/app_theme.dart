import 'package:flutter/material.dart';

/// Canonical app theme.
///
/// Use [AppTheme] in new code. The [Default_Theme] typedef at the bottom of
/// this file provides backward-compatible access for existing callers while
/// imports are being migrated.
class AppTheme {
  // ── Text Styles ─────────────────────────────────────────────────────────────
  static const primaryTextStyle = TextStyle(fontFamily: "Fjalla");
  static const secondoryTextStyle = TextStyle(fontFamily: "Gilroy");
  static const secondoryTextStyleMedium =
      TextStyle(fontFamily: "Gilroy", fontWeight: FontWeight.w700);
  static const tertiaryTextStyle = TextStyle(fontFamily: "CodePro");
  static const fontAwesomeRegularFont =
      TextStyle(fontFamily: "FontAwesome-Regular");
  static const fontAwesomeSolidFont =
      TextStyle(fontFamily: "FontAwesome-Solids");

  // ── Colors ──────────────────────────────────────────────────────────────────
  /// Pure black for Dark OLED theme (true #000000 black)
  static const oledThemeColor = Color(0xFF000000);
  /// Classic dark theme background (faint midnight purple)
  static const classicThemeColor = Color(0xFF0A040C);

  /// Default theme color out of the box is Pure OLED Black.
  static const themeColor = oledThemeColor;
  static const primaryColor1 = Color(0xFFDAEAF7);
  static const primaryColor2 = Color.fromARGB(255, 242, 231, 240);
  static const accentColor1 = Color(0xFF0EA5E0);
  static const accentColor1light = Color(0xFF18C9ED);
  static const accentColor2 = Color(0xFFFE385E);
  static const successColor = Color(0xFF5EFF43);

  // ── Theme Data ───────────────────────────────────────────────────────────────
  ThemeData get defaultThemeData => getThemeData(oled: true);

  static ThemeData getThemeData({bool oled = true}) {
    final bgColor = oled ? oledThemeColor : classicThemeColor;
    final surfaceContainer = oled ? const Color(0xFF0E0E0E) : const Color(0xFF1A111B);
    final popupBg = oled ? const Color(0xFF121212) : const Color.fromARGB(255, 23, 18, 25);

    final darkScheme = ColorScheme.dark(
      primary: accentColor2,
      secondary: accentColor1,
      surface: bgColor,
      surfaceContainerHighest: surfaceContainer,
      onPrimary: primaryColor1,
      onSecondary: primaryColor1,
      onSurface: primaryColor1,
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bgColor,
      dialogBackgroundColor: bgColor,
      primaryColorDark: accentColor2,
      fontFamily: 'Gilroy',
      primarySwatch: MaterialColor(
        accentColor2.value,
        {
          50: accentColor2.withValues(alpha: 0.1),
          100: accentColor2.withValues(alpha: 0.2),
          200: accentColor2.withValues(alpha: 0.3),
          300: accentColor2.withValues(alpha: 0.4),
          400: accentColor2.withValues(alpha: 0.5),
          500: accentColor2.withValues(alpha: 0.6),
          600: accentColor2.withValues(alpha: 0.7),
          700: accentColor2.withValues(alpha: 0.8),
          800: accentColor2.withValues(alpha: 0.9),
          900: accentColor2,
        },
      ),
      colorScheme: darkScheme.copyWith(
        primary: accentColor2,
        secondary: accentColor2,
      ),
      iconTheme: const IconThemeData(color: primaryColor1),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(accentColor2),
        interactive: true,
        radius: const Radius.circular(10),
        thickness: WidgetStateProperty.all(5),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgColor,
        foregroundColor: primaryColor1,
        surfaceTintColor: bgColor,
        iconTheme: const IconThemeData(color: primaryColor1),
      ),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: accentColor2),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: accentColor2,
        selectionColor: accentColor2,
        selectionHandleColor: accentColor2,
      ),
      brightness: Brightness.dark,
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(primaryColor1),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? accentColor1
                : accentColor2),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? accentColor1
                : primaryColor2.withValues(alpha: 0.0)),
      ),
      searchBarTheme: SearchBarThemeData(
        backgroundColor: WidgetStatePropertyAll(bgColor),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: popupBg,
        textStyle: const TextStyle(color: primaryColor1),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(bgColor),
        ),
        textStyle: const TextStyle(color: primaryColor1),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(bgColor),
        ),
      ),
      cardTheme: CardThemeData(
        color: bgColor,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}

/// Backward-compat alias for [AppTheme].
/// Prefer importing from [core/theme/app_theme.dart] and using [AppTheme] directly.
// ignore: camel_case_types
typedef Default_Theme = AppTheme;
