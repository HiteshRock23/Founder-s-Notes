import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/errors/api_exception.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/features/auth/data/auth_service.dart';
import 'package:mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile/features/auth/presentation/providers/auth_state.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final authServiceProvider = Provider<AuthService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return AuthService(dioClient);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final authService = ref.watch(authServiceProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return AuthRepositoryImpl(authService, tokenStorage);
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final notifier = AuthNotifier(repository);

  // Register the global force-logout callback in the Dio layer.
  // This allows the 401 interceptor to log the user out without a
  // circular dependency on Riverpod inside the network layer.
  registerForceLogoutCallback(() => notifier.forceLogout());

  return notifier;
});

// ── Notifier ──────────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(AuthState.initial()) {
    _checkAuthStatus();
  }

  // ── Initialisation ────────────────────────────────────────────────────────

  /// Called on app start. Reads the stored token to determine
  /// whether the user is already authenticated.
  Future<void> _checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    final isAuthenticated = await _repository.isAuthenticated();
    state = state.copyWith(
      isLoading: false,
      isAuthenticated: isAuthenticated,
    );
  }

  // ── Login ─────────────────────────────────────────────────────────────────

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _repository.login(email, password);
      state = state.copyWith(isLoading: false, isAuthenticated: true);
    } on UnauthenticatedException {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        error: 'Invalid email or password.',
      );
    } on ValidationException catch (e) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        error: e.message,
      );
    } on NetworkException {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        error: 'Cannot connect to the server. Check your internet connection.',
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        error: 'Something went wrong. Please try again.',
      );
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  /// Explicit user-initiated logout.
  Future<void> logout() async {
    await _repository.logout();
    state = AuthState.initial();
  }

  /// Force-logout triggered by the Dio interceptor when the refresh token
  /// itself has expired. Clears storage (already done by interceptor) and
  /// resets state so the AuthGate redirects to LoginScreen.
  Future<void> forceLogout() async {
    state = AuthState.initial();
  }
}
