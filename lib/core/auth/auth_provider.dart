

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import 'auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService api;

  AuthProvider({required this.api});

  String?  _error;

  String? get error => _error;

  Future<String> singUp(
      {
        required String name, required String email, required String password, required String phone, required String referralCode
      }) async {

    try {
      final data = await api.post('/auth/register', {
        'name': name,  'email': email, 'password': password, 'phone': phone, 'referralCode': referralCode
      });
      await FirebaseAuth.instance.signInWithCustomToken(data['customToken']);

      await PushNotificationService().saveTokenToFirestore();

      return data['user']['firebaseUid'];

    }
    catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

}