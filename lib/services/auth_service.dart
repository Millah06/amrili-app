import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:everywhere/services/notification_service.dart';
import 'package:everywhere/services/purchase_service.dart';
import 'package:everywhere/services/transaction_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class Authentication {
  final _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  BuildContext context;

  Authentication({required this.context});

  String generateUserTransferId() {
    final random = Random.secure();
    return List.generate(11, (_) => random.nextInt(10)).join();
  }

  String generateReferralCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return 'REF-${List.generate(6, (_) => chars[random.nextInt(chars.length)]).join()}';
  }



  Future<User?> userSignIn(String email, String password,) async {
    UserCredential ? result;
    try {
      result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      await PushNotificationService().saveTokenToFirestore();
      return result.user;
    }
    catch(e) {
      rethrow;
    }
  }


}