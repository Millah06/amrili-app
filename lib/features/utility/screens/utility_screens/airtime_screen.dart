import 'package:everywhere/shared/widgets/confirmation_page.dart';
import 'package:everywhere/constraints/constants.dart';
import 'package:everywhere/constraints/firebase_constant.dart';
import 'package:everywhere/services/purchase_service.dart';
import 'package:everywhere/services/transaction_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../components/formatters.dart';
import '../../../../components/notice_banner.dart';
import '../../../../components/textInput_formater.dart';
import '../../../../services/brain.dart';

class AirtimeScreen extends StatefulWidget {
  const AirtimeScreen({super.key});

  @override
  State<AirtimeScreen> createState() => _AirtimeScreenState();
}

class _AirtimeScreenState extends State<AirtimeScreen> {

  String _selectedNetwork = 'MTN';
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  // List networks = ['MTN', 'Airtel', 'Glo', 'etisalat'];
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    // TODO: implement dispose
    _phoneController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  String ? message;

  bool userCancelNotice = false;

  String ? currentRequestId;

  @override
  Widget build(BuildContext context) {
    final pov = Provider.of<Brain>(context);


    Map<String, bool> myServices = pov.airtimeProviders;



    List<String> networks = myServices.keys.toList();

    bool oneServiceIsDown = myServices.containsValue(false);

    if (oneServiceIsDown) {
      final unavailable = MyFormatManager.getUnavailableServices(myServices);
      message = MyFormatManager.formatUnavailable(unavailable, 'airtime purchase');
    }

    return  Scaffold(
      appBar: AppBar(
        title: Text('Airtime Purchase'),
      ),
      body: Form(
        key: _formKey,
        child: Container(
          padding: EdgeInsets.only(left: 12, right: 12, top: 20),
          child: SingleChildScrollView(
            child: Column(
              children: [
                userCancelNotice? SizedBox() : Visibility(
                  visible: oneServiceIsDown,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: NoticeBanner(
                      noticeMessage: message ?? '34',
                      onClose: () {
                        setState(() {
                          userCancelNotice = true;
                        });
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
                  value: _selectedNetwork,
                  menuMaxHeight: 200,
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  decoration: const InputDecoration(
                      labelText: 'Network',
                  ),
                  // style: const TextStyle(color: Colors.black),
                  items: networks.map((range) {
                    return DropdownMenuItem<String>(
                        value: range,
                        child: Text(range, style: TextStyle(color: Colors.white),));
                  }).toList(),
                  onChanged: (val) {
                    // else if (val != null) {setState(() => selectedDateRange = val);};
                    setState(() => _selectedNetwork = val!);
                  },
                ),
                SizedBox(height: 20,),
                TextFormField(
                  controller: _phoneController,
                  cursorColor: Colors.white,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: InputDecoration(
                    prefix: Text('+234 | ',
                      style: TextStyle(color: Colors.white, fontSize: 16,
                          fontWeight: FontWeight.w900),),
                    labelText: 'Phone Number',
                    hintText: '8023344567',

                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'This field is required';
                    }
                    if (value.startsWith('0', 0)) {
                      return 'Phone number can\'n start with zero';
                    }
                    if (value.length != 10) {
                      return 'Phone Number is incomplete';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20,),
                TextFormField(
                  controller: _amountController,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  cursorColor: Colors.white,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      prefix: Text('$kNaira | ',
                        style: TextStyle(color: Colors.white, fontSize: 16,
                            fontWeight: FontWeight.w900),),
                      labelText: 'Amount',
                      hintText: '300',

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
                myServices[_selectedNetwork] == false ?
                SizedBox(
                  height: 100,
                  child: Center(
                    child: Text('Service Temporarily unavailable, please try again later!',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
                      textAlign: TextAlign.center,),
                  ),
                ) :
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            elevation: 4,
                            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                           side: BorderSide(
                             color: kButtonColor
                           )
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text('May be Later', style: TextStyle(color: Colors.white),)
                    ),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: kButtonColor,
                            elevation: 4,
                            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 50)
                        ),
                        onPressed: () {
                          print(_amountController.text);
                          if (_formKey.currentState!.validate()) {
                            double bonus = pov.airtimePercent *
                                int.parse(_amountController.text.replaceAll(',', ''));
                            showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder: (context) =>
                                    ConfirmationPage(
                                      amount: _amountController.text.replaceAll(',', ''),
                                      bonusEarn:
                                      (bonus).toDouble(),
                                      isRecharge: true,
                                      receiptData: {
                                        'Product Name' : '$_selectedNetwork Airtime',
                                        'Actual Amount' : ''
                                            '${kFormatter.format(double.parse(_amountController
                                            .text.replaceAll(',', '')))} NGN',
                                        'Recipient Mobile' : '0${_phoneController.text}',
                                        'Bonus to Earn' : '$kNaira${(bonus).toStringAsFixed(2) }'
                                      },
                                      onTap: (amount, reward, useReward) {
                                        TransactionService.handlePurchase(
                                          context: context,
                                          purchaseFunction: () async {
                                            try {
                                              if (currentRequestId != null) {
                                                return {
                                                  'status' : false
                                                };
                                              }
                                              currentRequestId = FirebaseConstant.clientRequestId();
                                              String humanReference = FirebaseConstant.generateTransactionId();
                                              final res = await PurchaseItems(context: context)
                                                  .purchaseAirtime(
                                                  humanRef: humanReference,
                                                  phone: '0${_phoneController.text}',
                                                  serviceId: _selectedNetwork.toLowerCase(),
                                                  amount: _amountController.text,
                                                  clientRequestId: currentRequestId!,
                                                  isRecharge: true,
                                                  useReward: useReward
                                              );
                                              print(res);
                                              return res;

                                            }
                                            catch(e) {
                                              rethrow;
                                            }
                                            finally {
                                              setState(() {
                                                currentRequestId = null;
                                              });
                                            }
                                          },
                                        );
                                      },
                                    )
                            );
                          }
                        },
                        child: Text('Proceed', style: GoogleFonts.inter(
                            color: Colors.black, fontWeight: FontWeight.bold),)
                    ),
                  ],
                )
              ],
            ),
          )
        ),
      ),
    );
  }
}
