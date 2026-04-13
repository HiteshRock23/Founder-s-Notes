import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/auth/domain/entities/user.dart';
// import 'package:mobile/features/auth/presentation/providers/auth_provider.dart'; // REMOVED
// import 'package:mobile/features/auth/domain/repositories/auth_repository.dart'; // REMOVED

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
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // TODO: Fetch user from FirebaseAuth or Firestore
      // final user = await _authRepo.getMe();
      await Future.delayed(const Duration(milliseconds: 500));
      state = state.copyWith(isLoading: false, user: null);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: 'Failed to load user profile.');
    }
  }
}
