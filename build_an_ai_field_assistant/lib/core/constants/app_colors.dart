import 'package:flutter/material.dart';

/// App-wide curated clean modern enterprise color palette (Light / Clean Slate)
class AppColors {
  AppColors._();

  // Backgrounds & Surfaces (Clean Industrial Slate & Pure White)
  static const Color background = Color(0xFFF8FAFC); // Slate 50 (Sáng dịu mắt, chống chói)
  static const Color surface = Color(0xFFFFFFFF); // Pure White (Thẻ Card phẳng, sạch)
  static const Color surfaceLight = Color(0xFFF1F5F9); // Slate 100 (Background ô nhập liệu)
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE2E8F0); // Slate 200 (Đường viền mảnh, tinh tế)

  // Brand Accents (Deep Emerald / Sky Blue Enterprise)
  static const Color primary = Color(0xFF059669); // Emerald 600 (Đậm đà, sắc nét trên nền sáng)
  static const Color primaryLight = Color(0xFF10B981); // Emerald 500
  static const Color primaryDark = Color(0xFF047857); // Emerald 700
  static const Color secondary = Color(0xFF0284C7); // Sky 600
  static const Color accent = Color(0xFF4F46E5); // Indigo 600

  // Text Colors (High Contrast for Outdoor/Field Readability)
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900 (Đen than chì, cực kỳ dễ đọc)
  static const Color textSecondary = Color(0xFF475569); // Slate 600 (Xám trung tính chuẩn)
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400 (Hint text / Icon mờ)

  // Ticket Priority Colors
  static const Color priorityCritical = Color(0xFFDC2626); // Red 600
  static const Color priorityCriticalBg = Color(0xFFFEF2F2); // Red 50
  static const Color priorityHigh = Color(0xFFEA580C); // Orange 600
  static const Color priorityHighBg = Color(0xFFFFF7ED); // Orange 50
  static const Color priorityMedium = Color(0xFFD97706); // Amber 600
  static const Color priorityMediumBg = Color(0xFFFFFBEB); // Amber 50
  static const Color priorityLow = Color(0xFF16A34A); // Green 600
  static const Color priorityLowBg = Color(0xFFF0FDF4); // Green 50

  // Status & Synchronization
  static const Color statusSynced = Color(0xFF16A34A);
  static const Color statusPending = Color(0xFFD97706);
  static const Color statusDraft = Color(0xFF64748B);
  static const Color success = Color(0xFF16A34A);
  static const Color error = Color(0xFFDC2626);

  // Waveform & Recording State
  static const Color recordingActive = Color(0xFFDC2626);
  static const Color recordingGlow = Color(0x33DC2626);
  static const Color waveBar = Color(0xFF059669);
}
