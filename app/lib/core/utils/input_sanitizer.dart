// ============================================================================
// Archivo  : input_sanitizer.dart
// Ubicación: lib/core/utils/input_sanitizer.dart
// Proyecto : SITRA-Luz • Clínica La Luz
// ----------------------------------------------------------------------------
// Clase utilitaria de saneamiento (sanitización) de entradas del usuario.
//
// DESACOPLAMIENTO ARQUITECTURAL:
//   • NO importa bibliotecas de renderizado visual (flutter/material.dart,
//     flutter/widgets.dart, flutter/cupertino.dart, etc.).
//   • NO importa bibliotecas de red/HTTP (http, dio, supabase_flutter, etc.).
//   • Solo utiliza 'dart:core' (implícito) — sin dependencias externas.
//
// Responsabilidades:
//   1. Eliminar espacios en blanco en los extremos (leading/trailing).
//   2. Colapsar espacios internos duplicados en un solo espacio.
//   3. Suprimir caracteres de control no imprimibles (Unicode C0, C1, DEL, etc.).
//   4. Proveer métodos especializados para campos comunes:
//      correo, DNI, nombre completo, código alfanumérico.
// ============================================================================

/// Clase utilitaria pura para el saneamiento (sanitización) de datos de
/// entrada ingresados por el usuario.
///
/// Esta clase opera exclusivamente con [String] y no depende de ninguna
/// biblioteca de UI, Widgets, renderizado ni de clientes HTTP/red, lo que
/// garantiza su desacoplamiento arquitectural y facilita las pruebas unitarias.
///
/// Uso típico:
/// ```dart
/// final correoLimpio = InputSanitizer.sanitizeEmail('  usuario@correo.com  ');
/// final nombreLimpio = InputSanitizer.sanitizeName('  Juan   Carlos  ');
/// final dniLimpio    = InputSanitizer.sanitizeDni(' 12345678 ');
/// final codigoLimpio = InputSanitizer.sanitizeCode(' COD-001 ');
/// ```
class InputSanitizer {
  // ---------------------------------------------------------------------------
  // Constructor privado: esta clase es puramente estática (no se instancia).
  // ---------------------------------------------------------------------------
  InputSanitizer._();

  // ===========================================================================
  //  MÉTODOS BASE DE SANEAMIENTO
  // ===========================================================================

  /// Elimina caracteres de control no imprimibles de [input].
  ///
  /// Se suprimen todos los caracteres Unicode de las categorías C0 (U+0000–U+001F),
  /// DEL (U+007F) y C1 (U+0080–U+009F), preservando espacios normales, tabulaciones
  /// convertidas a espacio, y saltos de línea si fuese necesario.
  static String removeControlCharacters(String input) {
    // Expresión regular que detecta caracteres de control no imprimibles.
    // Rangos cubiertos:
    //   \x00-\x08  : C0 control (NUL a BS), excluyendo TAB (\x09)
    //   \x0B-\x0C  : VT y FF
    //   \x0E-\x1F  : C0 control restante (SO a US)
    //   \x7F       : DEL
    //   \x80-\x9F  : C1 control
    final controlCharsPattern = RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F\x80-\x9F]');
    return input.replaceAll(controlCharsPattern, '');
  }

  /// Colapsa secuencias de dos o más espacios en blanco consecutivos en un
  /// único espacio.
  ///
  /// Ejemplo: `'Juan    Carlos'` → `'Juan Carlos'`.
  static String collapseWhitespace(String input) {
    return input.replaceAll(RegExp(r'\s{2,}'), ' ');
  }

  /// Aplica el pipeline completo de saneamiento genérico a [input]:
  ///
  /// 1. Suprime caracteres de control no imprimibles.
  /// 2. Colapsa espacios internos duplicados.
  /// 3. Elimina espacios en los extremos (trim).
  ///
  /// Este es el método principal y se recomienda como punto de entrada para
  /// cualquier campo de texto que no requiera un tratamiento especializado.
  static String sanitize(String input) {
    String result = input;

    // Paso 1: Remover caracteres de control no imprimibles
    result = removeControlCharacters(result);

    // Paso 2: Colapsar espacios internos duplicados
    result = collapseWhitespace(result);

    // Paso 3: Eliminar espacios en los extremos
    result = result.trim();

    return result;
  }

  // ===========================================================================
  //  MÉTODOS ESPECIALIZADOS POR TIPO DE CAMPO
  // ===========================================================================

  /// Sanea un correo electrónico ingresado por el usuario.
  ///
  /// Además del pipeline base, convierte el correo a minúsculas para
  /// normalización (los correos electrónicos son case-insensitive según RFC 5321).
  ///
  /// Ejemplo:
  /// ```dart
  /// InputSanitizer.sanitizeEmail('  Usuario@Correo.COM  ');
  /// // → 'usuario@correo.com'
  /// ```
  static String sanitizeEmail(String input) {
    return sanitize(input).toLowerCase();
  }

  /// Sanea un número de DNI (Documento Nacional de Identidad).
  ///
  /// Además del pipeline base, elimina todos los caracteres que no sean
  /// dígitos numéricos, asegurando que el resultado contenga solo números.
  ///
  /// Ejemplo:
  /// ```dart
  /// InputSanitizer.sanitizeDni('  12-345.678  ');
  /// // → '12345678'
  /// ```
  static String sanitizeDni(String input) {
    final cleaned = sanitize(input);
    return cleaned.replaceAll(RegExp(r'[^0-9]'), '');
  }

  /// Sanea un nombre completo (nombre y apellidos) ingresado por el usuario.
  ///
  /// Además del pipeline base, elimina dígitos y caracteres especiales que no
  /// correspondan a letras, espacios o tildes/diacríticos comunes del español.
  ///
  /// Ejemplo:
  /// ```dart
  /// InputSanitizer.sanitizeName('  Juan   Carlos   Pérez  ');
  /// // → 'Juan Carlos Pérez'
  /// ```
  static String sanitizeName(String input) {
    String cleaned = sanitize(input);

    // Permitir solo letras (incluyendo acentuadas/diacríticos), espacios y guiones
    cleaned = cleaned.replaceAll(RegExp(r"[^a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s\-']"), '');

    // Colapsar espacios que pudieran generarse tras la eliminación
    cleaned = collapseWhitespace(cleaned).trim();

    return cleaned;
  }

  /// Sanea un código alfanumérico (ej. código de producto, código de servicio).
  ///
  /// Además del pipeline base, convierte a mayúsculas y permite solo caracteres
  /// alfanuméricos y guiones, que son los formatos típicos de codificación.
  ///
  /// Ejemplo:
  /// ```dart
  /// InputSanitizer.sanitizeCode('  cod-001/abc  ');
  /// // → 'COD-001ABC'
  /// ```
  static String sanitizeCode(String input) {
    String cleaned = sanitize(input).toUpperCase();

    // Permitir solo letras, dígitos y guiones
    cleaned = cleaned.replaceAll(RegExp(r'[^A-Z0-9\-]'), '');

    return cleaned;
  }
}
