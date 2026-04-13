import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Login
  Future<UserCredential> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  // Signup
  Future<UserCredential> signup(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Send email verification to the current user.
  //
  // ActionCodeSettings.handleCodeInApp = true: Firebase embeds a deep-link
  // URL so the OS routes the tap back into the app instead of the browser.
  // The DeepLinkService then calls reload() automatically.
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.emailVerified) return;

      final actionCodeSettings = ActionCodeSettings(
        // Must be in Firebase Console → Authentication → Settings →
        // Authorized Domains. The path segment is arbitrary.
        url: 'https://founder-notes-6b8cb.firebaseapp.com/verify-email',

        // KEY: tells Firebase to try to open the native app.
        handleCodeInApp: true,

        // Android — must match applicationId in build.gradle.kts
        androidPackageName: 'com.example.mobile',
        androidInstallApp: true,
        androidMinimumVersion: '21',

        // iOS — must match CFBundleIdentifier in Info.plist
        iOSBundleId: 'com.example.mobile',
      );

      await user.sendEmailVerification(actionCodeSettings);
    } on FirebaseAuthException catch (e) {
      throw _handleError(e);
    }
  }

  // Reload the current user's data from Firebase (refreshes emailVerified)
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  // Check if the current user's email is verified (after reload)
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // Handle Firebase Errors
  Exception _handleError(FirebaseAuthException e) {
    debugPrint('[AuthService] Firebase error: ${e.code}');
    switch (e.code) {
      case 'invalid-email':
        return Exception('Invalid email address.');
      case 'user-not-found':
        return Exception('User not found. Please check your credentials.');
      case 'wrong-password':
        return Exception('Incorrect password.');
      case 'invalid-credential':
        return Exception('Invalid credentials provided.');
      case 'email-already-in-use':
        return Exception('Email is already registered. Please sign in instead.');
      case 'weak-password':
        return Exception('Password is too weak.');
      case 'operation-not-allowed':
        return Exception('This authentication method is disabled.');
      case 'network-request-failed':
        return Exception('Network error. Please check your connection.');
      case 'too-many-requests':
        return Exception('Too many attempts. Please wait a moment before trying again.');
      case 'user-disabled':
        return Exception('This account has been disabled. Please contact support.');
      default:
        return Exception(e.message ?? 'An unknown authentication error occurred.');
    }
  }
}

// Global instance for simple dependency injection
final authService = AuthService();
