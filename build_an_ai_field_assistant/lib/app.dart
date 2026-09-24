import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_constants.dart';
import 'features/inspection/presentation/controllers/inspection_controller.dart';
import 'features/inspection/presentation/views/ticket_history_screen.dart';
import 'features/inspection/presentation/views/voice_capture_screen.dart';

/// Main Application Widget configuring Theme, Routes & Global Styling
class FieldAiAssistantApp extends StatelessWidget {
  final InspectionController controller;

  const FieldAiAssistantApp({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = ThemeData.dark().textTheme;

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primary,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
          error: AppColors.priorityCritical,
        ),
        cardTheme: CardThemeData(
          color: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.cardBorder),
          ),
          elevation: 0,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: AppColors.textPrimary),
          titleTextStyle: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        textTheme: GoogleFonts.interTextTheme(baseTextTheme).apply(
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => VoiceCaptureScreen(controller: controller),
        '/history': (context) => TicketHistoryScreen(controller: controller),
      },
    );
  }
}
