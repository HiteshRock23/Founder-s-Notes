import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../navigation/main_shell.dart';

/// AuthGate sits at the root of the widget tree and reactively switches
/// between LoginScreen and MainShell based on the auth state.
///
/// Why reactive instead of imperative navigation?
/// • No Navigator.push race conditions.
/// • Survives hot reload.
/// • Auth state drives UI — a single source of truth.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // Show a splash while we check if a stored token exists.
    if (authState.isLoading) {
      return const _SplashScreen();
    }

    if (authState.isAuthenticated) {
      return const MainShell();
    }

    return const LoginScreen();
  }
}

// ── Minimal splash (shown only ~100ms on start) ────────────────────────────

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.hub_outlined,
                color: theme.colorScheme.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
