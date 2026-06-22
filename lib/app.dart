
import 'package:everywhere/core/constant/app_constants.dart';
import 'package:everywhere/core/router/app_router.dart';
import 'package:everywhere/features/communication/providers/chat_provider.dart';
import 'package:everywhere/features/social/providers/feed_provider.dart';
import 'package:everywhere/features/social/providers/reward_provider.dart';
import 'package:everywhere/providers/transaction_provider.dart';
import 'package:everywhere/providers/user_provider.dart';
import 'package:everywhere/providers/withdrawal_provider.dart';
import 'package:everywhere/services/brain.dart';
import 'package:everywhere/services/notification_service.dart';
import 'package:everywhere/services/session_service.dart';
import 'package:everywhere/shared/widgets/splash_screen.dart';
import 'package:everywhere/shared/widgets/web_app_banner.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constraints/app_theme.dart';
import 'constraints/constants.dart';
import 'core/app_scroll_behavior.dart';
import 'core/deep_link/deep_link_service.dart';
import 'features/payment/services/payment_service.dart';
import 'features/payment/widgets/payment_sheet.dart';
import 'features/profile/providers/my_profile_provider.dart';
import 'features/support/provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {

  AppLifecycleState? _appLifecycleState;
  // Key _key = UniqueKey();
  bool  hasDone = false;
  bool _isGuest = false;   // ← add this
  bool _isLoading = true;
  bool _resolvingPayment = false; // prevents stacking recovery sheets on resume
  String? _lastRecoveredPaymentId;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    if (!kIsWeb) {
      PushNotificationService().init(); // FCM web is out of scope (needs SW + VAPID)
    }
    _finish();
    // Start listening for App Links / Universal Lcinks once the first frame is
    // up, so the router is ready to receive go() calls. navigatorKey + appRouter
    // are wired together in app_router.dart.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DeepLinkService.instance.init();
    });
  }

  Future<void> _finish () async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        hasDone  = prefs.getBool('isSetupDone') ?? false;
        _isGuest  = prefs.getBool('isGuest')     ?? false;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    WidgetsBinding.instance.removeObserver(this);
    DeepLinkService.instance.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // TODO: implement didChangeAppLifecycleState
    super.didChangeAppLifecycleState(state);
    setState(() {
      _appLifecycleState = state;
    });
    if (state == AppLifecycleState.resumed) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (mounted) {
          setState(() {
            // _key = UniqueKey();
          });
          final prefs = await SharedPreferences.getInstance();
          setState(() {
            hasDone  = prefs.getBool('isSetupDone') ?? false;
          });

          // ── Resume any unfinished payment (spec §13.2) ──────────────────────
          // The recovery cron already finishes payments server-side; this just
          // shows the user the outcome promptly when they come back.
          // add to your State:


          // inside the resumed branch, replacing the forced PaymentSheet.show:
          if (_resolvingPayment) return;
          _resolvingPayment = true;
          try {
            final pending = await PaymentService.instance.pending();
            if (pending.isEmpty) { _lastRecoveredPaymentId = null; return; }
            final p = pending.first;
            if (p.paymentId == _lastRecoveredPaymentId) return; // already offered — don't re-pop
            _lastRecoveredPaymentId = p.paymentId;

            final ctx = navigatorKey.currentContext;
            if (ctx == null) return;

            // Non-blocking: stay on the exact screen; let the user choose to resume.
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              duration: const Duration(seconds: 6),
              content: const Text('You have a payment to finish.'),
              backgroundColor: kSnackSuccess,
              action: SnackBarAction(
                label: 'Resume',
                onPressed: () => PaymentSheet.show(
                  ctx,
                  amount: p.amount,
                  entityType: p.entityType,
                  entityId: p.entityId,
                  recoverPaymentId: p.paymentId,
                ),
              ),
            ));
          } catch (_) {/* cron finishes it */} finally {
            _resolvingPayment = false;
          }
        }
      });
    }
  }

  String? currentUserId;

  void handleLogin(String uid) {
    setState(() {
      currentUserId = uid;
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = Provider.of<SessionProvider>(context);
    final pov = Provider.of<UserProvider>(context);
    // In _MyAppState.build()
    if (_isLoading) return const SplashScreen();
    if (pov.loadingUser) return const SplashScreen();

    return MultiProvider(
      key: ValueKey(session.currentUserId),
      providers: [
        // pov.user is null for guest users — pass '' so MyProfileProvider
        // initialises safely (it will no-op or show empty state for guests).
        ChangeNotifierProvider(create: (_) => MyProfileProvider()..initialize(pov.user?.userId ?? '')),
        ChangeNotifierProvider(create: (_) => FeedProvider()),
        ChangeNotifierProvider(create: (_) => RewardProvider()),
        ChangeNotifierProvider(create: (_) => WithdrawalProvider()),
        ChangeNotifierProvider(
          create: (_) => ChatsProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => SupportProvider(),
        ),
        ChangeNotifierProvider(create: (_) => Brain()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
      ],
      child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: AppConstants.appName,
          scrollBehavior: const AppScrollBehavior(),
          routerConfig: appRouter,

          // Phase 12 Track B — single unified theme from AppTheme.data.
          // This replaces the inline ThemeData block that was here before.
          // All colour tokens, text styles, button shapes, and component themes
          // are now declared in lib/constraints/app_theme.dart.
          theme: AppTheme.data,

          // Web-only banner that invites visitors to download the native app.
          // On native platforms the builder just passes through the child.
          // On web it wraps the Navigator in a Stack with a slide-in banner.
          builder: (context, child) {
            if (kIsWeb) {
              return WebAppBannerOverlay(child: child!);
            }
            return child!;
          },
      ),
    );
  }
}