import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'features/projects/presentation/screens/projects_screen.dart';
// TODO: Re-enable auth when ready for production
// import 'features/auth/presentation/screens/login_screen.dart';
// import 'features/auth/presentation/screens/signup_screen.dart';
// import 'features/auth/presentation/providers/auth_provider.dart';

void main() {
  runApp(
    const ProviderScope(
      child: FounderApp(),
    ),
  );
}

class AppRoutes {
  static const String dashboard = '/dashboard';
}

class FounderApp extends StatelessWidget {
  const FounderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Founder Project Knowledge Hub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // DEV MODE: skipping auth — goes straight to dashboard
      home: const ProjectsScreen(),
    );
  }
}
