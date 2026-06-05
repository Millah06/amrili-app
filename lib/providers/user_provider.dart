import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/api_service.dart';

class UserProvider extends ChangeNotifier {

  final ApiService api;
  UserProvider({required this.api});

  User ?  user;

  bool loadingUser = false;

  String? error;

  String preferredBank = 'wema-bank';

  void getUserId () async {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser != null) {
      var tokenResult = await firebaseUser.getIdTokenResult();

      var postgresId = tokenResult.claims?['postgresId'];

      if (postgresId == null) {
        // Force refresh token
        tokenResult = await firebaseUser.getIdTokenResult(true);

        postgresId = tokenResult.claims?['postgresId'];
        // user = user?.copyWith(userId: postgresId);
        user = User.fromJson({'id' : postgresId});
        notifyListeners();

        if (postgresId == null) {
          // LAST fallback
          await loadUser(silent: false);

          return;

        }
      }

      if (postgresId != null) {
        // user = user?.copyWith(userId: postgresId);
        user = User.fromJson({'id' : postgresId});
        notifyListeners();

        print('hey😂 I am postres Id $postgresId');
      }
    }
  }

  // Add to UserProvider class:

  /// Safely initialises user data only if a Firebase session already exists.
  /// Called at app startup. Returns immediately for logged-out / first-launch users,
  /// shows SplashScreen (via loadingUser flag) for returning authenticated users.
  Future<void> initIfAuthenticated() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return; // first launch / logged out — skip
    getUserId();
    await loadUser(silent: false); // silent: false → shows SplashScreen while loading
  }

  Future<void> loadUser({bool silent = true}) async {
    silent == false ? loadingUser = true : null;
    notifyListeners();
    try {
      final data = await api.get('/users/me');
      user = User.fromJson(data);
      print("parsed");
    } catch (e) {
      print('❌ parsing failed $e');
      error = e.toString();
    } finally {
      silent == false ? loadingUser = false : null;
      notifyListeners();
    }
  }

  void setPreferredBank(String bankName) {
    preferredBank = bankName;
    notifyListeners();
  }
  
  Future<bool> generateVirtualAccount() async {
    try {
      final data = await api.post('/virtual-accounts', {
        'preferredBank': preferredBank
      });
      return true;
    }
    catch (e) {
      rethrow;
    }
  }

  void seedFromAuth(Map<String, dynamic> json) {
    user = User.fromJson(json);
    notifyListeners();
  }

  void updatePhone(String phone) {
    user = user?.copyWith(phone: phone);
    notifyListeners();
  }

  void updateAvatar(String avatarUrl) {

  }

  /// Live available balance (₦). Source of truth: User.wallet.fiat.
  double get availableBalance => user?.wallet.fiat.availableBalance ?? 0.0;

  /// Local affordability check — lets the PaymentSheet avoid a wasted backend
  /// call when the wallet clearly can't cover an amount.
  bool canAfford(double amount) => availableBalance >= amount;

  /// Reflect a wallet movement after a confirmed payment/refund. We re-fetch
  /// silently (authoritative, can't drift). If you later add nested copyWith to
  /// the User model, you can make this a true optimistic in-place update and
  /// drop the network call. `delta` is negative for spends, positive for refunds.
  Future<void> applyWalletDelta(double delta) async {
    // Optimistic-ready signature; safe authoritative refresh for now.
    await loadUser(silent: true);
  }


}