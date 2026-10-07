// ============================================================================
// Archivo  : auth_viewmodel_test.dart
// Ubicación: test/auth_viewmodel_test.dart
// Proyecto : SITRA-Luz • Clínica La Luz
// ----------------------------------------------------------------------------
// PUNTO 4 DEL EXAMEN: Tres pruebas de autenticación y flujo en terminal.
//
//   (a) Estado en frío: al inicializar el ViewModel no hay sesión previa.
//   (b) Flujo exitoso: autenticación conforme y carga íntegra de la entidad.
//   (c) Flujo denegado: credenciales rechazadas → estado de fallo sin
//       peticiones adicionales al repositorio.
//
// Se ejecuta con: flutter test test/auth_viewmodel_test.dart
// Sin emuladores ni dependencias externas.
// ============================================================================

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';

// Entidades y contratos del dominio
import 'package:sitra_luz/features/auth/domain/entities/user_entity.dart';
import 'package:sitra_luz/features/auth/domain/repositories/auth_repository.dart';
import 'package:sitra_luz/features/auth/data/datasources/auth_remote_datasource.dart';

// ViewModel bajo prueba
import 'package:sitra_luz/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:sitra_luz/features/auth/presentation/states/auth_state.dart';

// =============================================================================
//  MOCK DEL REPOSITORIO CON CONTADOR DE LLAMADAS
// =============================================================================

/// Mock manual del repositorio de autenticación.
/// Registra el número exacto de llamadas a cada método para verificar
/// que no se realizan peticiones innecesarias a la red.
class MockAuthRepositoryForTest implements AuthRepository {
  // Contadores de llamadas
  int loginCallCount = 0;
  int logoutCallCount = 0;
  int getCurrentUserCallCount = 0;

  // Comportamiento configurable
  UserEntity? currentUserToReturn;
  UserEntity? loginUserToReturn;
  Exception? loginExceptionToThrow;

  final _authController = StreamController<UserEntity?>.broadcast();

  @override
  Future<UserEntity> login({
    required String email,
    required String password,
  }) async {
    loginCallCount++;

    if (loginExceptionToThrow != null) {
      throw loginExceptionToThrow!;
    }

    if (loginUserToReturn != null) {
      return loginUserToReturn!;
    }

    throw const AuthException('Correo o contraseña incorrectos.');
  }

  @override
  Future<void> logout() async {
    logoutCallCount++;
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    getCurrentUserCallCount++;
    return currentUserToReturn;
  }

  @override
  Stream<UserEntity?> get authStateChanges => _authController.stream;

  void dispose() {
    _authController.close();
  }
}

// =============================================================================
//  ENTIDAD DE PRUEBA
// =============================================================================

/// Usuario de prueba con datos completos para verificar carga íntegra.
const testUser = UserEntity(
  uid: 'uid-test-001',
  nombre: 'Dr. Juan Pérez Rodríguez',
  email: 'admin@sitraluz.pe',
  rol: UserRole.administrador,
  areasAsignadas: ['Sistemas', 'Dirección General'],
  activo: true,
);

// =============================================================================
//  SUITE DE PRUEBAS — PUNTO 4
// =============================================================================

void main() {
  group('PUNTO 4 — Pruebas de Autenticación y Flujo', () {
    // =========================================================================
    //  (a) Estado en frío: no hay sesión previa al inicializar
    // =========================================================================
    test('(a) Estado en frío: al inicializar no existe sesión previa', () async {
      // Arrange: repositorio que devuelve null (sin sesión activa)
      final mockRepo = MockAuthRepositoryForTest();
      mockRepo.currentUserToReturn = null;

      // Act: crear el ViewModel (dispara _checkCurrentSession internamente)
      final viewModel = AuthViewModel(repository: mockRepo);

      // Esperar a que se complete la verificación asíncrona de sesión
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert: el estado debe ser "no autenticado" y no hay usuario cargado
      expect(viewModel.state, isA<AuthStateUnauthenticated>());
      expect(viewModel.currentUser, isNull);
      expect(mockRepo.getCurrentUserCallCount, equals(1),
          reason: 'Se debe consultar exactamente 1 vez si hay sesión previa');
      expect(mockRepo.loginCallCount, equals(0),
          reason: 'No se debe invocar login() durante la inicialización');

      mockRepo.dispose();
    });

    // =========================================================================
    //  (b) Flujo exitoso: autenticación conforme y carga íntegra de entidad
    // =========================================================================
    test('(b) Flujo exitoso: login válido carga íntegramente la entidad', () async {
      // Arrange: repositorio que retorna el usuario de prueba
      final mockRepo = MockAuthRepositoryForTest();
      mockRepo.currentUserToReturn = null;
      mockRepo.loginUserToReturn = testUser;

      final viewModel = AuthViewModel(repository: mockRepo);
      await Future.delayed(const Duration(milliseconds: 100));

      // Act: login con credenciales válidas (ya saneadas por InputValidator)
      await viewModel.login(
        email: 'admin@sitraluz.pe',
        password: 'admin123',
      );

      // Assert: estado autenticado con entidad cargada íntegramente
      expect(viewModel.state, isA<AuthStateAuthenticated>());
      expect(viewModel.currentUser, isNotNull);

      // Verificar carga ÍNTEGRA de todos los campos de la entidad
      final user = viewModel.currentUser!;
      expect(user.uid, equals('uid-test-001'));
      expect(user.nombre, equals('Dr. Juan Pérez Rodríguez'));
      expect(user.email, equals('admin@sitraluz.pe'));
      expect(user.rol, equals(UserRole.administrador));
      expect(user.areasAsignadas, containsAll(['Sistemas', 'Dirección General']));
      expect(user.activo, isTrue);

      // Verificar que el repositorio fue invocado exactamente 1 vez
      expect(mockRepo.loginCallCount, equals(1),
          reason: 'El repositorio debe recibir exactamente 1 llamada a login()');

      mockRepo.dispose();
    });

    // =========================================================================
    //  (c) Flujo denegado: credenciales rechazadas → estado de fallo
    //      sin peticiones adicionales
    // =========================================================================
    test('(c) Flujo denegado: credenciales rechazadas generan estado de fallo', () async {
      // Arrange: repositorio que lanza excepción al hacer login
      final mockRepo = MockAuthRepositoryForTest();
      mockRepo.currentUserToReturn = null;
      mockRepo.loginExceptionToThrow = const AuthException(
        'Correo o contraseña incorrectos.',
      );

      final viewModel = AuthViewModel(repository: mockRepo);
      await Future.delayed(const Duration(milliseconds: 100));

      // Act: login con credenciales rechazadas
      await viewModel.login(
        email: 'admin@sitraluz.pe',
        password: 'passwordIncorrecto',
      );

      // Assert: estado de error con mensaje adecuado
      expect(viewModel.state, isA<AuthStateError>());
      final errorState = viewModel.state as AuthStateError;
      expect(errorState.message, contains('incorrectos'));
      expect(viewModel.currentUser, isNull,
          reason: 'No debe haber usuario cargado tras un login fallido');

      // Verificar que NO se desencadenaron peticiones adicionales
      expect(mockRepo.loginCallCount, equals(1),
          reason: 'Solo 1 llamada a login(), sin reintentos adicionales');
      expect(mockRepo.logoutCallCount, equals(0),
          reason: 'No se debe invocar logout() tras un login fallido');

      mockRepo.dispose();
    });
  });
}
