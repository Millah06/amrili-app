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
}