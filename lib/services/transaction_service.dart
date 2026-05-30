import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:another_flushbar/flushbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:everywhere/components/dash_line.dart';
import 'package:everywhere/shared/utils/flush_bar_message.dart';
import 'package:everywhere/components/reusable_card.dart';
import 'package:everywhere/services/receipt_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../components/transacrtion_pin.dart';
import '../components/view_receipt.dart';
import '../components/wallet_balance.dart';
import '../constraints/constants.dart';
import 'brain.dart';

class TransactionService {
  static void handlePurchase({
    required BuildContext context,
    required Future<Map<String, dynamic>?> Function() purchaseFunction,
    Function() ? airtimeGiftFunction,
    bool ? isGift,
  }) {

    final pov = Provider.of<Brain>(context, listen: false);

    void showCorrect() async {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => PopScope(
          canPop: false,
          child: const Center(child: CircularProgressIndicator(
            value: 20,
            backgroundColor: kCardColor,
            color: kButtonColor,
          ),),
        ),
      );
      try {
        final result = await purchaseFunction();

        print(result);

        if (context.mounted) {
          Navigator.pop(context); // Remove loading dialog
        }

        if (result?['status'] == true) {
          // await pov.fetchTransactions();
          // pov.addTransaction(amount, buildData!(result!)!);
          if (context.mounted) {
            isGift ?? false ? airtimeGiftFunction?.call() : Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) =>
                    showSuccessResult(context,
                      true,
                      receiptInformation: result,
                    ),

                ));
          }
        }

        else if (result?['status'] == false) {
          // await pov.fetchTransactions();

          // pov.addTransaction(amount, buildData!(result!)!);

          if (context.mounted) {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) =>
                    showPendingResult(
                      transactionRef: result!['transactionRef'],
                      receiptData: result
                    ),

                ));
          }
        }

        else {

          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) =>
                  showSuccessResult(context, false,
                      errorMessage: result?['message'])));
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context); // Remove loading
        }

        String errorMsg = "An error occurred.";
        if (e.toString().contains('SocketException')) {
          errorMsg = "No internet connection.";
        }
        if (e.toString().contains('HandshakeException')) {
          errorMsg = "No stable internet connection, please try again later.";
        }

        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) =>
                showSuccessResult(context, false, errorMessage: errorMsg)));
      }

    }

    showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        isDismissible: false,
        builder: (_) =>
        TransactionPin(
          onSuccess: () => showCorrect()
          // onCorrect: showCorrect
        )
    );
  }

  static Widget showPendingResult({required String transactionRef, required Map<String, dynamic> receiptData}) {
    return Builder(
      builder: (context) {
        return Scaffold(
          appBar: AppBar(
            title: const Text("Processing Transaction"),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('transactions')
                .doc(transactionRef)
                .snapshots(),
            builder: (context, snapshot) {

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final data = snapshot.data!.data() as Map<String, dynamic>;
              final status = data['status'];

              if (status == "success") {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => showSuccessResult(
                        context,
                        true,
                        receiptInformation: receiptData,
                      ),
                    ),
                  );
                });
              }

              if (status == "failed") {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ShowFailedResult(
                        transactionRef: transactionRef,
                      ),
                    ),
                  );
                });
              }

              return const _PendingBody();
            },
          ),
        );
      },
    );
  }
  
  static Widget showSuccessResult(BuildContext context, bool success,
      {String? errorMessage, Map<String, dynamic>? receiptInformation}) {

    // double tranAmount = double.parse( receiptInformation!['amount']);
    double tranAmount = 0.0;
    String ? errorMessage = receiptInformation!['error'];
    String ? token = receiptInformation['token'];
    String ? serial = receiptInformation['serial'];

    return Scaffold(
      body: FractionallySizedBox(
        heightFactor: 1,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.only(top: 35, left: 15, right: 15),
              child: Column(
                // mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);},
                    child: Container(
                      alignment: Alignment.topRight,
                      child: Text('Done', style: TextStyle(
                          fontSize: 20, color: Colors.white,
                          fontWeight: FontWeight.bold, fontFamily: 'DejaVu Sans', ),),
                    ),
                  ),
                  SizedBox(height: 30,),
                  FaIcon(success ? FontAwesomeIcons.trophy : FontAwesomeIcons.xmark,
                    color: success ? Color(0xFF21D3ED)
                        : Colors.pink, size: 45, shadows: [
                          Shadow(
                            color: Colors.blue.withOpacity(0.5),
                            offset: Offset(3, 3),
                            blurRadius: 20
                          )
                    ],),
                  SizedBox(height: 30,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    textBaseline: TextBaseline.alphabetic,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    children: [
                      Text(kNaira, style: TextStyle(fontSize: 18,
                          fontWeight: FontWeight.bold, fontFamily: 'Courier', color: kButtonColor),),
                      SizedBox(width: 2,),
                      BalanceText(tranAmount, 40, 18, color: kButtonColor,),
                      SizedBox(width: 7,),
                    ],
                  ),
                  Text(DateFormat('MMMM dd, yyyy hh:mm a').
                  format(receiptInformation['date'] ?? DateTime.now())),
                  SizedBox(height: 15,),
                  Text(
                    success
                        ? 'Transaction Completed Successfully.'
                        : errorMessage ?? 'Transaction failed.', style: TextStyle(
                    fontSize: 14, // big integer part
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'DejaVu Sans',
                  ), textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20,),
                  if (token != null && token != '')
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Text('Copy your token: ',
                        style: TextStyle(
                          fontFamily:  'Courier',
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                          fontSize: 16,
                        ),),
                    ),
                  if (token != null && token != '')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(token,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                          style: TextStyle(
                            fontFamily:  'Courier',
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white,
                            fontSize: 17,
                            color: Colors.white
                        ),),
                      ),
                      SizedBox(width: 5,),
                      GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: token));
                            FlushBarMessage
                                .showFlushBar(
                                context: context,
                                message: 'Token Copied Successfully!'
                            );
                          },
                          child: Icon(Icons.copy, size: 20,),
                        )
                    ],
                  ),
                  SizedBox(height: 20,),
                  if (serial != null && token != '')
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(serial,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                            style: TextStyle(
                                fontFamily:  'Courier',
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white,
                                fontSize: 17,
                                color: Colors.white
                            ),),
                        ),
                        SizedBox(width: 5,),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: serial));
                            FlushBarMessage
                                .showFlushBar(
                                context: context,
                                message: 'Token Copied Successfully!'
                            );
                          },
                          child: Icon(Icons.copy, size: 20,),
                        )
                      ],
                    ),
                ],
              ),
            ),
            Visibility(
              visible: success,
              child: Container(
                padding: EdgeInsets.only(bottom: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(

                  onTap: () {
                    print(receiptInformation);
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) => ViewReceipt(
                              transactionId: receiptInformation['transaction_id']!,) ));
                      },
                      child: ReusableCardReceipt(
                        text: 'View Receipt',
                        myIcon: Icon(Icons.receipt),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) => ViewReceipt(
                              transactionId: receiptInformation['transaction_id']!,) ));
                      },
                      child: ReusableCardReceipt(
                        text: 'Share Receipt',
                        myIcon: Icon(Icons.share),
                      ),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }


}

