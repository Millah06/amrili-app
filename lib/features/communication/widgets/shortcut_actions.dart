import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/confirmation_page.dart';
import '../../../components/dash_line.dart';
import '../../../components/formatters.dart';
import '../../../components/notice_banner.dart';
import '../../../components/textInput_formater.dart';
import '../../../constraints/constants.dart';
import '../../../services/brain.dart';
import '../services/message_service.dart';
import '../../../services/purchase_service.dart';
import '../../../services/transaction_service.dart';

class ShortCutAction extends StatefulWidget {
  const ShortCutAction({super.key, required this.shortcutName, required this.otherUserId,
    required this.roomId});

  final String shortcutName;
  final String otherUserId;
  final String roomId;

  @override
  State<ShortCutAction> createState() => _ShortCutActionState();
}

class _ShortCutActionState extends State<ShortCutAction> {


  TextEditingController amountController = TextEditingController();

  bool userCancelNotice = false;

  String selectedNetwork = 'MTN';


  String ? message;


  final formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    final pov = Provider.of<Brain>(context, listen: false);

    Map<String, bool> myServices = pov.airtimeProviders;



    List<String> networks = myServices.keys.toList();

    bool oneServiceIsDown = myServices.containsValue(false);

    if (oneServiceIsDown) {
      final unavailable = MyFormatManager.getUnavailableServices(myServices);
      message = MyFormatManager.formatUnavailable(unavailable, 'airtime purchase');
    }
    if (widget.shortcutName == 'Transfer Money') {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 15, right: 15),
            child:  TextFormField(
              controller: amountController,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              cursorColor: Colors.white,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefix: Text('$kNaira | ',
                  style: TextStyle(color: Colors.white, fontSize: 16,
                      fontWeight: FontWeight.w900),),
                labelText: 'Amount',
                hintText: '300',
                labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'This field is required';
                }
                return null;
              },
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                TextFieldFormater()
              ],
            ),
          ),
          SizedBox(height: 20,),
          Padding(
            padding: const EdgeInsets.only(left: 15, right: 15, bottom: 15),
            child: DashedLine(),
          ),
          SizedBox(height: 15,),
          Padding(
            padding: const EdgeInsets.only(bottom: 15.0),
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: kButtonColor,
                    elevation: 4,
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 120),
                    side: BorderSide.none
                ),

                onPressed: () async {
                  Navigator.pop(context);
                  if (formKey.currentState!.validate()) {
                    // Look up the other user's phone from Firestore
                    final otherLast10 =
                    await MessageService().getOtherUserPhoneLast10(widget.otherUserId);
                    if (otherLast10 == null) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Could not find recipient phone number. Please try again later.',
                            ),
                          ),
                        );
                      }
                      return;
                    }

                    final destinationPhone = '0$otherLast10';

                    double bonus = pov.airtimePercent *
                        int.parse(amountController.text.replaceAll(',', ''));
                    showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) =>
                            ConfirmationPage(
                              amount: amountController.text.replaceAll(',', ''),
                              isRecharge: true,
                              bonusEarn:
                              (bonus).toDouble(),
                              receiptData: {
                                'Product Name' : '$selectedNetwork Airtime',
                                'Actual Amount' : '${kFormatter.format(double.parse(amountController.text.replaceAll(',', '')))} NGN',
                                'Recipient Mobile' : destinationPhone,
                                'Bonus to Earn' : '$kNaira${(bonus).toStringAsFixed(2) }'
                              },
                              onTap: (amount, reward, useReward) {
                                TransactionService.handlePurchase(
                                  context: context,
                                  purchaseFunction: () async {
                                    try {
                                      final res = await PurchaseItems(context: context)
                                          .purchaseAirtime(
                                          humanRef: '',
                                          phone: destinationPhone,
                                          serviceId: selectedNetwork.toLowerCase(),
                                          amount: amountController.text,
                                          clientRequestId: '',
                                          isRecharge: true,
                                          useReward: useReward
                                      );
                                      return res;
                                    }
                                    catch(e) {
                                      rethrow;
                                    }
                                  },
                                );
                              },
                            )
                    );
                  }
                },
                child: Text('Proceed', style: TextStyle(color: Colors.black),)
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 15, right: 15),
          child: Form(
            key: formKey,
            child: Column(
              children: [
                userCancelNotice? SizedBox() : Visibility(
                  visible: oneServiceIsDown,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: NoticeBanner(
                      noticeMessage: message ?? '34',
                      onClose: () {
                        // setState(() {
                        //   userCancelNotice = true;
                        // });
                      },
                    ),
                  ),
                ),
                DropdownButtonFormField<String>(
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  dropdownColor: kCardColor,
                  padding: EdgeInsets.only(left: 10, right: 10),
                  iconSize: 30,
                  iconDisabledColor: kButtonColor,
                  iconEnabledColor: kButtonColor,
                  value: selectedNetwork,
                  menuMaxHeight: 200,
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  decoration: const InputDecoration(
                    labelText: 'Network',
                    labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                  ),
                  // style: const TextStyle(color: Colors.black),
                  items: networks.map((range) {
                    return DropdownMenuItem<String>(
                        value: range,
                        child: Text(range, style: TextStyle(color: Colors.white),));
                  }).toList(),
                  onChanged: (val) {
                    // else if (val != null) {setState(() => selectedDateRange = val);};
                    setState(() => selectedNetwork = val!);
                  },
                ),
                SizedBox(height: 20,),
                TextFormField(
                  controller: amountController,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  cursorColor: Colors.white,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    prefix: Text('$kNaira | ',
                      style: TextStyle(color: Colors.white, fontSize: 16,
                          fontWeight: FontWeight.w900),),
                    labelText: 'Amount',
                    hintText: '300',
                    labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'This field is required';
                    }
                    return null;
                  },
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    TextFieldFormater()
                  ],
                ),
                SizedBox(height: 20,),
              ],
            ),
          ),
        ),
        SizedBox(height: 10,),
        Padding(
          padding: const EdgeInsets.only(left: 15, right: 15, bottom: 15),
          child: DashedLine(),
        ),
        SizedBox(height: 15,),
        myServices[selectedNetwork] == false ?
        SizedBox(
          height: 100,
          child: Center(
            child: Text('Service Temporarily unavailable, please try again later!',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
              textAlign: TextAlign.center,),
          ),
        ) : Padding(
          padding: const EdgeInsets.only(bottom: 15.0),
          child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: kButtonColor,
                  elevation: 4,
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 120),
                  side: BorderSide.none
              ),

              onPressed: () async {
                Navigator.pop(context);
                if (formKey.currentState!.validate()) {
                  // Look up the other user's phone from Firestore
                  final otherLast10 =
                  await MessageService().getOtherUserPhoneLast10(widget.otherUserId);
                  if (otherLast10 == null) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Could not find recipient phone number. Please try again later.',
                          ),
                        ),
                      );
                    }
                    return;
                  }

                  final destinationPhone = '0$otherLast10';

                  double bonus = pov.airtimePercent *
                      int.parse(amountController.text.replaceAll(',', ''));
                  showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) =>
                          ConfirmationPage(
                            amount: amountController.text.replaceAll(',', ''),
                            isRecharge: true,
                            bonusEarn:
                            (bonus).toDouble(),
                            receiptData: {
                              'Product Name' : '$selectedNetwork Airtime',
                              'Actual Amount' : '${kFormatter.format(double.parse(amountController.text.replaceAll(',', '')))} NGN',
                              'Recipient Mobile' : destinationPhone,
                              'Bonus to Earn' : '$kNaira${(bonus).toStringAsFixed(2) }'
                            },
                            onTap: (amount, reward, useReward) {
                              TransactionService.handlePurchase(
                                context: context,
                                purchaseFunction: () async {
                                  try {
                                    final res = await PurchaseItems(context: context)
                                        .purchaseAirtime(
                                        humanRef: '',
                                        phone: destinationPhone,
                                        serviceId: selectedNetwork.toLowerCase(),
                                        amount: amountController.text,
                                        clientRequestId: '',
                                        isRecharge: true,
                                        useReward: useReward
                                    );
                                    return res;
                                  }
                                  catch(e) {
                                    rethrow;
                                  }
                                },
                              );
                            },
                          )
                  );
                }
              },
              child: Text('Proceed', style: TextStyle(color: Colors.black),)
          ),
        ),
      ],
    );
  }
}

