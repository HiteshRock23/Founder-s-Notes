import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/email_verification_screen.dart';
import '../navigation/main_shell.dart';

/// AuthGate — single source of truth for authentication routing.
///
/// Three states:
///   1. user == null              → LoginScreen
///   2. user && !emailVerified   → EmailVerificationScreen
///   3. user && emailVerified    → MainShell
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.idTokenChanges(), // fires on token refresh, including emailVerified changes
      builder: (context, snapshot) {
        // Still waiting for the auth state to resolve
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          );
        }

        final user = snapshot.data;

        // No session → go to login
        if (user == null) {
          return const LoginScreen();
        }

        // Session exists but email not verified → verification gate
        if (!user.emailVerified) {
          return const EmailVerificationScreen();
        }

        // Fully authenticated and verified → main app
        return const MainShell();
      },
    );
  }
}

