import 'package:flutter/material.dart';

/// Colores tomados del logo PrestaL&J.
class Paleta {
  Paleta._();

  static const tinta = Color(0xFF14234B); // azul marino del texto del logo
  static const azul = Color(0xFF1F5FA6); // acciones principales
  static const cian = Color(0xFF0BB3D2);
  static const naranja = Color(0xFFF5A623); // vence pronto
  static const naranjaTexto = Color(0xFFB86E00); // naranja legible sobre blanco
  static const fondo = Color(0xFFF3F5F9);
  static const borde = Color(0xFFDCE1EA);
  static const suave = Color(0xFF5B6478); // textos secundarios

  static const vencido = Color(0xFFC62828);
  static const cobrado = Color(0xFF2E7D5B);
}

/// Cifras alineadas como en un libro contable.
const cifras = [FontFeature.tabularFigures()];

ThemeData temaPrestaLJ() {
  final esquema = ColorScheme.fromSeed(seedColor: Paleta.azul).copyWith(
    primary: Paleta.azul,
    onPrimary: Colors.white,
    secondary: Paleta.naranja,
    surface: Colors.white,
    onSurface: Paleta.tinta,
    error: Paleta.vencido,
  );

  final bordeCampo = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Paleta.borde),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: esquema,
    scaffoldBackgroundColor: Paleta.fondo,
    appBarTheme: const AppBarTheme(
      backgroundColor: Paleta.fondo,
      foregroundColor: Paleta.tinta,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: TextStyle(color: Paleta.tinta, fontSize: 20, fontWeight: FontWeight.w700),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: bordeCampo,
      enabledBorder: bordeCampo,
      focusedBorder: bordeCampo.copyWith(borderSide: const BorderSide(color: Paleta.azul, width: 1.6)),
      errorBorder: bordeCampo.copyWith(borderSide: const BorderSide(color: Paleta.vencido)),
      focusedErrorBorder: bordeCampo.copyWith(borderSide: const BorderSide(color: Paleta.vencido, width: 1.6)),
      prefixIconColor: Paleta.suave,
      labelStyle: const TextStyle(color: Paleta.suave),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: const BorderSide(color: Paleta.borde),
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Paleta.borde),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Paleta.tinta,
      foregroundColor: Colors.white,
      elevation: 2,
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: Paleta.tinta,
      unselectedLabelColor: Paleta.suave,
      indicatorColor: Paleta.azul,
      dividerColor: Paleta.borde,
      labelStyle: TextStyle(fontWeight: FontWeight.w700),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    dividerTheme: const DividerThemeData(color: Paleta.borde, space: 1),
  );
}
