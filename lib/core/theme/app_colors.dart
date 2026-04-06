import 'package:flutter/material.dart';

/// Curated color palette for Dashauli Connect
/// Inspired by trust (deep blue/teal) + community warmth (amber/saffron)
class AppColors {
  AppColors._();

  // ─── Primary Brand ─────────────────────────────────────────
  static const Color primary = Color(0xFF0D6E6E);       // Deep teal — trust
  static const Color primaryLight = Color(0xFF4DA8A8);   // Light teal
  static const Color primaryDark = Color(0xFF004848);    // Dark teal

  // ─── Secondary / Accent ────────────────────────────────────
  static const Color accent = Color(0xFFFF8F00);         // Saffron amber — warmth
  static const Color accentLight = Color(0xFFFFBF47);    // Light amber
  static const Color accentDark = Color(0xFFC66100);     // Dark amber

  // ─── Semantic ──────────────────────────────────────────────
  static const Color success = Color(0xFF2E7D32);        // Green — delivered
  static const Color warning = Color(0xFFF57F17);        // Yellow — in transit
  static const Color error = Color(0xFFC62828);          // Red — SOS / cancelled
  static const Color info = Color(0xFF1565C0);           // Blue — informational

  // ─── Surfaces (Light) ──────────────────────────────────────
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static Color borderLight = Colors.grey.shade200;

  // ─── Surfaces (Dark) ───────────────────────────────────────
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static Color borderDark = Colors.grey.shade800;

  // ─── Text ──────────────────────────────────────────────────
  static const Color textPrimaryLight = Color(0xFF1A1A1A);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color textPrimaryDark = Color(0xFFF5F5F5);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);

  // ─── Mode Colors ───────────────────────────────────────────
  static const Color requesterMode = Color(0xFF0D6E6E);  // Teal — shopping
  static const Color travelerMode = Color(0xFF1565C0);   // Blue — delivery

  // ─── Order Status Colors ───────────────────────────────────
  static const Color statusRequested = Color(0xFFFF8F00);
  static const Color statusAccepted = Color(0xFF1565C0);
  static const Color statusPickedUp = Color(0xFF7B1FA2);
  static const Color statusDelivered = Color(0xFF2E7D32);
  static const Color statusCancelled = Color(0xFFC62828);
}
