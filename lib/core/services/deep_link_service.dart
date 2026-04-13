import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Singleton service that handles incoming App Links (Android) and
/// Universal Links (iOS) for Firebase email-action deep links.
///
/// ──────────────────────────────────────────────────────────────────────────
/// How it fits into the auth flow
/// ──────────────────────────────────────────────────────────────────────────
///
///  1. User registers → [AuthService.sendEmailVerification()] sends an email
///     with ActionCodeSettings(handleCodeInApp: true).
///  2. User taps the link in their inbox.
///  3. Android App Links / iOS Universal Links open the app instead of browser.
///  4. [DeepLinkService] receives the URI on cold or warm start.
///  5. If mode=verifyEmail, it calls [FirebaseAuth.instance.currentUser?.reload()].
///  6. [FirebaseAuth.instance.idTokenChanges()] emits an updated [User] with
///     emailVerified = true.
///  7. [AuthGate]'s StreamBuilder rebuilds and routes to [MainShell].
///     Zero manual navigation needed.
///
/// ──────────────────────────────────────────────────────────────────────────
/// Conflict-free co-existence with receive_sharing_intent
/// ──────────────────────────────────────────────────────────────────────────
///
/// [receive_sharing_intent] captures android.intent.action.SEND (share sheet)
/// URIs — a completely different intent action from android.intent.action.VIEW
/// (App Links). They do NOT conflict. However both packages listen to the
/// incoming URI stream so we filter strictly on mode=verifyEmail to avoid
/// any false positives.
///
class DeepLinkService {
  DeepLinkService._();

  /// The singleton. Use [DeepLinkService.instance] everywhere.
  static final DeepLinkService instance = DeepLinkService._();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;
  bool _initialised = false;

  // ──────────────────────────────────────────────────────────────────────────
  // Public API
  // ──────────────────────────────────────────────────────────────────────────

  /// Initialise the service. Safe to call multiple times — subsequent calls
  /// are no-ops.
  ///
  /// **Must** be called after [Firebase.initializeApp()] in main().
  Future<void> init() async {
    if (_initialised) return;
    _initialised = true;

    // ── 1. Cold start: app was launched by tapping the link ───────────────
    //    getInitialLink() returns the URI that caused the app to launch,
    //    or null if the app was opened normally.
    try {
      final Uri? initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint('[DeepLink] Cold-start URI: $initialUri');
        await _handleUri(initialUri);
      }
    } catch (e) {
      // Never crash app startup due to a deep-link read failure.
      debugPrint('[DeepLink] Error reading initial link: $e');
    }

    // ── 2. Warm start: app is in foreground/background, link arrives ───────
    //    uriLinkStream emits every time a new URI is delivered to the app
    //    while it is running.
    _sub = _appLinks.uriLinkStream.listen(
      (Uri uri) async {
        debugPrint('[DeepLink] Warm-start URI: $uri');
        await _handleUri(uri);
      },
      onError: (Object err) {
        debugPrint('[DeepLink] Stream error: $err');
      },
    );
  }

  /// Call this if you ever need to restart the service (rarely needed).
  Future<void> restart() async {
    await dispose();
    _initialised = false;
    await init();
  }

  /// Cancel the stream subscription. Called when the root widget is destroyed.
  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Private logic
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _handleUri(Uri uri) async {
    // ── Guard 1: only act on Firebase email-action links ──────────────────
    // Firebase embeds mode=verifyEmail when ActionCodeSettings.handleCodeInApp
    // is true and the link type is email verification.
    //
    // Other Firebase link types (resetPassword, signIn, etc.) also pass
    // through here but are NOT handled — they will be logged and dropped.
    final String? mode = uri.queryParameters['mode'];

    debugPrint('[DeepLink] URI mode=$mode  host=${uri.host}  path=${uri.path}');

    if (mode != 'verifyEmail') {
      // Not our concern — share-sheet URIs, password-reset links, etc.
      debugPrint('[DeepLink] Skipping URI (mode=$mode is not verifyEmail).');
      return;
    }

    // ── Guard 2: must have a signed-in user ───────────────────────────────
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint(
        '[DeepLink] verifyEmail link received but no user is signed in. '
        'Ignoring — login UI will handle the session.',
      );
      return;
    }

    // ── Guard 3: skip if already verified (idempotency) ───────────────────
    if (user.emailVerified) {
      debugPrint('[DeepLink] User is already verified — no reload needed.');
      return;
    }

    debugPrint('[DeepLink] Calling reload() for uid=${user.uid}...');

    try {
      // ⚠️  Critical: call reload() ONLY, not getIdToken(true) simultaneously.
      //
      // Concurrent Pigeon platform-channel calls (reload + getIdToken) can
      // put the internal UserInfo deserialiser into a race condition, causing:
      //   "type 'List<Object?>' is not a subtype of type 'PigeonUserInfo'"
      //
      // reload() alone is sufficient:
      //   • Refreshes the cached User.emailVerified to true.
      //   • Triggers FirebaseAuth.idTokenChanges() to emit the updated User.
      //   • AuthGate's StreamBuilder rebuilds → shows MainShell. ✅
      await user.reload();

      final User? updated = FirebaseAuth.instance.currentUser;
      debugPrint(
        '[DeepLink] After reload → '
        'uid=${updated?.uid}  emailVerified=${updated?.emailVerified}',
      );
    } on FirebaseAuthException catch (e) {
      // e.g. user-not-found if the account was deleted between sending
      // the email and clicking the link.
      debugPrint('[DeepLink] FirebaseAuthException: ${e.code} — ${e.message}');
    } catch (e, st) {
      debugPrint('[DeepLink] Unexpected error during reload(): $e\n$st');
    }
  }
}
