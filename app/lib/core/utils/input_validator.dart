// ============================================================================
// Archivo  : input_validator.dart
// Ubicación: lib/core/utils/input_validator.dart
// Proyecto : SITRA-Luz • Clínica La Luz
// ----------------------------------------------------------------------------
// Clase de validación de reglas de negocio previas a la capa de red.
//
// DESACOPLAMIENTO ARQUITECTURAL:
//   • NO importa bibliotecas de renderizado visual (flutter/material.dart,
//     flutter/widgets.dart, flutter/cupertino.dart, etc.).
//   • NO importa bibliotecas de red/HTTP (http, dio, supabase_flutter, etc.).
//   • Solo importa clases propias de dominio: InputSanitizer y
//     ValidationException (ambas desacopladas).
//
// Responsabilidades:
//   Verificar que los datos de entrada del usuario cumplen las reglas de
//   negocio ANTES de invocar al repositorio. Si un valor no es conforme,
//   se lanza [ValidationException] para abortar el flujo sin contactar la red.
// ============================================================================

import 'input_sanitizer.dart';
import 'validation_exception.dart';

/// Clase de validación de reglas de negocio inherentes a la aplicación
/// SITRA-Luz, que opera ANTES de la capa de red.
///
/// Cada método valida y sanea la entrada. Si la validación falla, lanza
/// una [ValidationException] controlada que impide la llamada al repositorio.
/// Si la validación pasa, retorna el valor saneado listo para usar.
///
/// Esta clase NO importa bibliotecas de UI ni de red.
///
/// Uso típico en un caso de uso o ViewModel:
/// ```dart
/// try {
///   final emailLimpio = InputValidator.validateEmail(emailIngresado);
///   final dniLimpio   = InputValidator.validateDni(dniIngresado);
///   // Solo si pasa la validación se invoca al repositorio:
///   await repository.login(email: emailLimpio, password: password);
/// } on ValidationException catch (e) {
///   // Se intercepta y se muestra el error SIN haber contactado la red
///   mostrarError(e.message);
/// }
/// ```
class InputValidator {
  // ---------------------------------------------------------------------------
  // Constructor privado: esta clase es puramente estática (no se instancia).
  // ---------------------------------------------------------------------------
  InputValidator._();

  // ===========================================================================
  //  CONSTANTES DE REGLAS DE NEGOCIO
  // ===========================================================================

  /// Longitud exacta requerida para un DNI peruano.
  static const int dniLength = 8;

  /// Longitud mínima aceptable para una contraseña.
  static const int passwordMinLength = 6;

  /// Longitud máxima de un nombre completo.
  static const int nameMaxLength = 100;

  /// Longitud mínima de un nombre (al menos un nombre y un apellido).
  static const int nameMinLength = 3;

  /// Patrón de expresión regular para validar formato de correo electrónico
  /// compatible con RFC 5322 (simplificado para uso práctico).
  static final RegExp _emailPattern = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Dominios de correo electrónico válidos para el sistema de la clínica.
  /// Si está vacío, se acepta cualquier dominio con formato válido.
  static const List<String> allowedDomains = [];

  // ===========================================================================
  //  MÉTODOS DE VALIDACIÓN
  // ===========================================================================

  /// Valida y sanea un correo electrónico.
  ///
  /// Reglas de negocio:
  /// 1. No puede estar vacío.
  /// 2. Debe tener formato de email válido (usuario@dominio.ext).
  /// 3. Si [allowedDomains] no está vacío, el dominio debe pertenecer a la lista.
  ///
  /// Retorna el correo saneado (sin espacios, en minúsculas).
  /// Lanza [ValidationException] si no cumple las reglas.
  static String validateEmail(String input) {
    final sanitized = InputSanitizer.sanitizeEmail(input);

    if (sanitized.isEmpty) {
      throw const ValidationException(
        'El correo electrónico es obligatorio.',
        field: 'email',
      );
    }

    if (!_emailPattern.hasMatch(sanitized)) {
      throw const ValidationException(
        'El formato del correo electrónico no es válido. '
        'Ejemplo: usuario@dominio.com',
        field: 'email',
      );
    }

    // Validar dominio si hay restricción de dominios permitidos
    if (allowedDomains.isNotEmpty) {
      final domain = sanitized.split('@').last;
      if (!allowedDomains.contains(domain)) {
        throw ValidationException(
          'El dominio "$domain" no está autorizado para este sistema. '
          'Dominios permitidos: ${allowedDomains.join(", ")}.',
          field: 'email',
        );
      }
    }

    return sanitized;
  }

