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

  get signUp =>  userSignUp;

  String generateUserTransferId() {
    final random = Random.secure();
    return List.generate(11, (_) => random.nextInt(10)).join();
  }

  String generateReferralCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return 'REF-${List.generate(6, (_) => chars[random.nextInt(chars.length)]).join()}';
  }


  Future<User?> userSignUp(String email, String password, String name, String phoneNumber, {String? referralCodeUsed,}) async {
    try {
      // Normalize phone number
      final normalizedPhone =
      phoneNumber.startsWith('0') ? phoneNumber : '0$phoneNumber';

      // Check phone uniqueness
      final existingPhone = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: normalizedPhone)
          .limit(1)
          .get();

      if (existingPhone.docs.isNotEmpty) {
        throw Exception("Phone number already registered");
      }

      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userId = result.user!.uid;

      // Generate unique transfer UID
      String transferUid = '';
      bool exists = true;

      while (exists) {
        transferUid = generateUserTransferId();
        final check = await _firestore
            .collection('users')
            .where('transferUid', isEqualTo: transferUid)
            .limit(1)
            .get();
        exists = check.docs.isNotEmpty;
      }

      final referralCode = generateReferralCode();

      await _firestore.collection('users').doc(userId).set({
        'name': name,
        'email': email,
        'phoneNumber': normalizedPhone,

        'transferUid': transferUid,
        'referralCode': referralCode,
        'referredBy': referralCodeUsed,

        'kyc': {
          'status': 'not_submitted', // future crypto use
        },

        'wallet': {
          'fiat': {
            'available': 0.0,
            'locked': 0.0,
          },
          'crypto': {
            'usdt': {'available': 0.0, 'locked': 0.0},
            'btc': {'available': 0.0, 'locked': 0.0},
          }
        },

        'createdAt': FieldValue.serverTimestamp(),
      });

      await PushNotificationService().saveTokenToFirestore();

      return result.user;
    } catch (e) {
      rethrow;
    }
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