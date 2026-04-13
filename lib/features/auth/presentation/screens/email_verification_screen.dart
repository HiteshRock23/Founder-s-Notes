import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_service.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  bool _isCheckingVerification = false;
  bool _isResending = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;
  Timer? _autoCheckTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startAutoCheck();

    // Pulse animation for the email icon — subtle 'waiting' feedback.
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cooldownTimer?.cancel();
    _autoCheckTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  // Resume app lifecycle: re-check if user just came back from email client
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkVerification(silent: true);
    }
  }

  void _startAutoCheck() {
    _autoCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkVerification(silent: true);
    });
  }

  Future<void> _checkVerification({bool silent = false}) async {
    if (_isCheckingVerification) return;

    if (!silent) {
      setState(() => _isCheckingVerification = true);
    }

    try {
      // Step 1: Reload the user object from Firebase servers.
      // This is the ONLY call needed — it refreshes emailVerified on the
      // cached User object and causes idTokenChanges() in AuthGate to emit.
      //
      // ⚠️  Do NOT call getIdToken(true) immediately after reload().
      //     Both calls go through the Pigeon platform channel to Android/iOS.
      //     Running them concurrently puts the internal UserInfo decode into a
      //     race condition where the Dart side receives a raw List<Object?>
      //     instead of a fully-decoded PigeonUserInfo, crashing with:
      //     "type 'List<Object?>' is not a subtype of type 'PigeonUserInfo'"
      //
      // idTokenChanges() emits automatically after reload() — no manual
      // token push is required.
      debugPrint('[EmailVerification] Calling reload() on current user...');
      debugPrint(
        '[EmailVerification] currentUser runtimeType before reload: '
        '${FirebaseAuth.instance.currentUser.runtimeType}',
      );

      await FirebaseAuth.instance.currentUser?.reload();

      // Step 2: Always re-fetch from FirebaseAuth.instance.currentUser
      // AFTER reload — the local User reference captured before reload()
      // is a stale snapshot and will not reflect emailVerified = true.
      final updatedUser = FirebaseAuth.instance.currentUser;

      debugPrint(
        '[EmailVerification] After reload — user: ${updatedUser?.uid}, '
        'emailVerified: ${updatedUser?.emailVerified}, '
        'runtimeType: ${updatedUser.runtimeType}',
      );

      if (updatedUser == null) {
        // Session expired — idTokenChanges() will emit null and AuthGate
        // will route to LoginScreen automatically.
        debugPrint('[EmailVerification] User is null after reload — session expired.');
        return;
      }

      if (updatedUser.emailVerified) {
        _autoCheckTimer?.cancel();
        debugPrint('[EmailVerification] ✅ Email verified! AuthGate will navigate to MainShell.');
        // idTokenChanges() already receives the updated state from reload().
        // AuthGate's StreamBuilder rebuilds and routes to MainShell.
        return;
      }

      debugPrint('[EmailVerification] Email not yet verified.');

      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Email not verified yet. Please check your inbox.',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Catch Firebase-specific errors (network, token revoked, etc.) separately
      // so a platform-channel hiccup doesn't crash the whole screen.
      debugPrint('[EmailVerification] FirebaseAuthException: ${e.code} — ${e.message}');
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Authentication error. Please try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e, stack) {
      // Broad catch so a Pigeon decode error or any other unexpected exception
      // surfaces as a readable message rather than an uncaught crash.
      debugPrint('[EmailVerification] Unexpected error during reload: $e\n$stack');
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (!silent && mounted) {
        setState(() => _isCheckingVerification = false);
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (_isResending || _resendCooldown > 0) return;

    setState(() => _isResending = true);

    try {
      await authService.sendEmailVerification();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Verification email sent! Check your inbox.'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }

      // Start 60-second cooldown
      setState(() => _resendCooldown = 60);
      _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          _resendCooldown--;
          if (_resendCooldown <= 0) {
            timer.cancel();
          }
        });
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  Future<void> _logout() async {
    await authService.logout();
    // AuthGate will handle the navigation back to LoginScreen
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final email = authService.currentUser?.email ?? 'your email';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () async => _logout(),
            child: Text(
              'Sign Out',
              style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              // Pulsing email icon
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.mark_email_unread_outlined,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),

              // Deep-link active badge
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.link_rounded, size: 13, color: Colors.green),
                    const SizedBox(width: 5),
                    Text(
                      'Deep link active — opens app automatically',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Text(
                'Verify Your Email',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'We sent a verification link to:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Tap the link in your email — the app opens automatically.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Verification card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // "I Have Verified" primary button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isCheckingVerification
                            ? null
                            : () async {
                                await _checkVerification();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isCheckingVerification
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_outline, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    "I've Verified My Email",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Resend email button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: (_isResending || _resendCooldown > 0)
                            ? null
                            : () async {
                                await _resendVerificationEmail();
                              },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: _resendCooldown > 0
                                ? theme.colorScheme.outline.withValues(alpha: 0.3)
                                : theme.colorScheme.primary,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isResending
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.primary,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.refresh_rounded,
                                    size: 20,
                                    color: _resendCooldown > 0
                                        ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
                                        : theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _resendCooldown > 0
                                        ? 'Resend in ${_resendCooldown}s'
                                        : 'Resend Verification Email',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: _resendCooldown > 0
                                          ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
                                          : theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Hint row — reflects the new deep-link UX
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.auto_awesome_outlined,
                        size: 14,
                        color: theme.colorScheme.primary.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Tapping the email link opens the app instantly',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 13,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Also auto-checking every 5 s as fallback',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
