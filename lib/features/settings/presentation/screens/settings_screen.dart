import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../features/auth/data/auth_service.dart';
import '../../../../features/auth/presentation/screens/login_screen.dart';
import '../../../../features/settings/presentation/providers/settings_provider.dart';
import 'change_password_screen.dart';

/// SettingsScreen — account management, preferences, and app info.
///
/// Reads the current Firebase user via [SettingsNotifier] (clean layer).
/// All Firebase sign-out logic goes through [AuthService].
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeProvider);
    final settingsState = ref.watch(settingsProvider);

    // Snackbar on transient errors
    ref.listen<SettingsState>(settingsProvider, (previous, next) {
      if (next.error != null && previous?.error != next.error) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(next.error!),
              backgroundColor: theme.colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(16),
            ),
          );
      }
    });

    final email = settingsState.email;
    final initials = _initials(email);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 20,
      ),
      body: ListView(
        children: [
          // ── Account ────────────────────────────────────────────────────────
          const _SectionHeader('Account'),
          _AccountTile(
            email: email ?? 'Not logged in',
            initials: initials,
            isLoading: settingsState.isLoading,
          ),
          _SettingsTile(
            icon: Icons.lock_outline,
            title: 'Change Password',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ChangePasswordScreen(),
                ),
              );
            },
          ),

          const Divider(height: 1),

          // ── Preferences ────────────────────────────────────────────────────
          const _SectionHeader('Preferences'),
          _NotificationsTile(),
          SwitchListTile(
            title: const Text(
              'Dark Mode',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            value: themeMode == ThemeMode.dark,
            onChanged: (value) {
              ref
                  .read(themeProvider.notifier)
                  .setTheme(value ? ThemeMode.dark : ThemeMode.light);
            },
            secondary: const Icon(
              Icons.dark_mode_outlined,
              color: Color(0xFF2196F3),
              size: 22,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            activeTrackColor: const Color(0xFF2196F3),
          ),

          const Divider(height: 1),

          // ── About ──────────────────────────────────────────────────────────
          const _SectionHeader('About'),
          _SettingsTile(
            icon: Icons.info_outline,
            title: 'App Version',
            subtitle: '1.0.0',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.description_outlined,
            title: 'Terms & Privacy',
            onTap: () {},
          ),

          const SizedBox(height: 24),

          // ── Sign Out ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: OutlinedButton.icon(
              onPressed: () => _showLogoutDialog(context),
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text(
                'Sign Out',
                style: TextStyle(color: Colors.red),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _initials(String? email) {
    if (email == null || email.isEmpty) return '?';
    return email[0].toUpperCase();
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  await authService.logout();
                  // AuthGate re-routes automatically on auth state change.
                  // In case it doesn't (edge case), force-push LoginScreen.
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Sign out failed. Please try again.')),
                    );
                  }
                }
              },
              child:
                  const Text('Sign Out', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}

// ── Private widgets ────────────────────────────────────────────────────────────

/// Avatar + email tile for the Account section.
class _AccountTile extends StatelessWidget {
  final String email;
  final String initials;
  final bool isLoading;

  const _AccountTile({
    required this.email,
    required this.initials,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          // Avatar circle
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    initials,
                    style: const TextStyle(
                      color: Color(0xFF2196F3),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          // Email + label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Logged in account',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Stateful notifications tile with a toggle switch.
class _NotificationsTile extends StatefulWidget {
  @override
  State<_NotificationsTile> createState() => _NotificationsTileState();
}

class _NotificationsTileState extends State<_NotificationsTile> {
  bool _enabled = true;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: const Icon(
        Icons.notifications_none_rounded,
        color: Color(0xFF2196F3),
        size: 22,
      ),
      title: const Text(
        'Notifications',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        _enabled ? 'Push and email alerts enabled' : 'Notifications muted',
        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
      ),
      value: _enabled,
      onChanged: (v) => setState(() => _enabled = v),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      activeTrackColor: const Color(0xFF2196F3),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey[500],
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF2196F3), size: 22),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            )
          : null,
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }
}
