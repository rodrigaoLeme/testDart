import 'package:flutter/material.dart';
import 'package:seven_chat_app/share/utils/app_text_styles.dart';
import '../../share/utils/app_colors.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.darkBlue,
        primaryColor: AppColors.primary,
        fontFamily: 'Poppins',
        textTheme: const TextTheme(
          bodyLarge: AppTextStyles.body,
          bodyMedium: AppTextStyles.subtitle,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.lightBlue,
          border: OutlineInputBorder(
            borderSide: const BorderSide(color: AppColors.lightBlue),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          // ignore: deprecated_member_use
          background: AppColors.darkBlue,
          surface: AppColors.darkBlue,
        ),
      );
}
