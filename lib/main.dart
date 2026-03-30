import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/navigation/main_shell.dart';
import 'core/utils/url_normalizer.dart';
import 'features/capture/presentation/screens/capture_screen.dart';
import 'core/navigation/auth_gate.dart';
import 'features/auth/presentation/screens/login_screen.dart';

final navigatorKey = GlobalKey<NavigatorState>();

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

class FounderApp extends ConsumerStatefulWidget {
  const FounderApp({super.key});

  @override
  ConsumerState<FounderApp> createState() => _FounderAppState();
}

class _FounderAppState extends ConsumerState<FounderApp> {
  late StreamSubscription _intentDataStreamSubscription;
  bool _isHandlingIntent = false;

  @override
  void initState() {
    super.initState();
    _initShareIntentListeners();
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  void _initShareIntentListeners() {
    // 1. Warm start (app already running in background)
    _intentDataStreamSubscription =
        ReceiveSharingIntent.instance.getMediaStream().listen(
      (List<SharedMediaFile> value) {
        if (value.isNotEmpty) {
          // Usually text/URLs shared from browser are in the `path` or `message` property depending on OS
          _handleSharedText(value.first.path);
        }
      },
      onError: (err) {
        debugPrint("getIntentDataStream error: $err");
      },
    );

    // 2. Cold start (app was closed)
    ReceiveSharingIntent.instance
        .getInitialMedia()
        .then((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        _handleSharedText(value.first.path);
      }
    });
  }

  void _handleSharedText(String text) {
    if (_isHandlingIntent) return;

    // [Edge case 3] Extract URL safely from multiline text
    final normalizedUrl = UrlNormalizer.extractUrl(text);

    if (normalizedUrl != null) {
      // [Edge case 1] Guard against duplicate intent firing
      _isHandlingIntent = true;

      // [Edge case 2] Handle authentication-first routing:
      // Since Dev Mode skips auth, we navigate straight to the Capture Screen.
      // In production, we would check `ref.read(authProvider)` and redirect to
      // LoginScreen first if not authenticated, persisting the intent locally.

      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKey.currentState
            ?.push(
          MaterialPageRoute(
            builder: (context) => CaptureScreen(url: normalizedUrl),
          ),
        )
            .then((_) {
          // When CaptureScreen is popped, reset flag
          _isHandlingIntent = false;
        });
      });
    } else {
      // Clear intent if no URL found to prevent ghost reroutes
      ReceiveSharingIntent.instance.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Founder Notes',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const AuthGate(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const MainShell(),
      },
    );
  }
}
