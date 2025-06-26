import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// アプリで使用する色の定義
class AppColors {
  // ダークテーマ用の色
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color gold = Color(0xFFD4AF37); // メインのゴールドカラー
  static const Color goldLight = Color(0xFFFFD700); // より明るいゴールド
  static const Color gray = Color(0xFF333333);
  static const Color grayLight = Color(0xFF666666);
  
  // ライトテーマ（高級感）用の色
  static const Color luxuryBackground = Color(0xFFFFFFFF); // 純白
  static const Color luxuryText = Color(0xFF212121); // 濃いグレーに近い黒
  static const Color luxuryTextSecondary = Color(0xFF757575); // 薄いグレー
  static const Color luxuryDivider = Color(0xFFEEEEEE); // 非常に薄いグレー
  static const Color luxuryShadow = Color(0x0F000000); // 薄い影
}

class AppTheme {
  // 高級感のある白ベースのライトテーマ
  static ThemeData get luxuryTheme {
    return ThemeData(
      scaffoldBackgroundColor: AppColors.luxuryBackground,
      primaryColor: AppColors.gold,
      colorScheme: const ColorScheme.light(
        primary: AppColors.gold,
        secondary: AppColors.goldLight,
        surface: AppColors.luxuryBackground,
        onSurface: AppColors.luxuryText,
        error: Colors.redAccent,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.luxuryText,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.luxuryText,
          letterSpacing: -0.25,
        ),
        displaySmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.luxuryText,
        ),
        headlineMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.luxuryText,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: AppColors.luxuryText,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppColors.luxuryText,
        ),
      ),
      buttonTheme: const ButtonThemeData(
        buttonColor: AppColors.gold,
        textTheme: ButtonTextTheme.primary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.luxuryText,
          side: const BorderSide(color: AppColors.luxuryDivider),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: Colors.transparent,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        labelStyle: const TextStyle(
          color: AppColors.luxuryTextSecondary,
          fontSize: 14,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.luxuryDivider, width: 1),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.gold, width: 2),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.redAccent, width: 2),
        ),
        hintStyle: const TextStyle(color: AppColors.luxuryTextSecondary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.luxuryBackground,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: AppColors.luxuryText,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: AppColors.luxuryText),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.luxuryDivider,
        thickness: 1,
        space: 32,
      ),
      cardTheme: CardThemeData(
        color: AppColors.luxuryBackground,
        elevation: 0.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      ),
    );
  }
  
  // 既存のダークテーマ
  static ThemeData get darkTheme {
    return ThemeData(
      scaffoldBackgroundColor: AppColors.black,
      primaryColor: AppColors.gold,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.gold,
        secondary: AppColors.goldLight,
        surface: AppColors.black,
        // backgroundは非推奨なので削除し、surfaceを使用。ただしここでは既に設定済
        error: Colors.redAccent,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.white,
        ),
        displayMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.white,
        ),
        displaySmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
        ),
        headlineMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.white,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: AppColors.white,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppColors.white,
        ),
      ),
      buttonTheme: const ButtonThemeData(
        buttonColor: AppColors.gold,
        textTheme: ButtonTextTheme.primary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: AppColors.black,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: UnderlineInputBorder(
          borderSide: const BorderSide(color: AppColors.grayLight, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: const BorderSide(color: AppColors.grayLight, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: const BorderSide(color: AppColors.gold, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        labelStyle: const TextStyle(color: AppColors.white),
        hintStyle: TextStyle(color: AppColors.white.withAlpha(128)), // 0.5の透明度 = 128 (255 * 0.5)
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.black,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
    );
  }
}
