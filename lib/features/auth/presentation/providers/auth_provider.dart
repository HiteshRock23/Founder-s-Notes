import 'package:flutter/foundation.dart';
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
  return AuthRepositoryImpl(authService);
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});

// ── Notifier ──────────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(AuthState.initial()) {
    _checkAuthStatus();
  }

  // ── Initialisation ────────────────────────────────────────────────────────

  /// Called on app start.
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
    } on UnimplementedError catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        error: 'Something went wrong. Please try again.',
      );
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await _repository.logout();
    state = AuthState.initial();
  }

  Future<void> register(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _repository.register(name, email, password);
      // Auto-login after successful registration
      await login(email, password);
    } on UnimplementedError catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        error: 'Registration failed. Please try again.',
      );
    }
  }
}
