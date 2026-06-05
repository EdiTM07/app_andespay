import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_banco/features/auth/models/user.model.dart';
import 'package:app_banco/features/auth/repositories/auth.repository.dart';

/// Estado de autenticación de AndesPay
/// Todos los widgets que necesiten saber el estado de auth escuchan este provider
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository = AuthRepository();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _currentUser;
  String? _errorMessage;

  // ── Getters ──

  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  // ── Inicialización ──

  /// Escucha los cambios del estado de auth de Firebase
  void listenToAuthState() {
    _repository.authStateChanges.listen((User? user) async {
      if (user == null) {
        _currentUser = null;
        _setStatus(AuthStatus.unauthenticated);
      } else {
        // Intentar cargar el perfil de Firestore
        final profile = await _repository.getCurrentUserProfile();
        _currentUser = profile;
        _setStatus(AuthStatus.authenticated);
      }
    });
  }

  // ── Login con Email ──

  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    _setStatus(AuthStatus.loading);
    _errorMessage = null;

    try {
      _currentUser = await _repository.loginWithEmail(
        email: email,
        password: password,
      );
      _setStatus(AuthStatus.authenticated);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseError(e.code);
      _setStatus(AuthStatus.error);
      return false;
    } catch (e) {
      _errorMessage = 'Ocurrió un error inesperado.';
      _setStatus(AuthStatus.error);
      return false;
    }
  }

  // ── Registro con Email ──

  Future<bool> registerWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    _setStatus(AuthStatus.loading);
    _errorMessage = null;

    try {
      _currentUser = await _repository.registerWithEmail(
        email: email,
        password: password,
        fullName: fullName,
      );
      _setStatus(AuthStatus.authenticated);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseError(e.code);
      _setStatus(AuthStatus.error);
      return false;
    } catch (e) {
      _errorMessage = 'Ocurrió un error inesperado.';
      _setStatus(AuthStatus.error);
      return false;
    }
  }

  // ── Google Sign In ──

  Future<bool> loginWithGoogle() async {
    _setStatus(AuthStatus.loading);
    _errorMessage = null;

    try {
      final user = await _repository.loginWithGoogle();
      if (user == null) {
        // Usuario canceló el flujo de Google
        _setStatus(AuthStatus.unauthenticated);
        return false;
      }
      _currentUser = user;
      _setStatus(AuthStatus.authenticated);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseError(e.code);
      _setStatus(AuthStatus.error);
      return false;
    } catch (e) {
      _errorMessage = 'No se pudo iniciar sesión con Google.';
      _setStatus(AuthStatus.error);
      return false;
    }
  }

  // ── Recuperación de contraseña ──

  Future<bool> sendPasswordReset(String email) async {
    try {
      await _repository.sendPasswordReset(email);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Cerrar sesión ──

  Future<void> signOut() async {
    await _repository.signOut();
    _currentUser = null;
    _setStatus(AuthStatus.unauthenticated);
  }

  // ── Actualizar perfil ──

  Future<bool> updateProfile({
    required String uid,
    required String fullName,
    String? phoneNumber,
  }) async {
    _setStatus(AuthStatus.loading);
    _errorMessage = null;

    try {
      await _repository.updateProfile(
        uid: uid,
        fullName: fullName,
        phoneNumber: phoneNumber,
      );
      
      // Recargar perfil
      _currentUser = await _repository.getCurrentUserProfile();
      _setStatus(AuthStatus.authenticated);
      return true;
    } catch (e) {
      _errorMessage = 'No se pudo actualizar el perfil.';
      _setStatus(AuthStatus.error);
      return false;
    }
  }

  // ── Limpiar error ──

  void clearError() {
    _errorMessage = null;
    if (_status == AuthStatus.error) {
      _setStatus(
        _currentUser != null
            ? AuthStatus.authenticated
            : AuthStatus.unauthenticated,
      );
    }
  }

  // ── Helpers privados ──

  void _setStatus(AuthStatus status) {
    _status = status;
    notifyListeners();
  }

  /// Mapea errores de Firebase a mensajes legibles en español
  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No existe una cuenta con este correo.';
      case 'wrong-password':
        return 'Contraseña incorrecta.';
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos.';
      case 'email-already-in-use':
        return 'Este correo ya está registrado.';
      case 'weak-password':
        return 'La contraseña es demasiado débil (mínimo 6 caracteres).';
      case 'invalid-email':
        return 'El formato del correo no es válido.';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera un momento.';
      case 'network-request-failed':
        return 'Sin conexión a internet.';
      default:
        return 'Error de autenticación ($code).';
    }
  }
}
