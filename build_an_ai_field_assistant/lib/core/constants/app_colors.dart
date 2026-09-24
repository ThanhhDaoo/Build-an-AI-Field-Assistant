import 'package:flutter/material.dart';

/// App-wide curated industrial dark/light modern color palette
class AppColors {
  AppColors._();

  // Backgrounds & Surfaces (Industrial Slate & Obsidian)
  static const Color background = Color(0xFF0F172A); // Slate 900
  static const Color surface = Color(0xFF1E293B); // Slate 800
  static const Color surfaceLight = Color(0xFF334155); // Slate 700
  static const Color card = Color(0xFF1E293B);
  static const Color cardBorder = Color(0xFF334155);

  // Brand Accents (Emerald / Cyan Neon)
  static const Color primary = Color(0xFF10B981); // Emerald 500
  static const Color primaryLight = Color(0xFF34D399); // Emerald 400
  static const Color primaryDark = Color(0xFF059669); // Emerald 600
  static const Color secondary = Color(0xFF06B6D4); // Cyan 500
  static const Color accent = Color(0xFF6366F1); // Indigo 500

  // Text Colors
  static const Color textPrimary = Color(0xFFF8FAFC); // Slate 50
  static const Color textSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color textMuted = Color(0xFF64748B); // Slate 500

  // Ticket Priority Colors
  static const Color priorityCritical = Color(0xFFEF4444); // Red 500
  static const Color priorityCriticalBg = Color(0x26EF4444); // 15% Red
  static const Color priorityHigh = Color(0xFFF97316); // Orange 500
  static const Color priorityHighBg = Color(0x26F97316); // 15% Orange
  static const Color priorityMedium = Color(0xFF3B82F6); // Blue 500
  static const Color priorityMediumBg = Color(0x263B82F6); // 15% Blue
  static const Color priorityLow = Color(0xFF10B981); // Emerald 500
  static const Color priorityLowBg = Color(0x2610B981); // 15% Emerald

  // Status & Synchronization
  static const Color statusSynced = Color(0xFF10B981);
  static const Color statusPending = Color(0xFFF59E0B);
  static const Color statusDraft = Color(0xFF94A3B8);

  // Waveform & Recording State
  static const Color recordingActive = Color(0xFFEF4444);
  static const Color recordingGlow = Color(0x55EF4444);
  static const Color waveBar = Color(0xFF10B981);
}
