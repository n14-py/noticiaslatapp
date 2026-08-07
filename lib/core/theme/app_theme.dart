import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // ✅ Arreglado tras el pub get

class AppTheme {
  // PALETA DE COLORES PREMIUM (Estilo Dark Futuro)
  static const Color bgDark = Color(0xFF000000); // Negro absoluto
  static const Color cardDark = Color(0xFF0D0D0D); // Gris casi negro
  static const Color cardBorder = Color(0xFF1A1A1A); // Borde sutil
  static const Color accentCyan = Color(0xFF00F2FF); // Cyan Neón
  static const Color textMuted = Color(0xFF666666); // Gris para detalles

  // GRADIENTES PREMIUM
  static const LinearGradient neonGradient = LinearGradient(
    colors: [Color(0xFF00F2FF), Color(0xFF007BFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static final LinearGradient darkFadeGradient = LinearGradient(
    colors: [Colors.transparent, bgDark.withValues(alpha: 0.9)], // ✅ Arreglado withValues
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // SOMBRAS CON GLOW
  static List<BoxShadow> glowShadow = [
    BoxShadow(
      color: accentCyan.withValues(alpha: 0.3), // ✅ Arreglado withValues
      blurRadius: 15,
      spreadRadius: 2,
    ),
  ];

  // TEMA DE TEXTO PERSONALIZADO (Google Fonts)
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bgDark,
    colorScheme: const ColorScheme.dark(
      surface: cardDark,
      primary: accentCyan,
    ),
    textTheme: TextTheme(
      // Títulos Gigantes (Display)
      displayLarge: GoogleFonts.plusJakartaSans( // ✅ Arreglado identifier
        color: Colors.white,
        fontSize: 32,
        fontWeight: FontWeight.w800,
      ),
      // Títulos de Noticias
      titleLarge: GoogleFonts.plusJakartaSans(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      // Cuerpo de Noticia
      bodyLarge: GoogleFonts.inter(
        color: Colors.white,
        fontSize: 16,
        height: 1.6,
      ),
      // Texto Secundario/Muted
      bodyMedium: GoogleFonts.inter(
        color: textMuted,
        fontSize: 14,
      ),
      // Etiquetas (Categorías)
      labelSmall: GoogleFonts.plusJakartaSans(
        color: accentCyan,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    ),
  );
}