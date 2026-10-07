// ============================================================================
// Archivo  : validation_exception.dart
// Ubicación: lib/core/utils/validation_exception.dart
// Proyecto : SITRA-Luz • Clínica La Luz
// ----------------------------------------------------------------------------
// Excepción controlada de validación de negocio.
//
// DESACOPLAMIENTO ARQUITECTURAL:
//   • NO importa bibliotecas de renderizado visual (flutter/material.dart, etc.).
//   • NO importa bibliotecas de red/HTTP (http, dio, supabase_flutter, etc.).
//   • Solo utiliza 'dart:core' (implícito) — sin dependencias externas.
//
// Se lanza cuando un dato de entrada del usuario no cumple las reglas de
// negocio definidas, ANTES de invocar al repositorio o a cualquier servicio
// de red. Esto evita llamadas innecesarias al backend.
// ============================================================================

/// Excepción controlada que se lanza cuando un dato de entrada no cumple
/// las reglas de validación de negocio previas a la capa de red.
///
/// Permite abortar el flujo de forma limpia sin contactar al servicio remoto.
///
/// Ejemplo:
/// ```dart
/// throw ValidationException('El DNI debe tener exactamente 8 dígitos.');
/// ```
class ValidationException implements Exception {
  /// Mensaje descriptivo del error de validación para mostrar al usuario.
  final String message;

  /// Campo de origen que falló la validación (opcional, útil para UI).
  final String? field;

  const ValidationException(this.message, {this.field});

  @override
  String toString() => 'ValidationException($message)';
}
