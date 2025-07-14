import 'package:flutter/material.dart';

// 2. 컬러 팔레트
class AppColors {
  // Neutral Gray 계열
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color grey50 = Color(0xFFF9F9F9);
  static const Color grey100 = Color(0xFFF2F2F2);

  // 텍스트
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textDisabled = Color(0xFF999999);

  // Primary Brand Color
  static const Color primary = Color(0xFF3A49FF);

  // Feedback Color
  static const Color success = Color(0xFF00C48C);
  static const Color warning = Color(0xFFFF9F43);
  static const Color error = Color(0xFFFF3B30);

  // 투명도 사용
  static Color primary20Opacity = primary.withOpacity(0.2);
  static Color overlay50Opacity = Colors.black.withOpacity(0.5);
}

// 3. 타이포그래피
class AppTextStyles {
  static const String _fontFamilyAppleSDGothicNeo = "Apple SD Gothic Neo";
  static const String _fontFamilySpoqaHanSans = "Spoqa Han Sans";

  static TextStyle _baseTextStyle({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.normal,
    Color color = AppColors.textPrimary,
  }) {
    // Calculate line height based on font-size * 1.5, minimum 24px
    final double lineHeight = (fontSize * 1.5) < 24 ? 24 / fontSize : 1.5;
    return TextStyle(
      fontFamily:
          _fontFamilySpoqaHanSans, // Prefer Spoqa Han Sans if available, otherwise system font
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: lineHeight,
    );
  }

  static TextStyle h1 = _baseTextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600, // SemiBold
  );

  static TextStyle h2 = _baseTextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w500, // Medium
  );

  static TextStyle body = _baseTextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400, // Regular
  );

  static TextStyle caption = _baseTextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400, // Regular
  );

  static TextStyle finePrint = _baseTextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400, // Regular
  );
}

// 4. 컴포넌트 스타일
ThemeData appTheme() {
  return ThemeData(
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.pureWhite,
    textTheme: TextTheme(
      displayLarge: AppTextStyles.h1, // H1
      displayMedium: AppTextStyles.h2, // H2
      bodyLarge: AppTextStyles.body, // Body
      bodyMedium: AppTextStyles.body, // Body
      bodySmall: AppTextStyles.caption, // Caption
      labelSmall: AppTextStyles.finePrint, // Fine Print
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style:
          ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.pureWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6.0),
            ),
            textStyle: AppTextStyles.body.copyWith(
              color: AppColors.pureWhite,
            ), // Ensure text style is consistent
            padding: EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ), // Default padding, adjust for sizes
          ).copyWith(
            // Sizes (Large, Medium, Small) - will need to be applied contextually or via custom widgets
            // For now, define a base style.
            minimumSize: MaterialStateProperty.resolveWith((states) {
              // This is a simplified approach. For specific sizes, custom widgets or more complex logic might be needed.
              // Assuming Medium size as default for theme.
              return Size(double.infinity, 40); // Medium (40px height)
            }),
            backgroundColor: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.disabled)) {
                return AppColors.grey100; // Disabled background
              }
              if (states.contains(MaterialState.hovered)) {
                return AppColors.primary.withOpacity(0.9); // Hover
              }
              if (states.contains(MaterialState.pressed)) {
                return AppColors.primary.withOpacity(0.8); // Pressed
              }
              return AppColors.primary;
            }),
            foregroundColor: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.disabled)) {
                return AppColors.pureWhite.withOpacity(0.5); // Disabled text
              }
              return AppColors.pureWhite;
            }),
          ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary, // Action text, links
        textStyle: AppTextStyles.body.copyWith(color: AppColors.primary),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      floatingLabelBehavior: FloatingLabelBehavior.auto, // Floating label
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(
          color: Color(0xFFE0E0E0),
          width: 1.0,
        ), // Default 1px #E0E0E0
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(
          color: AppColors.primary,
          width: 2.0,
        ), // Focus 2px Primary
      ),
      filled: true,
      fillColor: AppColors.pureWhite, // Default background
      hoverColor: AppColors.grey50, // Hover background
      contentPadding: EdgeInsets.symmetric(
        vertical: 12.0,
        horizontal: 0,
      ), // Adjust padding
      labelStyle: AppTextStyles.body.copyWith(
        color: AppColors.textSecondary,
      ), // Label style
      hintStyle: AppTextStyles.body.copyWith(
        color: AppColors.textDisabled,
      ), // Hint style
    ),
    cardTheme: CardThemeData(
      color: AppColors.pureWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0), // 12px rounded
      ),
      elevation: 2,
      shadowColor: Color(0x10000000), // #00000010
      margin: EdgeInsets.zero, // Remove default margin
    ),
    // 1. 그리드 & 레이아웃 - 8pt 기반 그리드 (Padding, Margin, etc. will be applied contextually)
    // VisualDensity.adaptivePlatformDensity, // Already there, good for responsive UI
  );
}
