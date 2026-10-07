// ============================================================================
// Archivo  : sanitizer_validator_test.dart
// Ubicación: test/sanitizer_validator_test.dart
// Proyecto : SITRA-Luz • Clínica La Luz
// ----------------------------------------------------------------------------
// PUNTO 5 DEL EXAMEN: Dos pruebas unitarias de saneamiento y rechazo previo.
//
//   (a) Saneamiento efectivo: cadena con tabulaciones, espacios sobrantes e
//       impurezas → salida formateada según el estándar previsto.
//   (b) Interrupción de red: entrada que vulnera la validación de negocio →
//       el repositorio registra exactamente 0 llamadas (mock con contador).
//
// Se ejecuta con: flutter test test/sanitizer_validator_test.dart
// Sin emuladores ni dependencias externas.
// ============================================================================

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';

// Clases de saneamiento y validación bajo prueba
import 'package:sitra_luz/core/utils/input_sanitizer.dart';
import 'package:sitra_luz/core/utils/input_validator.dart';
import 'package:sitra_luz/core/utils/validation_exception.dart';

// Entidades y contratos del dominio para el mock
import 'package:sitra_luz/features/auth/domain/entities/user_entity.dart';
import 'package:sitra_luz/features/auth/domain/repositories/auth_repository.dart';
import 'package:sitra_luz/features/auth/data/datasources/auth_remote_datasource.dart';

// ViewModel para la prueba de interrupción de red
import 'package:sitra_luz/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:sitra_luz/features/auth/presentation/states/auth_state.dart';

// =============================================================================
//  MOCK DEL REPOSITORIO CON CONTADOR DE LLAMADAS (para prueba 5b)
// =============================================================================

/// Mock que registra el número exacto de llamadas para demostrar
/// que ante una entrada inválida, el repositorio recibe CERO llamadas.
class SpyAuthRepository implements AuthRepository {
  int loginCallCount = 0;
  int logoutCallCount = 0;
  int getCurrentUserCallCount = 0;

  final _controller = StreamController<UserEntity?>.broadcast();

  @override
  Future<UserEntity> login({
    required String email,
    required String password,
  }) async {
    loginCallCount++;
    throw const AuthException('No debería llegar aquí');
  }

  @override
  Future<void> logout() async {
    logoutCallCount++;
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    getCurrentUserCallCount++;
    return null;
  }

  @override
  Stream<UserEntity?> get authStateChanges => _controller.stream;

  void dispose() {
    _controller.close();
  }
}

// =============================================================================
//  SUITE DE PRUEBAS — PUNTO 5
// =============================================================================

