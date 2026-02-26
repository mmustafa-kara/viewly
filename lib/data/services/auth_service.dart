import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with identifier (email or username) and password.
  /// If identifier contains '@', treat as email; otherwise look up username in Firestore.
  Future<User?> signInWithIdentifier(String identifier, String password) async {
    try {
      String email;

      if (identifier.contains('@')) {
        // Identifier is an email
        email = identifier;
      } else {
        // Identifier is a username — look up email from Firestore
        final query = await _firestore
            .collection('users')
            .where('username', isEqualTo: identifier.toLowerCase())
            .limit(1)
            .get();

        if (query.docs.isEmpty) {
          throw 'Kullanıcı bulunamadı.';
        }

        email = query.docs.first.data()['email'] as String;
      }

      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Legacy email/password sign-in (kept for compatibility)
  Future<User?> signInWithEmailPassword(String email, String password) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign up with username, email, and password.
  /// Checks Firestore to ensure username is unique, creates the Auth user,
  /// and saves the user document to Firestore atomically.
  Future<User?> signUpWithUsernameEmailPassword({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      // Normalize username to lowercase
      final normalizedUsername = username.toLowerCase();

      // Check if username is already taken
      final usernameQuery = await _firestore
          .collection('users')
          .where('username', isEqualTo: normalizedUsername)
          .limit(1)
          .get();

      if (usernameQuery.docs.isNotEmpty) {
        throw 'Bu kullanıcı adı zaten alınmış.';
      }

      // Create Firebase Auth user
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // CRITICAL: Save user document to Firestore BEFORE returning,
      // so it completes before AuthGate redirects away from SignUpScreen.
      if (result.user != null) {
        await _firestore.collection('users').doc(result.user!.uid).set({
          'email': email,
          'username': normalizedUsername,
          'displayName': null,
          'photoUrl': null,
          'bio': null,
          'location': null,
          'followersCount': 0,
          'followingCount': 0,
          'postsCount': 0,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        });
      }

      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Legacy sign-up (kept for compatibility)
  Future<User?> signUpWithEmailPassword(String email, String password) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Delete current user account
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Delete user's document from Firestore first
        await _firestore.collection('users').doc(user.uid).delete();
        // Then delete the Firebase Auth user
        await user.delete();
      } else {
        throw 'Oturum açık bir kullanıcı bulunamadı.';
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw 'Bu işlem hassas olduğu için yeniden giriş yapmanız gerekmektedir. Lütfen çıkış yapıp tekrar girin.';
      }
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Hesap silinirken bir hata oluştu: $e';
    }
  }

  /// Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
        return 'E-posta adresi veya şifre hatalı.';
      case 'user-not-found':
        return 'Kullanıcı bulunamadı.';
      case 'wrong-password':
        return 'Yanlış şifre.';
      case 'email-already-in-use':
        return 'Bu e-posta zaten kullanımda.';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi.';
      case 'weak-password':
        return 'Şifre çok zayıf. En az 6 karakter olmalıdır.';
      case 'operation-not-allowed':
        return 'Bu işlem şu anda kullanılamıyor.';
      default:
        return 'Bir hata oluştu: ${e.message}';
    }
  }
}
