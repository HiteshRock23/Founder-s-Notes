import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../features/auth/presentation/screens/login_screen.dart';
import '../providers/settings_provider.dart';

/// ChangePasswordScreen
///
/// Re-authenticates the user and updates their Firebase password.
/// All Firebase logic is handled in [SettingsNotifier].
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _showSnackbar(String message, {bool isError = true}) {
    if (!mounted) return;
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? theme.colorScheme.error : const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final error = await ref.read(settingsProvider.notifier).changePassword(
          currentPassword: _currentPasswordCtrl.text,
          newPassword: _newPasswordCtrl.text,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == null) {
      // Show success message first, then sign out + redirect.
      // The provider has already called signOut(), so AuthGate would handle
      // routing automatically — but we push LoginScreen explicitly to show
      // the success snackbar on the login page and give users a clear signal.
      _showSnackbar(
        'Password updated. Please log in with your new password.',
        isError: false,
      );
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } else {
      _showSnackbar(error);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Change Password',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Info banner ────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF2196F3).withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: Color(0xFF2196F3), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Enter your current password for verification, '
                          'then choose a new password (min. 6 characters).',
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // ── Current password ───────────────────────────────────────
                AppTextField(
                  label: 'Current Password',
                  hintText: '••••••••',
                  controller: _currentPasswordCtrl,
                  obscureText: _obscureCurrent,
                  suffixIcon: _visibilityToggle(
                    obscure: _obscureCurrent,
                    onToggle: () =>
                        setState(() => _obscureCurrent = !_obscureCurrent),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Current password is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // ── New password ───────────────────────────────────────────
                AppTextField(
                  label: 'New Password',
                  hintText: '••••••••',
                  controller: _newPasswordCtrl,
                  obscureText: _obscureNew,
                  suffixIcon: _visibilityToggle(
                    obscure: _obscureNew,
                    onToggle: () =>
                        setState(() => _obscureNew = !_obscureNew),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'New password is required';
                    if (v.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    if (v == _currentPasswordCtrl.text) {
                      return 'New password must differ from current';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // ── Confirm password ───────────────────────────────────────
                AppTextField(
                  label: 'Confirm New Password',
                  hintText: '••••••••',
                  controller: _confirmPasswordCtrl,
                  obscureText: _obscureConfirm,
                  suffixIcon: _visibilityToggle(
                    obscure: _obscureConfirm,
                    onToggle: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Please confirm your new password';
                    }
                    if (v != _newPasswordCtrl.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 36),

                // ── Submit button ──────────────────────────────────────────
                PrimaryButton(
                  text: 'Update Password',
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _handleSubmit,
                ),

                const SizedBox(height: 16),

                // ── Cancel ─────────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _visibilityToggle({
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return IconButton(
      icon: Icon(
        obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        size: 20,
        color:
            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
      ),
      onPressed: onToggle,
    );
  }
}
