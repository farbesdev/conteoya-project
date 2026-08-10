import 'package:flutter/material.dart';

class AppColors {
  // Primarios Institucionales
  static const Color primary = Color(0xFF0F172A);      // Slate 900
  static const Color primaryLight = Color(0xFF1E293B); // Slate 800
  static const Color accent = Color(0xFF2563EB);       // Blue 600
  static const Color accentHover = Color(0xFF1D4ED8);  // Blue 700

  // Superficies y Fondos
  static const Color background = Color(0xFF0B1120);   // Deep Slate
  static const Color surface = Color(0xFF1E293B);      // Surface Card
  static const Color surfaceElevated = Color(0xFF334155);

  // Estados Electorales / Sync
  static const Color success = Color(0xFF10B981);       // Emerald 500 (SYNCED / CONFIRMED)
  static const Color warning = Color(0xFFF59E0B);       // Amber 500 (TOTAL_MISMATCH / Low Confidence)
  static const Color danger = Color(0xFFEF4444);        // Rose 500 (FAILED / CONFLICT)
  static const Color info = Color(0xFF38BDF8);          // Sky 400 (SYNCING)
  static const Color draft = Color(0xFF94A3B8);         // Slate 400 (DRAFT)

  // Textos
  static const Color textPrimary = Color(0xFFF8FAFC);   // Slate 50
  static const Color textSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color textMuted = Color(0xFF64748B);     // Slate 500
  static const Color border = Color(0xFF334155);        // Slate 700
}