  /// Valida y sanea un número de DNI (Documento Nacional de Identidad).
  ///
  /// Reglas de negocio:
  /// 1. No puede estar vacío.
  /// 2. Debe contener exactamente 8 dígitos numéricos.
  ///
  /// Retorna el DNI saneado (solo dígitos).
  /// Lanza [ValidationException] si no cumple las reglas.
  static String validateDni(String input) {
    final sanitized = InputSanitizer.sanitizeDni(input);

    if (sanitized.isEmpty) {
      throw const ValidationException(
        'El número de DNI es obligatorio.',
        field: 'dni',
      );
    }

    if (sanitized.length != dniLength) {
      throw ValidationException(
        'El DNI debe tener exactamente $dniLength dígitos. '
        'Se ingresaron ${sanitized.length} dígitos.',
        field: 'dni',
      );
    }

    return sanitized;
  }

  /// Valida y sanea un nombre completo (nombre y apellidos).
  ///
  /// Reglas de negocio:
  /// 1. No puede estar vacío.
  /// 2. Debe tener al menos [nameMinLength] caracteres.
  /// 3. No debe exceder [nameMaxLength] caracteres.
  /// 4. Solo puede contener letras, espacios, tildes y guiones.
  ///
  /// Retorna el nombre saneado.
  /// Lanza [ValidationException] si no cumple las reglas.
  static String validateName(String input) {
    final sanitized = InputSanitizer.sanitizeName(input);

    if (sanitized.isEmpty) {
      throw const ValidationException(
        'El nombre completo es obligatorio.',
        field: 'nombre',
      );
    }

    if (sanitized.length < nameMinLength) {
      throw ValidationException(
        'El nombre debe tener al menos $nameMinLength caracteres.',
        field: 'nombre',
      );
    }

    if (sanitized.length > nameMaxLength) {
      throw ValidationException(
        'El nombre no debe exceder los $nameMaxLength caracteres.',
        field: 'nombre',
      );
    }

    return sanitized;
  }

  /// Valida y sanea una contraseña.
  ///
  /// Reglas de negocio:
  /// 1. No puede estar vacía.
  /// 2. Debe tener al menos [passwordMinLength] caracteres.
  ///
  /// Nota: La contraseña NO se sanea (no se eliminan caracteres especiales),
  /// solo se verifican las reglas de longitud.
  /// Lanza [ValidationException] si no cumple las reglas.
  static String validatePassword(String input) {
    if (input.isEmpty) {
      throw const ValidationException(
        'La contraseña es obligatoria.',
        field: 'password',
      );
    }

    if (input.length < passwordMinLength) {
      throw ValidationException(
        'La contraseña debe tener al menos $passwordMinLength caracteres.',
        field: 'password',
      );
    }

    return input;
  }

  /// Valida y sanea un código alfanumérico (ej. código de producto o servicio).
  ///
  /// Reglas de negocio:
  /// 1. No puede estar vacío.
  /// 2. Debe tener entre [minLength] y [maxLength] caracteres.
  /// 3. Solo puede contener letras, dígitos y guiones.
  ///
  /// Retorna el código saneado (mayúsculas, solo alfanumérico y guiones).
  /// Lanza [ValidationException] si no cumple las reglas.
  static String validateCode(
    String input, {
    int minLength = 3,
    int maxLength = 20,
    String fieldName = 'código',
  }) {
    final sanitized = InputSanitizer.sanitizeCode(input);

    if (sanitized.isEmpty) {
      throw ValidationException(
        'El $fieldName es obligatorio.',
        field: fieldName,
      );
    }

    if (sanitized.length < minLength) {
      throw ValidationException(
        'El $fieldName debe tener al menos $minLength caracteres.',
        field: fieldName,
      );
    }

    if (sanitized.length > maxLength) {
      throw ValidationException(
        'El $fieldName no debe exceder los $maxLength caracteres.',
        field: fieldName,
      );
    }

    return sanitized;
  }
}
