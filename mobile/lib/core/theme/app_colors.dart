import 'package:flutter/material.dart';

class AppColors {
  // ─── DARK THEME CONSTANTS ──────────────────────────────────────────────────
  static const Color darkPrimary = Color(0xFF0F172A);       // Slate 900
  static const Color darkPrimaryLight = Color(0xFF1E293B);  // Slate 800
  static const Color darkBackground = Color(0xFF0B1120);    // Deep Slate
  static const Color darkSurface = Color(0xFF1E293B);       // Surface Card
  static const Color darkSurfaceElevated = Color(0xFF334155);

  static const Color darkTextPrimary = Color(0xFFF8FAFC);   // Slate 50
  static const Color darkTextSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color darkTextMuted = Color(0xFF64748B);     // Slate 500
  static const Color darkBorder = Color(0xFF1E293B);        // Slate 800 (suave y sutil)
  static const Color darkBorderSubtle = Color(0x1AFFFFFF);  // 10% White

  // ─── LIGHT THEME CONSTANTS ─────────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFF8FAFC);   // Slate 50 (más limpio y aireado)
  static const Color lightSurface = Color(0xFFFFFFFF);      // White
  static const Color lightSurfaceElevated = Color(0xFFF1F5F9); // Slate 100
  static const Color lightPrimary = Color(0xFFFFFFFF);      // AppBar blanco
  static const Color lightPrimaryAlt = Color(0xFF1E293B);   // Slate 800

  static const Color lightTextPrimary = Color(0xFF0F172A);  // Slate 900
  static const Color lightTextSecondary = Color(0xFF475569); // Slate 600
  static const Color lightTextMuted = Color(0xFF94A3B8);    // Slate 400
  static const Color lightBorder = Color(0xFFE2E8F0);       // Slate 200 (suave y no saturado)
  static const Color lightBorderSubtle = Color(0x0F0F172A); // 6% Slate 900

  // ─── SHARED ACCENT & STATUS COLORS ─────────────────────────────────────────
  static const Color accent = Color(0xFF2563EB);        // Blue 600
  static const Color accentHover = Color(0xFF1D4ED8);   // Blue 700
  static const Color success = Color(0xFF10B981);       // Emerald 500
  static const Color warning = Color(0xFFF59E0B);       // Amber 500
  static const Color danger = Color(0xFFEF4444);        // Rose 500
  static const Color info = Color(0xFF38BDF8);          // Sky 400
  static const Color draft = Color(0xFF94A3B8);         // Slate 400

  // ─── CONSTANTES DE COMPATIBILIDAD ─────────────────────────────────────────
  static const Color primary = darkPrimary;
  static const Color primaryLight = darkPrimaryLight;
  static const Color background = darkBackground;
  static const Color surface = darkSurface;
  static const Color surfaceElevated = darkSurfaceElevated;
  static const Color textPrimary = darkTextPrimary;
  static const Color textSecondary = darkTextSecondary;
  static const Color textMuted = darkTextMuted;
  static const Color border = darkBorder;

  // ─── DYNAMIC CONTEXTUAL HELPERS ────────────────────────────────────────────
  static Color backgroundOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBackground
        : lightBackground;
  }

  static Color surfaceOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSurface
        : lightSurface;
  }

  static Color surfaceElevatedOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSurfaceElevated
        : lightSurfaceElevated;
  }

  static Color primaryOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkPrimary
        : lightPrimary;
  }

  static Color textPrimaryOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextPrimary
        : lightTextPrimary;
  }

  static Color textSecondaryOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextSecondary
        : lightTextSecondary;
  }

  static Color textMutedOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextMuted
        : lightTextMuted;
  }

  static Color borderOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBorder
        : lightBorder;
  }

  static Color borderSubtleOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBorderSubtle
        : lightBorderSubtle;
  }

  // ─── ACCESSIBLE STATUS HELPERS (ANTI-CHROMOSTEREOPSIS & WCAG AAA) ─────────
  static Color warningOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFFBBF24) // Amber 400 (suave y legible en fondos oscuros sin vibración cromática)
        : const Color(0xFFB45309); // Amber 700 (alto contraste > 5.5:1 en fondos claros, cumple WCAG AAA)
  }

  static Color successOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF34D399) // Emerald 400
        : const Color(0xFF059669); // Emerald 600
  }

  static Color dangerOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFF87171) // Rose 400
        : const Color(0xFFDC2626); // Rose 600
  }

  static Color infoOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF38BDF8) // Sky 400
        : const Color(0xFF0284C7); // Sky 600
  }

  static Color accentOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF60A5FA) // Blue 400
        : const Color(0xFF2563EB); // Blue 600
  }
}
