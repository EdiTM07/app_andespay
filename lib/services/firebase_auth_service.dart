import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Wrapper aislado de FirebaseAuth y GoogleSignIn
/// Solo expone los métodos de bajo nivel. La lógica de negocio va en auth.repository
class FirebaseAuthService {
  FirebaseAuthService._();

  static final FirebaseAuthService _instance = FirebaseAuthService._();
  factory FirebaseAuthService() => _instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ── Stream del estado de autenticación ──

  /// Emite el usuario actual cada vez que cambia (login/logout)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Usuario actualmente autenticado (puede ser null)
  User? get currentUser => _auth.currentUser;

  // ── Email / Password ──

  /// Inicia sesión con correo y contraseña
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Registra un nuevo usuario con correo y contraseña
  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Actualiza el displayName del usuario en Firebase Auth
  Future<void> updateDisplayName(String fullName) async {
    await _auth.currentUser?.updateDisplayName(fullName);
  }

  /// Envía email de recuperación de contraseña
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // ── Google Sign In ──

  /// Inicia el flujo de autenticación con Google
  Future<UserCredential?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null; // El usuario canceló

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await _auth.signInWithCredential(credential);
  }

  // ── Cierre de sesión ──

  /// Cierra sesión en Firebase Auth y Google Sign In
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }
}
