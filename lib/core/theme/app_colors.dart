import 'package:flutter/material.dart';

/// Curated color palette for Dashauli Connect
/// Matching Stitch design reference
class AppColors {
  AppColors._();

  // ─── Primary Brand ─────────────────────────────────────────
  static const Color primary = Color(0xFF12372A); // Dark Green
  static const Color primaryLight = Color(0xFF436850); // Medium Green
  static const Color primaryDark = Color(0xFF0A1F17); // Darker Green

  // ─── Secondary / Accent ────────────────────────────────────
  static const Color accent = Color(0xFFADBC9F); // Sage
  static const Color accentLight = Color(0xFFD4DECC); // Light Sage
  static const Color accentDark = Color(0xFF8A9A7C); // Dark Sage

  // ─── Semantic ──────────────────────────────────────────────
  static const Color success = Color(0xFF2E7D32); // Green — delivered
  static const Color warning = Color(0xFFF57F17); // Yellow — in transit
  static const Color error = Color(0xFFC62828); // Red — SOS / cancelled
  static const Color info = Color(0xFF1565C0); // Blue — informational

  // ─── Surfaces (Light) ──────────────────────────────────────
  static const Color backgroundLight = Color(0xFFFBFADA); // Cream
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static Color borderLight = Colors.grey.shade300;

  // ─── Surfaces (Dark) ───────────────────────────────────────
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static Color borderDark = Colors.grey.shade800;

  // ─── Text ──────────────────────────────────────────────────
  static const Color textPrimaryLight =
      Color(0xFF12372A); // High contrast on Cream
  static const Color textSecondaryLight = Color(0xFF436850);
  static const Color textPrimaryDark = Color(0xFFFBFADA);
  static const Color textSecondaryDark = Color(0xFFADBC9F);

  // ─── Mode Colors ───────────────────────────────────────────
  static const Color requesterMode = Color(0xFF12372A); // Primary Green
  static const Color travelerMode = Color(0xFF436850); // Medium Green

  // ─── Order Status Colors ───────────────────────────────────
  static const Color statusRequested = Color(0xFFADBC9F); // Sage
  static const Color statusAccepted = Color(0xFF436850); // Medium Green
  static const Color statusPickedUp = Color(0xFF12372A); // Primary
  static const Color statusDelivered = Color(0xFF2E7D32);
  static const Color statusCancelled = Color(0xFFC62828);
}
