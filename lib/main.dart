import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/navigation/main_shell.dart';
// TODO: Re-enable auth when ready for production
// import 'features/auth/presentation/screens/login_screen.dart';
// import 'features/auth/presentation/providers/auth_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(sharedPreferences),
      ],
      child: const FounderApp(),
    ),
  );
}

class FounderApp extends ConsumerWidget {
  const FounderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Founder Notes',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      // DEV MODE: skipping auth — goes straight to the navigation shell.
      // Production: replace `home` with a router (GoRouter or Navigator 2.0)
      // that shows LoginScreen for unauthenticated users and MainShell for
      // authenticated ones.
      home: const MainShell(),
    );
  }
}
