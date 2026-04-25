import 'package:everywhere/components/formatters.dart';
import 'package:everywhere/models/notification_model.dart';
import 'package:everywhere/providers/user_provider.dart';
import 'package:everywhere/services/api_service.dart';
import 'package:everywhere/services/session_service.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'core/auth/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
  );
  
  await Hive.initFlutter();

  await AppLinkHandler.init();

  Hive.registerAdapter(AppNotificationAdapter());
  await Hive.openBox<AppNotification>('notifications');

  SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent
      )
  );
  runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
              create: (_) => SessionProvider()),
          ChangeNotifierProvider(
              create: (_) => AuthProvider(api: ApiService())),
          ChangeNotifierProvider(
              create: (_) => UserProvider(api: ApiService())..getUserId()..loadUser()),

        ],
        child: MyApp(),)
  );
}



