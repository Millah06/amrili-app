import 'package:everywhere/models/notification_model.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../app.dart';
import '../screens/pages/notification_screen.dart';

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // Called once in MyApp.initState. Wires up all FCM listeners WITHOUT
  // requesting permission or prompting the user — permission is requested
  // only after the user signs in (inside saveTokenToFirestore below).
  //
  // The old init() called requestPermission() immediately, causing an OS
  // permission dialog to fire on the very first app frame. That was wrong
  // for two reasons: (1) cold UX and (2) the early `return` on denial meant
  // none of the listeners were registered, so foreground and background
  // messages were silently dropped for users who declined on first launch.
  Future<void> init() async {
    // Token refresh — uses set+merge so it works even if the Firestore doc
    // doesn't exist yet (fresh install before first sign-in).
    FirebaseMessaging.instance.onTokenRefresh.listen(_saveTokenToFirestore);

    // Background handler (app is terminated or backgrounded by OS).
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Foreground — app is open and in the foreground.
    FirebaseMessaging.onMessage.listen((msg) {
      _saveNotification(msg);
    });

    // Tap on a notification when the app was in the background (not terminated).
    FirebaseMessaging.onMessageOpenedApp.listen(_navigateToNotificationScreen);

    // Cold-start: app was terminated and launched via a notification tap.
    // We defer navigation to the next frame so the GoRouter/navigator is
    // fully mounted before we attempt to push onto it.
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToNotificationScreen(initialMessage);
      });
    }
  }

  // Called by AuthProvider immediately after every sign-in or sign-up.
  // Requests notification permission (shows the OS dialog at the right moment
  // — after the user has chosen to log in, not on cold first launch) and
  // persists the FCM token to Firestore.
  Future<void> saveTokenToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final settings = await _fcm.requestPermission();
      // AuthorizationStatus.provisional = iOS "deliver quietly" — still useful.
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      final token = await _fcm.getToken();
      if (token == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'notificationToken': token}, SetOptions(merge: true));
    } catch (_) {
      // Push notifications unavailable on this platform/config — non-fatal.
      // Common on web when VAPID key / service worker not yet configured.
    }
  }

  // Private refresh-token handler. Uses set+merge (not update) so it does
  // not throw when the Firestore user document has not been created yet.
  Future<void> _saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({'notificationToken': token}, SetOptions(merge: true));
  }

  // Persist an incoming notification payload to the local Hive box so
  // the in-app notification screen can display it.
  Future<void> _saveNotification(RemoteMessage message) async {
    final box = Hive.box<AppNotification>('notifications');
    await box.add(AppNotification(
      title: message.notification?.title ?? 'No Title',
      body: message.notification?.body ?? 'No Body',
      data: message.data,
      receivedAt: DateTime.now(),
    ));
  }

  // Push the notification detail screen via the shared navigatorKey — the
  // same key GoRouter is registered on, so this push travels through the
  // correct navigator (no second navigator introduced).
  void _navigateToNotificationScreen(RemoteMessage message) {
    _saveNotification(message);
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => NotificationScreen(message: message),
      ),
    );
  }
}

// ── Hive box helper ────────────────────────────────────────────────────────────

Future<Box<AppNotification>> _getNotificationsBox() async {
  if (Hive.isBoxOpen('notifications')) {
    return Hive.box<AppNotification>('notifications');
  } else {
    return await Hive.openBox<AppNotification>('notifications');
  }
}

// ── Background handler (top-level, outside class — FCM requirement) ────────────

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  final dir = await getApplicationDocumentsDirectory();
  Hive.init(dir.path);

  final box = await _getNotificationsBox();
  await box.add(AppNotification(
    title: message.notification?.title ?? 'No Title',
    body: message.notification?.body ?? 'No Body',
    data: message.data,
    receivedAt: DateTime.now(),
  ));
}
