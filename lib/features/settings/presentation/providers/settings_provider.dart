import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/auth/domain/entities/user.dart';
import 'package:mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';

class SettingsState {
  final bool isLoading;
  final String? error;
  final User? user;

  const SettingsState({
    this.isLoading = false,
    this.error,
    this.user,
  });

  SettingsState copyWith({
    bool? isLoading,
    String? error,
    User? user,
  }) {
    return SettingsState(
      isLoading: isLoading ?? this.isLoading,
      error:
          error, // Clear error if null is passed (or we can use a more robust optional semantic, but this is fine for basic reset)
      user: user ?? this.user,
    );
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return SettingsNotifier(authRepo);
});

class SettingsNotifier extends StateNotifier<SettingsState> {
  final AuthRepository _authRepo;

  SettingsNotifier(this._authRepo) : super(const SettingsState()) {
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _authRepo.getMe();
      state = state.copyWith(isLoading: false, user: user);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: 'Failed to load user profile.');
    }
  }
}
