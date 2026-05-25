import 'package:firebase_auth/firebase_auth.dart' as auth;

/// Service untuk mengelola autentikasi pengguna menggunakan Firebase Auth
/// Mendukung Register, Login, dan Logout
class AuthService {
  final auth.FirebaseAuth _firebaseAuth = auth.FirebaseAuth.instance;

  // Stream untuk memantau perubahan status autentikasi
  Stream<auth.User?> get user {
    return _firebaseAuth.authStateChanges();
  }

  // Login dengan Email dan Password
  Future<auth.User?> signIn(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } catch (e) {
      rethrow;
    }
  }

  // Register dengan Email dan Password
  Future<auth.User?> signUp(String email, String password) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } catch (e) {
      rethrow;
    }
  }

  // Logout
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  // Mendapatkan user yang sedang login
  auth.User? get currentUser => _firebaseAuth.currentUser;
}