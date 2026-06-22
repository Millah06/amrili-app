

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/verification/verification_cache.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';




class AuthProvider extends ChangeNotifier {
  final ApiService api;
  AuthProvider({required this.api, bool initialGuest = false}) {
    _isGuest = initialGuest;
  }

  String? _error;
  bool _isGuest = false;
  bool _isLoading = false;

  /// Raw user map returned from the backend after any auth method.
  /// UserProvider uses this to seed local state without an extra API call.
  Map<String, dynamic>? _authUserData;

  String? get error => _error;

  bool get isLoading => _isLoading;
  bool get isGuest => _isGuest;
  bool get isAuthenticated => FirebaseAuth.instance.currentUser != null;
  Map<String, dynamic>? get authUserData => _authUserData;

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  // ─── Guest Mode ──────────────────────────────────────────────────────────

  Future<void> continueAsGuest() async {
    _isGuest = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isGuest', true);
  }

  Future<void> exitGuest() async {
    _isGuest = false;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isGuest');
  }



  // ─── Email Sign Up ───────────────────────────────────────────────────────────
  // Phone and referral are NO LONGER part of signup.
  // They are collected in SecurityStep1Screen after signup.

  Future<String> signUp({required String name, required String email, required String password,}) async {
    _clearError();
    try {
      _setLoading(true);
      final data = await api.post('/auth/register', {
        'name': name,
        'email': email,
        'password': password,
      });
      await FirebaseAuth.instance.signInWithCustomToken(data['customToken']);
      await PushNotificationService().saveTokenToFirestore();
      _authUserData = data['user'] as Map<String, dynamic>?;
      await VerificationCache.hydrateFromNetwork();

      _isGuest = false;

      notifyListeners();
      return FirebaseAuth.instance.currentUser!.uid;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Email Sign In ───────────────────────────────────────────────────────────

  Future<String> signIn({required String email, required String password,}) async {
    _clearError();
    try {
      _setLoading(true);
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      final idToken = await credential.user!.getIdToken();
      final data = await api.post('/auth/login', {'idToken': idToken});
      await PushNotificationService().saveTokenToFirestore();
      _authUserData = data['user'] as Map<String, dynamic>?;
      await VerificationCache.hydrateFromNetwork();
      _isGuest = false;
      notifyListeners();
      return FirebaseAuth.instance.currentUser!.uid;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Google Sign In ──────────────────────────────────────────────────────────
  //
  // Two paths:
  //   Web  — FirebaseAuth.signInWithPopup uses the Firebase JS SDK which
  //           handles the OAuth pop-up natively; no CORS or client-ID setup
  //           required beyond what Firebase already has.
  //   Mobile — GoogleSignIn package (v7 API: initialize + authenticate).
  //           Fixed bug: accessToken was incorrectly sent idToken value.

  Future<SocialAuthResult> signInWithGoogle() async {
    _clearError();
    try {
      _setLoading(true);

      late UserCredential userCredential;

      if (kIsWeb) {
        // Web: Firebase JS SDK handles the OAuth pop-up.
        final provider = GoogleAuthProvider();
        userCredential =
            await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        // Mobile: native GoogleSignIn package.
        final googleSignIn = GoogleSignIn.instance;
        await googleSignIn.initialize();
        final googleUser = await googleSignIn.authenticate();
        final googleAuth = googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );
        userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);
      }

      final idToken = await userCredential.user!.getIdToken(true);
      final data = await api.post('/auth/social', {
        'idToken': idToken,
        'provider': 'google',
        'name': userCredential.user!.displayName,
        'email': userCredential.user!.email,
      });

      await PushNotificationService().saveTokenToFirestore();
      _authUserData = data['user'] as Map<String, dynamic>?;
      await VerificationCache.hydrateFromNetwork();
      _isGuest = false;
      notifyListeners();

      return SocialAuthResult(
        uid: FirebaseAuth.instance.currentUser!.uid,
        isNewUser: data['isNewUser'] as bool? ?? false,
      );
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Apple Sign In (iOS only) ────────────────────────────────────────────────

  Future<SocialAuthResult> signInWithApple() async {
    _clearError();
    try {
      _setLoading(true);
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
      final userCredential =
      await FirebaseAuth.instance.signInWithCredential(oauthCredential);
      final idToken = await userCredential.user!.getIdToken(true);

      final name =
      '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'
          .trim();

      final data = await api.post('/auth/social', {
        'idToken': idToken,
        'provider': 'apple',
        'name': name.isNotEmpty ? name : (userCredential.user!.displayName ?? ''),
        'email': appleCredential.email ?? userCredential.user!.email,
      });

      await PushNotificationService().saveTokenToFirestore();
      _authUserData = data['user'] as Map<String, dynamic>?;
      await VerificationCache.hydrateFromNetwork();
      _isGuest = false;
      notifyListeners();

      return SocialAuthResult(uid: FirebaseAuth.instance.currentUser!.uid, isNewUser: data['isNewUser'] as bool? ?? false,
      );
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Sign Out ────────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;

      await googleSignIn.signOut();
    } catch (_) {}
    _isGuest = false;
    _authUserData = null;
    notifyListeners();
  }
}





class SocialAuthResult {
  final String uid;
  final bool isNewUser;
  const SocialAuthResult({required this.uid, required this.isNewUser});
}