import 'package:flutter/material.dart';

/// ラキカラの配色。
///
/// 淡いがくすませない色を4系統。パーソナルカラー4分類の印象とも揃えてある。
/// 主対象が女子高生なので、彩度は落としつつ色数で楽しさを出す方針。
abstract final class AppColors {
  /// 主役のピンク。ボタンと見出しに使う。
  static const Color blush = Color(0xFFFF8FA8);
  static const Color blushSoft = Color(0xFFFFE6EC);

  static const Color lavender = Color(0xFFA99BE0);
  static const Color lavenderSoft = Color(0xFFEEE9FB);

  static const Color mint = Color(0xFF7FD3BA);
  static const Color mintSoft = Color(0xFFDFF4EE);

  static const Color butter = Color(0xFFFFC978);
  static const Color butterSoft = Color(0xFFFFF0D9);

  /// 文字色。真っ黒だと硬いので、赤みを含んだ濃いグレーにする。
  static const Color ink = Color(0xFF4B3A43);
  static const Color inkMuted = Color(0xFF9C8B95);

  static const Color surface = Color(0xFFFFFDFD);
  static const Color line = Color(0xFFF0E6EB);

  /// 画面全体の背景。上がほんのりピンク、下がラベンダー。
  static const List<Color> backgroundGradient = [
    Color(0xFFFFF6F9),
    Color(0xFFF4F0FC),
  ];

  /// 4つのアクセント色。カードやアイコンを色分けするときに順に使う。
  static const List<Color> accents = [blush, butter, mint, lavender];
  static const List<Color> accentsSoft = [
    blushSoft,
    butterSoft,
    mintSoft,
    lavenderSoft,
  ];
}

/// 角丸と余白の基準値。画面ごとにバラバラの数値を書かないための置き場。
abstract final class AppRadius {
  static const double card = 24;
  static const double chip = 16;
  static const double pill = 999;
}

/// アプリ全体のテーマ。
///
/// 端末の既定フォントに任せると印象がぶれるので、丸ゴシックを同梱して固定する。
ThemeData buildAppTheme() {
  const fontFamily = 'MPLUSRounded1c';

  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.blush,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.blush,
    onPrimary: Colors.white,
    primaryContainer: AppColors.blushSoft,
    onPrimaryContainer: AppColors.ink,
    secondary: AppColors.lavender,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.lavenderSoft,
    onSecondaryContainer: AppColors.ink,
    tertiary: AppColors.mint,
    tertiaryContainer: AppColors.mintSoft,
    surface: AppColors.surface,
    onSurface: AppColors.ink,
    outlineVariant: AppColors.line,
  );

  TextStyle text(double size, FontWeight weight, {double height = 1.5, Color? color}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: weight,
      height: height,
      color: color ?? AppColors.ink,
      letterSpacing: 0.2,
    );
  }

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    fontFamily: fontFamily,
    // グラデーションは GradientBackground が body に描く。
    // ここを透明にすると AppBar の裏に何も無くなって黒く抜けるので、
    // グラデーションの上端と同じ色を敷いて継ぎ目を消す。
    scaffoldBackgroundColor: AppColors.backgroundGradient.first,
    textTheme: TextTheme(
      displaySmall: text(34, FontWeight.w700, height: 1.25),
      headlineMedium: text(26, FontWeight.w700, height: 1.3),
      headlineSmall: text(22, FontWeight.w700, height: 1.35),
      titleLarge: text(19, FontWeight.w700),
      titleMedium: text(16, FontWeight.w700),
      bodyLarge: text(15.5, FontWeight.w400, height: 1.7),
      bodyMedium: text(14, FontWeight.w400, height: 1.7),
      bodySmall: text(12.5, FontWeight.w400, height: 1.6, color: AppColors.inkMuted),
      labelLarge: text(15, FontWeight.w700),
      labelMedium: text(13, FontWeight.w700),
      labelSmall: text(11.5, FontWeight.w700, color: AppColors.inkMuted),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      foregroundColor: AppColors.ink,
      titleTextStyle: text(18, FontWeight.w700),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        backgroundColor: AppColors.blush,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.blushSoft,
        disabledForegroundColor: AppColors.inkMuted,
        elevation: 0,
        textStyle: text(16, FontWeight.w700, color: Colors.white),
        shape: const StadiumBorder(),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: AppColors.line, width: 1.5),
        backgroundColor: Colors.white.withValues(alpha: 0.7),
        textStyle: text(15, FontWeight.w700),
        shape: const StadiumBorder(),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.blushSoft,
      side: BorderSide.none,
      labelStyle: text(12.5, FontWeight.w700),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.blush,
      linearTrackColor: AppColors.blushSoft,
      linearMinHeight: 8,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.ink,
      contentTextStyle: text(14, FontWeight.w400, color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
