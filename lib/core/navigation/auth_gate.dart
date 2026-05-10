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
class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  late final Stream<User?> _authStateStream;

  @override
  void initState() {
    super.initState();
    // Cache the stream here so it's not recreated on every build
    _authStateStream = FirebaseAuth.instance.idTokenChanges();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authStateStream, // fires on token refresh, including emailVerified changes
      builder: (context, snapshot) {
        debugPrint('[AuthGate] builder called: connectionState=${snapshot.connectionState}, user=${snapshot.data?.uid}');
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

