import 'package:flutter/material.dart';

/// Paleta de colores corporativa de SmartBank EC
/// Basada en tonos verdes esmeralda con acentos dorados
class AppColors {
  AppColors._();

  // ── Colores principales ──
  static const Color primary = Color(0xFF00897B);       // Verde Teal 600
  static const Color primaryDark = Color(0xFF00695C);   // Verde Teal 800
  static const Color primaryLight = Color(0xFF4DB6AC);  // Verde Teal 300

  // ── Colores secundarios ──
  static const Color secondary = Color(0xFF2E7D32);     // Verde oscuro
  static const Color accent = Color(0xFFFFB300);        // Dorado/Ámbar

  // ── Fondos ──
  static const Color background = Color(0xFFF5F7FA);    // Gris muy claro
  static const Color surface = Color(0xFFFFFFFF);       // Blanco
  static const Color scaffoldBackground = Color(0xFFF0F4F3); // Gris verdoso

  // ── Textos ──
  static const Color textPrimary = Color(0xFF1B2631);   // Casi negro
  static const Color textSecondary = Color(0xFF607D8B); // Gris azulado
  static const Color textOnPrimary = Color(0xFFFFFFFF); // Blanco sobre primario

  // ── Estados ──
  static const Color success = Color(0xFF43A047);       // Verde éxito
  static const Color error = Color(0xFFE53935);         // Rojo error
  static const Color warning = Color(0xFFFFA726);       // Naranja advertencia
  static const Color info = Color(0xFF29B6F6);          // Azul info

  // ── Gradientes ──
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, Color(0xFF26A69A)],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryDark, primary, Color(0xFF26A69A)],
  );

  // ── Sombras ──
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: primary.withValues(alpha: 0.15),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
}
