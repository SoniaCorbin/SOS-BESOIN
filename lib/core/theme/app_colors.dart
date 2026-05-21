import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Backgrounds ──────────────────────────────────────────
  static const bg        = Color(0xFF0B1220);
  static const bg2       = Color(0xFF0F172A);
  static const surface   = Color(0xFF111C33);
  static const surface2  = Color(0xFF16243F);

  // ── Borders ───────────────────────────────────────────────
  static const line      = Color(0xFF1F2D4A);
  static const line2     = Color(0xFF28385A);

  // ── Text ──────────────────────────────────────────────────
  static const text      = Color(0xFFF1F5F9);
  static const textDim   = Color(0xFF94A3B8);
  static const textMute  = Color(0xFF64748B);

  // ── Accent Amber (primary) ────────────────────────────────
  static const amber     = Color(0xFFF59E0B);
  static const amber2    = Color(0xFFFBBF24);
  static const amberSoft = Color(0x1FF59E0B); // 12% opacity

  // ── Accent Cyan (secondary) ───────────────────────────────
  static const cyan      = Color(0xFF06B6D4);
  static const cyan2     = Color(0xFF22D3EE);
  static const cyanSoft  = Color(0x1F06B6D4);

  // ── Status ────────────────────────────────────────────────
  static const red       = Color(0xFFEF4444);
  static const redSoft   = Color(0x1FEF4444);
  static const green     = Color(0xFF22C55E);
  static const greenSoft = Color(0x1F22C55E);
  static const violet    = Color(0xFFA78BFA);
  static const amber3    = Color(0xFFF59E0B); // alias pour étoiles

  // ── Gradients ─────────────────────────────────────────────
  static const gradientAmber = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [amber, Color(0xFFD97706)],
  );

  static const gradientSurface = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [surface, bg2],
  );
}