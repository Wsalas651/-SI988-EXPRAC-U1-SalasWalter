import 'package:flutter/material.dart';
import '../../../../core/utils/input_validator.dart';
import '../../../../core/utils/validation_exception.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../states/auth_state.dart';

/// ViewModel del módulo de autenticación.
/// Implementa [ChangeNotifier] para notificar a la UI.
/// No importa nada de Firebase directamente — usa [AuthRepository].
///
/// VALIDACIÓN PREVIA A LA RED:
/// El método [login] utiliza [InputValidator] para verificar las reglas de
/// negocio (formato de correo, longitud de contraseña) ANTES de invocar al
/// repositorio. Si la validación falla, se lanza [ValidationException] y se
/// aborta el flujo sin contactar al servicio de red.
class AuthViewModel extends ChangeNotifier {
  final AuthRepository _repository;

  AuthState _state = const AuthStateInitial();
  AuthState get state => _state;

  UserEntity? _currentUser;
  UserEntity? get currentUser => _currentUser;

  AuthViewModel({required AuthRepository repository})
      : _repository = repository {
    _checkCurrentSession();
  }

  /// Verifica si hay una sesión activa al iniciar la app
  Future<void> _checkCurrentSession() async {
    _setState(const AuthStateLoading());
    try {
      final user = await _repository.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        _setState(AuthStateAuthenticated(user));
      } else {
        _setState(const AuthStateUnauthenticated());
      }
    } catch (_) {
      _setState(const AuthStateUnauthenticated());
    }
  }

  /// Inicia sesión con email y contraseña.
  ///
  /// FLUJO DE VALIDACIÓN PREVIA A LA CAPA DE RED:
  /// 1. Se valida y sanea el email con [InputValidator.validateEmail].
  /// 2. Se valida la contraseña con [InputValidator.validatePassword].
  /// 3. Si alguna validación falla → [ValidationException] → se aborta
  ///    sin invocar al repositorio ni contactar la red.
  /// 4. Solo si TODAS las validaciones pasan → se llama a [_repository.login].
  Future<void> login({
    required String email,
    required String password,
  }) async {
    // ─── PASO 1: Validación de reglas de negocio ANTES de la capa de red ───
    // Si las validaciones fallan, se lanza ValidationException y el
    // repositorio NUNCA es invocado (no hay contacto con la red).
    final String validatedEmail;
    final String validatedPassword;

    try {
      validatedEmail = InputValidator.validateEmail(email);
      validatedPassword = InputValidator.validatePassword(password);
    } on ValidationException catch (e) {
      // ── INTERCEPTACIÓN: Se rechaza la llamada al repositorio ──
      // La excepción controlada aborta el flujo ANTES de la red.
      _setState(AuthStateError(e.message));
      return; // ← Sale sin invocar al repositorio
    }

    // ─── PASO 2: Las validaciones pasaron → ahora sí se contacta la red ───
    _setState(const AuthStateLoading());
    try {
      final user = await _repository.login(
        email: validatedEmail,
        password: validatedPassword,
      );
      _currentUser = user;
      _setState(AuthStateAuthenticated(user));
    } on AuthException catch (e) {
      _setState(AuthStateError(e.message));
    } catch (e) {
      _setState(AuthStateError('Error inesperado. Inténtalo de nuevo.'));
    }
  }

  /// Cierra la sesión actual
  Future<void> logout() async {
    _setState(const AuthStateLoading());
    try {
      await _repository.logout();
      _currentUser = null;
      _setState(const AuthStateUnauthenticated());
    } catch (e) {
      _setState(AuthStateError('No se pudo cerrar la sesión. Inténtalo de nuevo.'));
    }
  }

  /// Limpia un error anterior para permitir reintentar
  void clearError() {
    if (_state is AuthStateError) {
      _setState(const AuthStateInitial());
    }
  }

  void _setState(AuthState newState) {
    _state = newState;
    notifyListeners();
  }
}