class _PendingBody extends StatelessWidget {
  const _PendingBody();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            const SizedBox(
              height: 80,
              width: 80,
              child: CircularProgressIndicator(strokeWidth: 6),
            ),

            const SizedBox(height: 30),

            const Text(
              "Transaction Processing",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "Please wait while we confirm your payment.",
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Close"),
            )
          ],
        ),
      ),
    );
  }
}

class ShowFailedResult extends StatelessWidget {

  final String transactionRef;

  const ShowFailedResult({
    super.key,
    required this.transactionRef,
  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Transaction Failed"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              const Icon(
                Icons.cancel,
                color: Colors.red,
                size: 80,
              ),

              const SizedBox(height: 25),

              const Text(
                "Payment Failed",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "Your transaction could not be completed. ",
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Try Again"),
              ),

              const SizedBox(height: 10),

              TextButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text("Go Home"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PollingTransactionScreen extends StatefulWidget {
  final String transactionRef;
  final Map<String, dynamic> receiptData;

  const PollingTransactionScreen({
    super.key,
    required this.transactionRef, required this.receiptData,
  });

  @override
  State<PollingTransactionScreen> createState() =>
      _PollingTransactionScreenState();
}

class _PollingTransactionScreenState extends State<PollingTransactionScreen> {

  Timer? timer;

  @override
  void initState() {
    super.initState();
    startPolling();
  }

  void startPolling() {
    timer = Timer.periodic(
      const Duration(seconds: 5),
          (_) => checkStatus(),
    );
  }

  Future<void> checkStatus() async {

    final response = await http.get(
      Uri.parse(
        "https://yourbackend.com/transaction-status/${widget.transactionRef}",
      ),
    );

    final data = jsonDecode(response.body);

    final status = data['status'];

    if (status == "success") {

      timer?.cancel();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TransactionService.showSuccessResult(
             context, true,
          ),
        ),
      );
    }

    if (status == "failed") {

      timer?.cancel();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ShowFailedResult(
            transactionRef: widget.transactionRef,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: null,
      body: _PendingBody(),
    );
  }
}