void main() {
  group('PUNTO 5 — Pruebas de Saneamiento y Rechazo Previo', () {
    // =========================================================================
    //  (a) Saneamiento efectivo: cadena con tabulaciones, espacios e impurezas
    // =========================================================================
    test('(a) Saneamiento efectivo: limpia tabulaciones, espacios e impurezas', () {
      // ── Caso 1: Cadena con tabulaciones, espacios sobrantes y caracteres
      //    de control no imprimibles ──
      // Entrada: tab + espacios + nombre con espacios duplicados + caracteres control
      final inputSucio = '\t  Juan   \x00  Carlos   \x07 Pérez  \t ';
      //                  ↑tab ↑espacios  ↑NUL     ↑dobles  ↑BEL          ↑tab

      final resultadoNombre = InputSanitizer.sanitizeName(inputSucio);

      // Assert: debe quedar limpio, sin tabs, sin controles, con espacios colapsados
      expect(resultadoNombre, equals('Juan Carlos Pérez'),
          reason: 'Debe remover tabs, caracteres de control y colapsar espacios');

      // ── Caso 2: Email con espacios y caracteres de control ──
      final emailSucio = '  \t  Admin@SitraLUZ.PE  \x0B  ';
      final resultadoEmail = InputSanitizer.sanitizeEmail(emailSucio);

      expect(resultadoEmail, equals('admin@sitraluz.pe'),
          reason: 'Debe hacer trim, remover controles y convertir a minúsculas');

      // ── Caso 3: DNI con caracteres no numéricos e impurezas ──
      final dniSucio = '  \x01 12-345.678 \t ';
      final resultadoDni = InputSanitizer.sanitizeDni(dniSucio);

      expect(resultadoDni, equals('12345678'),
          reason: 'Debe extraer solo los 8 dígitos, removiendo todo lo demás');

      // ── Caso 4: Código con impurezas y formato irregular ──
      final codigoSucio = '  \t cod-001/abc \x00 ';
      final resultadoCodigo = InputSanitizer.sanitizeCode(codigoSucio);

      expect(resultadoCodigo, equals('COD-001ABC'),
          reason: 'Debe convertir a mayúsculas y mantener solo alfanuméricos y guiones');

      // ── Caso 5: Pipeline base sanitize() con múltiples impurezas ──
      final textoSucio = '  \x00\x01\x02 Hola   \t   Mundo \x7F  \x80 ';
      final resultadoBase = InputSanitizer.sanitize(textoSucio);

      expect(resultadoBase, equals('Hola Mundo'),
          reason: 'Pipeline base: remover controles → colapsar espacios → trim');

      // ── Verificación adicional: los métodos individuales funcionan ──
      expect(InputSanitizer.removeControlCharacters('\x00Hola\x07'), equals('Hola'),
          reason: 'removeControlCharacters debe eliminar NUL y BEL');
      expect(InputSanitizer.collapseWhitespace('a   b    c'), equals('a b c'),
          reason: 'collapseWhitespace debe colapsar múltiples espacios en uno');
    });

    // =========================================================================
    //  (b) Interrupción de red: entrada inválida → repositorio con 0 llamadas
    // =========================================================================
    test('(b) Interrupción de red: entrada inválida → repositorio recibe 0 llamadas', () async {
      // Arrange: mock del repositorio que cuenta llamadas
      final spyRepo = SpyAuthRepository();
      final viewModel = AuthViewModel(repository: spyRepo);

      // Esperar a que se complete la inicialización
      await Future.delayed(const Duration(milliseconds: 100));

      // Resetear el contador de getCurrentUser (se llama 1 vez en init)
      final callsAfterInit = spyRepo.loginCallCount;
      expect(callsAfterInit, equals(0),
          reason: 'Antes del login, el repositorio no debe tener llamadas a login()');

      // Act: intentar login con email INVÁLIDO que vulnera la validación
      // (formato de correo incorrecto → InputValidator.validateEmail() falla)
      await viewModel.login(
        email: 'correo-sin-arroba-invalido',
        password: 'admin123',
      );

      // Assert: el estado debe ser error de validación
      expect(viewModel.state, isA<AuthStateError>());
      final errorState = viewModel.state as AuthStateError;
      expect(errorState.message, contains('correo electrónico'),
          reason: 'El mensaje debe indicar que el formato de correo es inválido');

      // ── VERIFICACIÓN CLAVE: el repositorio registra EXACTAMENTE 0 llamadas ──
      expect(spyRepo.loginCallCount, equals(0),
          reason: '⚠️ CERO llamadas a login(): la validación abortó ANTES de la red');

      // Act adicional: intentar con contraseña muy corta
      viewModel.clearError();
      await viewModel.login(
        email: 'admin@sitraluz.pe',
        password: '123', // < 6 caracteres, falla validatePassword
      );

      // Assert: sigue en error y el repositorio sigue con 0 llamadas
      expect(viewModel.state, isA<AuthStateError>());
      expect(spyRepo.loginCallCount, equals(0),
          reason: '⚠️ Sigue con CERO llamadas: la contraseña corta también fue rechazada antes de la red');

      // Act adicional: intentar con email vacío
      viewModel.clearError();
      await viewModel.login(
        email: '   ',
        password: 'admin123',
      );

      // Assert final: 3 intentos inválidos, 0 llamadas al repositorio
      expect(viewModel.state, isA<AuthStateError>());
      expect(spyRepo.loginCallCount, equals(0),
          reason: '⚠️ Tras 3 intentos inválidos: CERO llamadas al repositorio. '
              'La validación de negocio impidió toda comunicación con la red.');

      spyRepo.dispose();
    });
  });
}
