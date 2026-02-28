import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'core/navigation/main_shell.dart';
// TODO: Re-enable auth when ready for production
// import 'features/auth/presentation/screens/login_screen.dart';
// import 'features/auth/presentation/providers/auth_provider.dart';

void main() {
  runApp(
    const ProviderScope(
      child: FounderApp(),
    ),
  );
}

class FounderApp extends StatelessWidget {
  const FounderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Founder Notes',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // DEV MODE: skipping auth — goes straight to the navigation shell.
      // Production: replace `home` with a router (GoRouter or Navigator 2.0)
      // that shows LoginScreen for unauthenticated users and MainShell for
      // authenticated ones.
      home: const MainShell(),
    );
  }
}
