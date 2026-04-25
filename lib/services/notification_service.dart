import 'package:everywhere/models/notification_model.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../app.dart';
import '../main.dart';
import '../screens/pages/notification_screen.dart';

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // 🔁 Initialize everything
  Future<void> init() async {
    // 1. Request permission to show notifications
    NotificationSettings settings = await _fcm.requestPermission();
    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      print('❌ User denied notification permission');
      return;
    }

    // Request permission (safe to call multiple times)
    await _fcm.requestPermission();

    // Listen for token refresh (if token changes)
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      print('🔁 FCM Token Refreshed: $newToken');
      _saveTokenToFirestore(newToken);
    });

    // Optional: Get initial token if refresh didn't fire
    // But only if we already saved one before (user logged in)
    String? savedToken = await _fcm.getToken();
    if (savedToken != null) {
      _saveTokenToFirestore(savedToken);
    }

    // 4. Handle background messages (when app is closed)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 5. Handle foreground messages (when app is open)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📬 Foreground message: ${message.notification?.title}');
      _saveNotification(message); // Save to Hive
      // _updateBadge(); // Update badge number
    });

    // 6. Handle when user taps notification (app in background or closed)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _navigateToNotificationScreen(message);
    });

    // 7. Check if app was opened from a terminated state (cold start via notification)
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _navigateToNotificationScreen(initialMessage);
    }
  }

  // ✅ Call this ONLY once — during login or signup
  Future<void> saveTokenToFirestore() async {
    // Get current user
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Get FCM token
    String? token = await _fcm.getToken();
    if (token == null) return;

    // Save to Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({
      'notificationToken': token,
    }, SetOptions(merge: true));

    print('✅ FCM Token saved to Firestore for user: ${user.uid}');
  }

  // 🔐 Save refreshed token (called by onTokenRefresh)
  Future<void> _saveTokenToFirestore(String token) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({'notificationToken': token});
  }


  // 💾 Save incoming notification to Hive (local storage)
  Future<void> _saveNotification(RemoteMessage message) async {

    final box = Hive.box<AppNotification>('notifications');

    await box.add(AppNotification(
        title: message.notification?.title ?? 'No Title',
        body: message.notification?.body ?? 'No Body',
        data: message.data,
        receivedAt: DateTime.now())
    );
    print('💾 Notification saved to Hive');
  }

  // 🚪 Navigate to NotificationScreen when notification is tapped
  void _navigateToNotificationScreen(RemoteMessage message) {
    _saveNotification(message); // Save first
    // _updateBadge(); // Update badge

    // 🔑 Use global navigator to open screen without context
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => NotificationScreen(message: message),
      ),
    );
  }
}

Future<Box<AppNotification>> _getNotificationsBox() async {
  if (Hive.isBoxOpen('notifications')) {
    return Hive.box<AppNotification>('notifications');
  } else {
    return await Hive.openBox<AppNotification>('notifications');
  }
}

// 🛠 Background handler (must be top-level, outside class)

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Make sure Firebase is initialized
  await Firebase.initializeApp();
  final dir = await getApplicationDocumentsDirectory();
  Hive.init(dir.path);


  print('🔥 Handling a background message: ${message.messageId}');

  // Initialize Hive if not already

  final box = await _getNotificationsBox();

  await box.add(AppNotification(
    title: message.notification?.title ?? 'No Title',
    body: message.notification?.body ?? 'No Body',
    data: message.data,
    receivedAt: DateTime.now(),
  ));
}
