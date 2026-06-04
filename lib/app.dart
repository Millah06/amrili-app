
import 'package:everywhere/core/constant/app_constants.dart';
import 'package:everywhere/core/router/app_router.dart';
import 'package:everywhere/features/communication/providers/chat_provider.dart';
import 'package:everywhere/features/social/providers/feed_provider.dart';
import 'package:everywhere/providers/profile_provider.dart';
import 'package:everywhere/features/social/providers/reward_provider.dart';
import 'package:everywhere/providers/transaction_provider.dart';
import 'package:everywhere/providers/user_provider.dart';
import 'package:everywhere/providers/withdrawal_provider.dart';
import 'package:everywhere/screens/first_screen.dart';
import 'package:everywhere/screens/welcome_screen.dart';
import 'package:everywhere/services/brain.dart';
import 'package:everywhere/services/notification_service.dart';
import 'package:everywhere/services/session_service.dart';
import 'package:everywhere/shared/widgets/splash_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'components/bootom_bar.dart';
import 'constraints/constants.dart';
import 'constraints/vendor_theme.dart';
import 'core/app_scroll_behavior.dart';
import 'core/deep_link/deep_link_service.dart';
import 'features/bottom_navigation/services_screen.dart';
import 'features/bottom_navigation/wallet_screen.dart';
import 'features/profile/providers/my_profile_provider.dart';
import 'features/support/provider.dart';
import 'features/utility/screens/utility_screens/airtime_gift.dart';
import 'features/utility/screens/utility_screens/airtime_screen.dart';
import 'features/utility/screens/utility_screens/cable_suscription.dart';
import 'features/utility/screens/utility_screens/data_screen.dart';
import 'features/utility/screens/utility_screens/electric_screen.dart';
import 'features/utility/screens/utility_screens/internet_services.dart';
import 'features/utility/screens/utility_screens/jamb_screen.dart';
import 'features/utility/screens/utility_screens/rechargepins_screen.dart';
import 'features/utility/screens/utility_screens/waec_screen.dart';

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
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => MyProfileProvider()..initialize(pov.user!.userId)),
        ChangeNotifierProvider(create: (_) => FeedProvider()),
        ChangeNotifierProvider(create: (_) => RewardProvider()),
        ChangeNotifierProvider(create: (_) => WithdrawalProvider()),
        ChangeNotifierProvider(
          create: (_) => ChatsProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => SupportProvider(),
        ),
        ChangeNotifierProvider(
            create: (BuildContext context) =>
            Brain()..getData()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()..loadInitial()),
      ],

      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: AppConstants.appName,
        scrollBehavior: const AppScrollBehavior(),
        routerConfig: appRouter,
        theme: ThemeData(
          scaffoldBackgroundColor: Color(0xFF0F172A),
          inputDecorationTheme: InputDecorationTheme(
              floatingLabelStyle: TextStyle(
                  color: Colors.white
              ),
              labelStyle: TextStyle(
                color:  Color(0x8AFFFFFF),
                fontSize: 13,
              ),
              helperStyle: TextStyle(
                  color: Colors.white
              ),
              hintStyle: const TextStyle(color: VendorTheme.textMuted),
              filled: true,
              fillColor: VendorTheme.surface,
              focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: kButtonColor
                  ),
                  borderRadius: BorderRadius.circular(10),
              ),
              border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(10)
              ),
              prefixIconColor: Colors.white,
              focusedErrorBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: Colors.red.shade400
                  ),
                  borderRadius: BorderRadius.circular(10)
              ),
              errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: Colors.red.shade400
                  ),
                  borderRadius: BorderRadius.circular(10)
              )
          ),
          textTheme: TextTheme(
            bodyMedium: TextStyle(color: Colors.white,),
          ),
          iconTheme: IconThemeData(
            // color: Color(0xFF21D3ED)
              color: Colors.white
          ),
          buttonTheme: ButtonThemeData(
            buttonColor: Color(0xFF21D3ED),
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: Color(0xFF177E85),
            titleTextStyle: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
            iconTheme: IconThemeData(
              color: Colors.white,
            ),
          ),
          bottomSheetTheme: BottomSheetThemeData(
            showDragHandle: true,
            dragHandleSize: Size(70, 5),
            backgroundColor: Color(0xFF0F172A),
            dragHandleColor: Colors.white,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
                // side: BorderSide(
                //     color: kButtonColor
                // ),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)
                ),
                textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold)
            ),
          ),
        ),
        // this will be implemented in the second phase
        // home: hasDone ? const FirstScreen() : const WelcomeScreen(),
        // After:
        // home: hasDone ? const BottomBar()
        //     : _isGuest ? const BottomBar()   // ← guest persists to feed
        //     : const WelcomeScreen(),

        // routes: {
        //   HomeScreen.id : (context) => HomeScreen(),
        //   WalletScreen.id: (context) => WalletScreen(),
        //   FirstScreen.id: (context) => FirstScreen(),
        //   WelcomeScreen.id: (context) => WelcomeScreen(),
        //   '/cable': (context) => CableSubscription(),
        //   '/airtimeNormal' : (context) => AirtimeScreen(),
        //   '/airtimeGift' : (context) => AirtimeGift(),
        //   '/data': (context) => DataScreen(),
        //   '/electric': (context) => ElectricScreen(),
        //   '/waec': (content) => WaecServices(),
        //   '/jamb' : (content) => JambServices(),
        //   '/rechargePins': (context) => RechargePinsBusiness(),
        //   '/internetServices' : (context) => InternetServicesScreen()
        // },

      ),
    );
  }
}