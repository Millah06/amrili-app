import 'package:everywhere/components/dash_line.dart';
import 'package:everywhere/components/wallet_balance.dart';
import 'package:everywhere/models/service_model.dart';
import 'package:everywhere/screens/pages/notification_screen.dart';
import 'package:everywhere/screens/pages/transaction_history_screen.dart';
import 'package:everywhere/shared/widgets/pull_to_reveal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_reveal_flutter/pull_to_reveal_flutter.dart';
import '../components/formatters.dart';
import '../components/promotion_screen.dart';
import '../components/reusable_card.dart';
import '../components/service_fraame.dart';
import '../constraints/constants.dart';
import '../core/money/money.dart';
import '../services/brain.dart';
import '../features/marketPlace/utils/vendor_engine_entry.dart';
import '../features/utility/screens/utility_screens/airtime_gift.dart';
import '../features/utility/screens/utility_screens/airtime_screen.dart';
import '../features/utility/screens/utility_screens/data_screen.dart';
import '../features/utility/screens/utility_screens/electric_screen.dart';
import '../features/utility/screens/utility_screens/internet_services.dart';
import '../features/utility/screens/utility_screens/rechargepins_screen.dart';


class HomeScreen extends StatefulWidget {

  static String id = 'home';
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {


  @override
  bool get wantKeepAlive => true;

  bool hasTouched = false;

  @override
  Widget build(BuildContext context) {

    super.build(context);


    final pov = Provider.of<Brain>(context);

    List<ServiceModel> billServices = [
       ServiceModel(
           name: 'Airtime',
           icon: FontAwesomeIcons.mobileScreenButton,
           function: () {
             showModalBottomSheet(
                 isScrollControlled: true,
                 context: context,
                 builder: (context) => FractionallySizedBox(
                   heightFactor: 0.33,
                   child: Container(
                     padding: EdgeInsets.only(left: 15, right: 15),
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text('Choose Type', style: kTitle.copyWith(fontSize: 18)),
                         SizedBox(height: 5,),
                         Divider(),
                         SizedBox(height: 5,),
                         ...['Normal Airtime', 'Airtime Gift',].map((type) => GestureDetector(
                           onTap: () {
                             type == 'Normal Airtime' ? Navigator.push(context,
                                 MaterialPageRoute(builder: (context) => AirtimeScreen()))  : Navigator.push(context, MaterialPageRoute(
                                 builder: (context) => AirtimeGift())
                             );
                           },
                           child: ReusableCard2(
                             child: ListTile(
                               title: Text(type,
                                 style: GoogleFonts.averageSans(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white),),
                               leading: Icon(
                                 type == 'Normal Airtime' ? Icons.business_center : Icons.card_giftcard, size: 20, color: Color(0xFF21D3ED),),),
                           ),
                         ), )
                       ],
                     ),
                   ),
                 )
             );
           }
       ),
      ServiceModel(
          name: 'Airtime Gift',
          icon:  FontAwesomeIcons.gift,
          function: () {
            Navigator.push(context, MaterialPageRoute(
                builder: (context) => AirtimeGift())
            );
          },
        isNew: true,
      ),
      ServiceModel(
          name: 'Data',
          icon:  FontAwesomeIcons.wifi,
          function: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => DataScreen()));
          }
      ),
      ServiceModel(
          name: 'Internet Services',
          icon:  FontAwesomeIcons.globe,
          function: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => InternetServicesScreen()));
          }
      ),
      ServiceModel(
          name: 'Cable',
          icon:  FontAwesomeIcons.tv,
          function: () {

            context.push('/cable');
          }
      ),
      ServiceModel(
          name: 'Electric Bills',
          icon:  FontAwesomeIcons.bolt,
          function: () {
            Navigator.push(context,
                MaterialPageRoute(
                    builder: (context) => ElectricScreen()));
          }
      ),
      ServiceModel(
          name: 'International Airtime',
          icon:  FontAwesomeIcons.globeEurope,
          function: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => InternetServicesScreen()));
          }
      ),
      ServiceModel(
          name: 'Recharge Pins',
          icon:  FontAwesomeIcons.ticket,
          function: () {
            Navigator.push(context, MaterialPageRoute(
                builder: (context) => RechargePinsBusiness())
            );
          }
      ),
    ];

    List<ServiceModel> travelServices = [
      ServiceModel(
          name: 'Flights',
          icon:  FontAwesomeIcons.planeDeparture,
          function: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                icon: Icon(Icons.sentiment_dissatisfied, color: kErrorIconColor, size: 30,),
                actionsPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                title: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('CURRENT VERSION:',  style: kAlertTitle.copyWith(fontSize: 16, fontWeight: FontWeight.w900)),
                          SizedBox(width: 5,),
                          Text(AppLinkHandler.currentVersion, style: kAlertTitle.copyWith(color: Colors.white70, fontSize: 15),)
                        ],
                      ),
                    ],
                  ),
                ),
                backgroundColor: kCardColor,
                alignment: Alignment.center,
                shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                content: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('What\'s happening?',
                          style: kAlertContent.copyWith(fontWeight: FontWeight.w900)),
                      SizedBox(height: 10),
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('This version does\'nt cover this service. Coming Soon, please bear with'
                              'the situation, our engineers are currently working on it, Stay tuned.',
                            style: GoogleFonts.raleway(fontSize: 12,  ), textAlign: TextAlign.center,
                            softWrap: true,),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  Center(
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          elevation: 4,
                          padding: EdgeInsets.symmetric(
                              vertical: 10, horizontal: 30),
                          side: BorderSide(
                              color: kButtonColor
                          ),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)
                          ),
                        ),
                        onPressed: ()  async {
                          Navigator.pop(context);
                        },
                        child: Text('Ok, I will be waiting', style: GoogleFonts.raleway(color: Colors.white, fontSize: 13),)
                    ),
                  )
                ],
              ),
            );
          }
      ),
      ServiceModel(
          name: 'Hotels',
          icon:  FontAwesomeIcons.hotel,
          function: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                icon: Icon(Icons.sentiment_dissatisfied, color: kErrorIconColor, size: 30,),
                actionsPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                title: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('CURRENT VERSION:',  style: kAlertTitle.copyWith(fontSize: 16, fontWeight: FontWeight.w900)),
                          SizedBox(width: 5,),
                          Text(AppLinkHandler.currentVersion, style: kAlertTitle.copyWith(color: Colors.white70, fontSize: 15),)
                        ],
                      ),
                    ],
                  ),
                ),
                backgroundColor: kCardColor,
                alignment: Alignment.center,
                shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                content: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('What\'s happening?',
                          style: kAlertContent.copyWith(fontWeight: FontWeight.w900)),
                      SizedBox(height: 10),
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('This version does\'nt cover this service. Coming Soon, please bear with'
                              'the situation, our engineers are currently working on it, Stay tuned.',
                            style: GoogleFonts.raleway(fontSize: 12,  ), textAlign: TextAlign.center,
                            softWrap: true,),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  Center(
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          elevation: 4,
                          padding: EdgeInsets.symmetric(
                              vertical: 10, horizontal: 30),
                          side: BorderSide(
                              color: kButtonColor
                          ),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)
                          ),
                        ),
                        onPressed: ()  async {
                          Navigator.pop(context);
                        },
                        child: Text('Ok, I will be waiting', style: GoogleFonts.raleway(color: Colors.white, fontSize: 13),)
                    ),
                  )
                ],
              ),
            );
          }
      ),
      ServiceModel(
          name: 'Bus',
          icon:  FontAwesomeIcons.bus,
          function: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                icon: Icon(Icons.sentiment_dissatisfied, color: kErrorIconColor, size: 30,),
                actionsPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                title: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('CURRENT VERSION:',  style: kAlertTitle.copyWith(fontSize: 16, fontWeight: FontWeight.w900)),
                          SizedBox(width: 5,),
                          Text(AppLinkHandler.currentVersion, style: kAlertTitle.copyWith(color: Colors.white70, fontSize: 15),)
                        ],
                      ),
                    ],
                  ),
                ),
                backgroundColor: kCardColor,
                alignment: Alignment.center,
                shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                content: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('What\'s happening?',
                          style: kAlertContent.copyWith(fontWeight: FontWeight.w900)),
                      SizedBox(height: 10),
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('This version does\'nt cover this service. Coming Soon, please bear with'
                              'the situation, our engineers are currently working on it, Stay tuned.',
                            style: GoogleFonts.raleway(fontSize: 12,  ), textAlign: TextAlign.center,
                            softWrap: true,),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  Center(
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          elevation: 4,
                          padding: EdgeInsets.symmetric(
                              vertical: 10, horizontal: 30),
                          side: BorderSide(
                              color: kButtonColor
                          ),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)
                          ),
                        ),
                        onPressed: ()  async {
                          Navigator.pop(context);
                        },
                        child: Text('Ok, I will be waiting', style: GoogleFonts.raleway(color: Colors.white, fontSize: 13),)
                    ),
                  )
                ],
              ),
            );
          }
      ),
      ServiceModel(
          name: 'Car rental',
          icon:  FontAwesomeIcons.car,
          function: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                icon: Icon(Icons.sentiment_dissatisfied, color: kErrorIconColor, size: 30,),
                actionsPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                title: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('CURRENT VERSION:',  style: kAlertTitle.copyWith(fontSize: 16, fontWeight: FontWeight.w900)),
                          SizedBox(width: 5,),
                          Text(AppLinkHandler.currentVersion, style: kAlertTitle.copyWith(color: Colors.white70, fontSize: 15),)
                        ],
                      ),
                    ],
                  ),
                ),
                backgroundColor: kCardColor,
                alignment: Alignment.center,
                shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                content: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('What\'s happening?',
                          style: kAlertContent.copyWith(fontWeight: FontWeight.w900)),
                      SizedBox(height: 10),
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('This version does\'nt cover this service. Coming Soon, please bear with'
                              'the situation, our engineers are currently working on it, Stay tuned.',
                            style: GoogleFonts.raleway(fontSize: 12,  ), textAlign: TextAlign.center,
                            softWrap: true,),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  Center(
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          elevation: 4,
                          padding: EdgeInsets.symmetric(
                              vertical: 10, horizontal: 30),
                          side: BorderSide(
                              color: kButtonColor
                          ),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)
                          ),
                        ),
                        onPressed: ()  async {
                          Navigator.pop(context);
                        },
                        child: Text('Ok, I will be waiting', style: GoogleFonts.raleway(color: Colors.white, fontSize: 13),)
                    ),
                  )
                ],
              ),
            );
          }
      ),
    ];

    const types = <String?>[null, 'restaurant', 'grocery', 'drinks', 'retail'];

    List<ServiceModel> essentialServices = [
      ServiceModel(
          name: 'Food',
          icon:  FontAwesomeIcons.utensils,
          function: () {
             Navigator.push(context, MaterialPageRoute(builder: (context) =>
                 VendorEngineEntry(searchParam: 'restaurant',)));
          }
      ),
      ServiceModel(
          name: 'Groceries',
          icon:  FontAwesomeIcons.carrot,
          function: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) =>
                VendorEngineEntry(searchParam: 'grocery',)));

          }
      ),
      ServiceModel(
          name: 'Drinks',
          icon:  FontAwesomeIcons.wineBottle,
          function: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) =>
                VendorEngineEntry(searchParam: 'drinks',)));
          }
      ),
      ServiceModel(
          name: 'Retail',
          icon:  FontAwesomeIcons.bagShopping,
          function: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) =>
                VendorEngineEntry(searchParam: 'retail',)));
          }
      ),
    ];

    return PopScope(

      child: PullRevealOverlayWrapper(
        controller: PullToRevealController(),
        child: Scaffold(
          backgroundColor: Color(0xFF0F172A),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: const Color(0xFF1E293B),
            // Pushed page now — give it a real back affordance.
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Bills & Top-ups',
              style: kTopAppbars.copyWith(
                  fontFamily: 'DejaVu Sans', fontSize: 23),
            ),
            actions: [
              // History stays — it's bills-specific and useful here.
              // The Scan action is GONE: the global scanner FAB owns that verb
              // now; a second entry point here was noise.
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const TransactionHistoryScreen()),
                ),
                child: const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Icon(Icons.receipt_long_outlined,
                      color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),

                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF177E85).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.bar_chart_rounded,
                                  color: Color(0xFF177E85), size: 22),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Monthly spend',
                                    style: GoogleFonts.inter(
                                        color: Colors.white54, fontSize: 12)),
                                const SizedBox(height: 2),
                                MoneyText(
                                  pov.totalMonthlySpent,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              MyFormatManager.formatMyDate(DateTime.now(), 'MMM yyyy'),
                              style: GoogleFonts.inter(
                                  color: Colors.white38, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      _ServiceSection(title: 'Bills', services: billServices),
                      _ServiceSection(title: 'Essentials', services: essentialServices),
                      _ServiceSection(title: 'Travel & Hotels', services: travelServices),
                      PromoCarousel()
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Service section — reuses the app's real ServiceFrame so tiles look identical
// to the rest of the screen (teal cards, white FontAwesome icons). Only the
// section wrapper + spacing are styled here.
// ─────────────────────────────────────────────────────────────────────────────
class _ServiceSection extends StatelessWidget {
  final String title;
  final List<ServiceModel> services;
  const _ServiceSection({required this.title, required this.services});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF1E293B),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header with a small teal accent bar for hierarchy.
          Padding(
            padding: const EdgeInsets.only(left: 10, bottom: 6, top: 2),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFF177E85),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth >= 600 ? 6 : 4;
              return GridView.builder(
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 0,
                  mainAxisSpacing: 4,
                ),
                itemCount: services.length,
                itemBuilder: (context, i) {
                  final s = services[i];
                  return ServiceFrame(
                    title: s.name,
                    icon: s.icon,
                    onTap: s.function,
                    isNew: s.isNew ?? false,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}