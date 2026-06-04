import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:everywhere/components/wallet_balance.dart';
import 'package:everywhere/constraints/constants.dart';
import 'package:everywhere/features/support/help_center.dart';
import 'package:everywhere/providers/user_provider.dart';
import 'package:everywhere/shared/widgets/pull_to_reveal.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_reveal_flutter/pull_to_reveal_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../shared/widgets/account_information.dart';
import '../../components/recent_frame.dart';
import '../../components/reusable_card.dart';
import '../../components/service_fraame.dart';
import '../../components/view_receipt.dart';
import '../../services/brain.dart';
import '../wallet/pages/crypto_wallet_screen.dart';
import '../wallet/pages/p2p_transfer_screen.dart';
import '../wallet/pages/withdraw_bank_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  static String id = 'wallet';

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {

  bool hasTouched = true;

  @override
  Widget build(BuildContext context) {
    final pov = Provider.of<Brain>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final double availableBalance =
        userProvider.user?.wallet.fiat.availableBalance ?? 0.0;
    final double rewardBalance =
        userProvider.user?.wallet.fiat.rewardBalance ?? 0.0;
    return PullRevealOverlayWrapper(
      controller: PullToRevealController(),
      child: Scaffold(
          backgroundColor: Color(0xFF0F172A),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    height: 270,
                    width: double.infinity,
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF0F172A), Color(0xFF0D9488), Color(0xFF0F172A), Color(0xFF0D9488) ],
                          // colors: [Colors.black38, Color(0xFF177E85)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        // image: DecorationImage(fit: BoxFit.cover,
                        //     image: AssetImage('images/wallet.jpg')),
                      color: kButtonColor,
                        borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(30),
                            bottomRight: Radius.circular(30)
                        )
                    ),
                    child: Center(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            alignment: Alignment.topLeft,
                              margin: EdgeInsetsGeometry.only(left: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(Radius.circular(20)),
                                // color: Colors.white,
                              ),
                              child: Padding(
                                padding: EdgeInsets.only(top: 25),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Builder(
                                      builder: (context) {
                                        final double fiatBalance =
                                            userProvider.user?.wallet.fiat.availableBalance ?? 0.0;
                                        const double cryptoBalance = 0.0; // placeholder until real crypto
                                        const double ngnPerUsdt = 1500.0; // TODO: load from backend
                                        final double totalNgn = fiatBalance + cryptoBalance;
                                        final double totalUsdt =
                                            ngnPerUsdt > 0 ? totalNgn / ngnPerUsdt : 0.0;

                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.shield_moon_outlined, size: 16,),
                                                Text('Total Assets', style:
                                                TextStyle(color: Colors.white70,
                                                    fontWeight: FontWeight.w900,
                                                    fontFamily: 'DejaVu Sans', fontSize: 12),),
                                                SizedBox(width: 5,),
                                                GestureDetector(
                                                    onTap: () {
                                                      setState(() {
                                                        hasTouched = !hasTouched;
                                                      });
                                                    },
                                                    child: FaIcon(hasTouched ? FontAwesomeIcons.eyeSlash :
                                                    FontAwesomeIcons.eye, size: 13, color: Colors.white70,)
                                                )

                                              ],
                                            ),
                                            const SizedBox(height: 5,),
                                            hasTouched
                                                ? Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text('******', style: kMoneyStyle,),
                                            )
                                                : Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  textBaseline: TextBaseline.alphabetic,
                                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                                  children: [

                                                    SizedBox(width: 4,),
                                                    BalanceText(availableBalance + rewardBalance,
                                                        20, 12),
                                                    SizedBox(width: 4,),
                                                    Text('NGN', style:
                                                    kMoneyStyle.copyWith(fontFamily: 'DejaVu Sans', fontSize: 12),),
                                                  ],
                                                ),
                                                SizedBox(height: 2,),

                                              ],
                                            )
                                          ],
                                        );
                                      },
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(right: 20),
                                      child: GestureDetector(
                                        onTap: () async {
                                           Navigator.push(context, MaterialPageRoute(builder: (context) => HelpCenter()));
                                        },
                                        child: Column(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.all(1.5),
                                              decoration: BoxDecoration(
                                                  color: Colors.pink,
                                                  borderRadius: BorderRadius.circular(5)
                                              ),
                                              child: Text('HELP',
                                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),),
                                            ),
                                            SizedBox(height: 2,),
                                            FaIcon(FontAwesomeIcons.headset, size: 26,),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                          ),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.only(bottom: 10, left: 15, right: 15, top: 10),
                            margin: EdgeInsets.only(left: 12, right: 12, bottom: 10, top: 10),
                            decoration: BoxDecoration(
                              // color: Color(0xFF177E85),
                                color: Color(0xFF0F172A),
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF0F172A), Color(0xFF0D9488), Color(0xFF0F172A),],
                                  begin: Alignment.topRight,
                                  end: Alignment.bottomLeft,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [BoxShadow(color: Color(0xFF177E85).withOpacity(0.4),
                                    blurRadius: 8, spreadRadius: 1, offset: Offset(0, 2))]
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.shield_moon_outlined, size: 18,),
                                            SizedBox(width: 2,),
                                            Text('NGN Wallet Balance', style: kWalletStyle,),
                                          ],
                                        ),
                                        SizedBox(width: 5,),
                                        GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                hasTouched = !hasTouched;
                                              });
                                            },
                                            child: FaIcon(hasTouched ? FontAwesomeIcons.eyeSlash :
                                            FontAwesomeIcons.eye, size: 13, color: Colors.white70,)
                                        )
                                      ],
                                    ),
                                    Text('Reward Balance', style: kWalletStyle,),
                                  ],
                                ),
                                StreamBuilder(
                                    stream: FirebaseFirestore
                                        .instance.collection('users')
                                        .doc(FirebaseAuth.instance.currentUser?.uid).snapshots(),
                                    builder: (context, snapshot) {
                                      final data = snapshot.data;
                                      if (!snapshot.hasData) {
                                        return CircularProgressIndicator();
                                      }
                                      if (snapshot.connectionState == ConnectionState.done && snapshot.hasError) {
                                        return Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('An error occurred or network')
                                          ],
                                        );
                                      }
                                      if (!snapshot.data!.exists) {
                                        return CircularProgressIndicator();
                                      }
                                      return Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          hasTouched ? Text('******', style: kMoneyStyle,) :  Row(
                                            textBaseline: TextBaseline.alphabetic,
                                            crossAxisAlignment: CrossAxisAlignment.baseline,
                                            children: [
                                              Text(kNaira, style:
                                              kMoneyStyle.copyWith(fontFamily: 'DejaVu Sans', fontSize: 18),),
                                              SizedBox(width: 2,),
                                              BalanceText(availableBalance, 30, 18),
                                            ],
                                          ),
                                          hasTouched ? Text('******', style: kMoneyStyle,) :  Row(
                                            children: [
                                              Text(kNaira, style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),),
                                              SizedBox(width: 3,),
                                              BalanceText(rewardBalance, 20, 10)
                                            ],
                                          ),
                                        ],
                                      );
                                    }
                                ),
                                Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.only(bottom: 10, left: 15, right: 15, top: 10),
                                    margin: EdgeInsets.only(left: 0, right: 0, bottom: 4, top: 5),
                                    decoration: BoxDecoration(
                                      // color: Color(0xFF0F172A),
                                        color: Color(0xFF177E85),
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [BoxShadow(color: Color(0xFF0F172A).withOpacity(0.6),
                                            blurRadius: 8, spreadRadius: 1, offset: Offset(0, 2))]
                                    ),
                                    child: GestureDetector(
                                      onTap: ()  {
                                        showModalBottomSheet(
                                          context: context, builder: (context) => FractionallySizedBox(
                                          heightFactor: 0.4,
                                          child: AccountInformation(),
                                        ),
                                          isScrollControlled: true,
                                          showDragHandle: true,
                                          // backgroundColor: Color(0xFF333333),
                                        );
                                      },
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Add Funds', style: kExpenseStyle,),
                                          FaIcon(
                                            FontAwesomeIcons.plusCircle,
                                          )
                                        ],
                                      ),
                                    )
                                ),
                              ],
                            ),
                          ),
                          // AccountInformation(),
                          SizedBox(height: 10,),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                      padding: EdgeInsets.only(top: 310, left: 10, right: 10),
                      child: Column(
                        children: [

                          // Wallet actions: p2p, bank, crypto
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.only(left: 5, right: 5),
                            margin: EdgeInsets.only(left: 25, right: 25, bottom: 10, top: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Color(0xFF1E293B),
                            ),
                            child: SizedBox(
                              height: 100,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  ServiceFrame(
                                    title: 'To NexPay',
                                    icon: FontAwesomeIcons.moneyBillTransfer,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const P2PTransferScreen(),
                                        ),
                                      );
                                    },
                                    isNew: false,
                                    titleFont: 11,
                                  ),

                                  ServiceFrame(
                                    title: 'Crypto',
                                    icon: FontAwesomeIcons.bitcoinSign,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const CryptoWalletScreen(),
                                        ),
                                      );
                                    },
                                    isNew: false,
                                    titleFont: 11,
                                  ),
                                  ServiceFrame(
                                    title: 'Withdraw',
                                    icon: FontAwesomeIcons.moneyBill,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const WithdrawBankScreen(),
                                        ),
                                      );
                                    },
                                    isNew: false,
                                    titleFont: 11,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                  )
                ],
              ),
              Padding(
                padding: EdgeInsets.only(left: 15, right: 15, top: 10, bottom: 10),
                child: Text('Recent Transactions',  style:
                GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w600),),
              ),
              Expanded(
                child: pov.transactions.isEmpty ?
                Center(child: Text('No Transactions yet', style: GoogleFonts.inter(),),) :
                ListView.builder(
                  padding: EdgeInsets.only(left: 15, right: 15),
                  itemBuilder: (BuildContext context, int index) {
                    final transaction = pov.transactions[index];
                    return RecentFrame(
                      beneficiary: transaction['Product Name'] ?? '',
                      date: (transaction['Date']).toDate(),
                      amount: (transaction['Paid Amount'] as num).toString(),
                      status: transaction['Status'] ?? '0',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ViewReceipt(transactionId: transaction['Transaction ID']),
                          ),
                        );
                      },
                    );
                  },
                  itemCount: pov.transactions.length,
                ),
              )
            ],
          )
      ),
    );
  }
}
