import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class SettingsState {
  final bool isLoading;
  final String? error;
  final String? email;
  final String? displayName;

  const SettingsState({
    this.isLoading = false,
    this.error,
    this.email,
    this.displayName,
  });

  SettingsState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? email,
    String? displayName,
  }) {
    return SettingsState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
    );
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

// ── Notifier ──────────────────────────────────────────────────────────────────

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    _loadUser();
  }

  /// Reads the currently signed-in Firebase user and populates the state.
  void _loadUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      state = state.copyWith(
        email: user.email,
        displayName: user.displayName,
        clearError: true,
      );
    }
  }

  /// Refresh user data (call after profile updates).
  Future<void> refreshUser() async {
    await FirebaseAuth.instance.currentUser?.reload();
    _loadUser();
  }

  /// Re-authenticates the user then updates their password.
  ///
  /// Returns `null` on success, or a user-friendly error message on failure.
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      state = state.copyWith(isLoading: false, error: 'No signed-in user.');
      return 'No signed-in user.';
    }

    try {
      // Step 1: Re-authenticate (required by Firebase before sensitive ops)
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Step 2: Update password
      await user.updatePassword(newPassword);

      // Step 3: Force session reset — CRITICAL.
      // Firebase does not invalidate the existing token automatically after a
      // password change. Signing out ensures the user must authenticate fresh
      // with the new password, preventing old-credential confusion.
      await FirebaseAuth.instance.signOut();

      state = state.copyWith(isLoading: false, clearError: true);
      return null; // success
    } on FirebaseAuthException catch (e) {
      final msg = _mapFirebaseError(e.code);
      state = state.copyWith(isLoading: false, error: msg);
      return msg;
    } catch (e) {
      const msg = 'An unexpected error occurred. Please try again.';
      state = state.copyWith(isLoading: false, error: msg);
      return msg;
    }
  }

  /// Maps Firebase error codes to user-friendly messages.
  String _mapFirebaseError(String code) {
    switch (code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'Current password is incorrect.';
      case 'weak-password':
        return 'New password is too weak. Use at least 6 characters.';
      case 'requires-recent-login':
        return 'Session expired. Please sign out and sign in again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      default:
        return 'Password update failed. Please try again.';
    }
  }
}
