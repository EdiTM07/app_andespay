import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_banco/core/constants/app.firestore_collections.dart';
import 'package:app_banco/features/accounts/repositories/account.repository.dart';
import 'package:app_banco/features/auth/models/user.model.dart';
import 'package:app_banco/services/firebase_auth_service.dart';
import 'package:app_banco/services/firestore_service.dart';

/// Repositorio de autenticación
/// Orquesta los servicios de FirebaseAuth y Firestore
/// Contiene toda la lógica de negocio relacionada con auth
class AuthRepository {
  AuthRepository._();

  static final AuthRepository _instance = AuthRepository._();
  factory AuthRepository() => _instance;

  final FirebaseAuthService _authService = FirebaseAuthService();
  final FirestoreService _firestoreService = FirestoreService();

  // ── Stream del estado de autenticación ──

  Stream<User?> get authStateChanges => _authService.authStateChanges;

  // ── Login con Email ──

  /// Inicia sesión y retorna el UserModel correspondiente
  Future<UserModel> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _authService.signInWithEmail(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;
    return await _getUserOrThrow(uid);
  }

  // ── Registro con Email ──

  /// Registra un nuevo usuario en Firebase Auth y crea su perfil en Firestore
  Future<UserModel> registerWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? cedula,
  }) async {
    final credential = await _authService.registerWithEmail(
      email: email,
      password: password,
    );

    await _authService.updateDisplayName(fullName);

    final user = UserModel(
      uid: credential.user!.uid,
      fullName: fullName,
      email: email,
      cedula: cedula,
      createdAt: DateTime.now(),
      isActive: true,
    );

    await _firestoreService.setDocument(
      collection: AppCollections.users,
      docId: user.uid,
      data: user.toJson(),
    );

    // Crear cuenta de ahorros automáticamente al registrarse
    await AccountRepository().createSavingsAccount(user.uid);

    return user;
  }

  // ── Google Sign In ──

  /// Autentica con Google y crea/actualiza perfil en Firestore
  Future<UserModel?> loginWithGoogle() async {
    final credential = await _authService.signInWithGoogle();
    if (credential == null) return null; // Usuario canceló

    final uid = credential.user!.uid;

    // Verificar si el usuario ya existe en Firestore
    final existing = await _firestoreService.getDocument(
      collection: AppCollections.users,
      docId: uid,
    );

    if (existing != null) {
      return UserModel.fromJson(existing);
    }

    // Primer login con Google: crear perfil
    final user = UserModel(
      uid: uid,
      fullName: credential.user!.displayName ?? 'Usuario AndesPay',
      email: credential.user!.email ?? '',
      photoUrl: credential.user!.photoURL,
      createdAt: DateTime.now(),
      isActive: true,
    );

    await _firestoreService.setDocument(
      collection: AppCollections.users,
      docId: user.uid,
      data: user.toJson(),
    );

    // Crear cuenta de ahorros para el nuevo usuario de Google
    await AccountRepository().createSavingsAccount(user.uid);

    return user;
  }

  // ── Recuperación de contraseña ──

  Future<void> sendPasswordReset(String email) async {
    await _authService.sendPasswordResetEmail(email);
  }

  // ── Cerrar sesión ──

  Future<void> signOut() async {
    await _authService.signOut();
  }

  // ── Actualizar PIN ──

  Future<void> updatePinHash({
    required String uid,
    required String pinHash,
  }) async {
    await _firestoreService.updateDocument(
      collection: AppCollections.users,
      docId: uid,
      data: {'pinHash': pinHash},
    );
  }

  // ── Obtener perfil actual ──

  Future<UserModel?> getCurrentUserProfile() async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return null;

    final data = await _firestoreService.getDocument(
      collection: AppCollections.users,
      docId: uid,
    );
    if (data == null) return null;
    return UserModel.fromJson(data);
  }

  // ── Actualizar perfil ──

  Future<void> updateProfile({
    required String uid,
    required String fullName,
    String? phoneNumber,
    String? cedula,
  }) async {
    final Map<String, dynamic> data = {
      'fullName': fullName,
    };
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      data['phoneNumber'] = phoneNumber;
    }
    if (cedula != null && cedula.isNotEmpty) {
      data['cedula'] = cedula;
    }

    await _firestoreService.updateDocument(
      collection: AppCollections.users,
      docId: uid,
      data: data,
    );
  }

  // ── Helper privado ──

  Future<UserModel> _getUserOrThrow(String uid) async {
    final data = await _firestoreService.getDocument(
      collection: AppCollections.users,
      docId: uid,
    );
    if (data == null) {
      throw Exception('Perfil de usuario no encontrado en Firestore.');
    }
    return UserModel.fromJson(data);
  }
}
