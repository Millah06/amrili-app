import 'package:everywhere/shared/widgets/confirmation_page.dart';
import 'package:everywhere/components/transacrtion_pin.dart';
import 'package:everywhere/constraints/constants.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../components/formatters.dart';
import '../../../../components/notice_banner.dart';
import '../../../../components/textInput_formater.dart';
import '../../../../services/brain.dart';
import '../../../../services/purchase_service.dart';
import '../../../../services/transaction_service.dart';
import '../template_selection.dart';


enum ViewMode {  standardValue, customValue}

class AirtimeGift extends StatefulWidget {
  const AirtimeGift({super.key});

  @override
  State<AirtimeGift> createState() => _AirtimeGiftState();
}

class _AirtimeGiftState extends State<AirtimeGift> {

  String _selectedNetwork = 'MTN';
  String _selectedValue = '1000';
  final TextEditingController _senderController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _recipientNameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  // List networks = ['MTN', 'Airtel', 'Glo', '9mobile'];
  List value = ['500', '1000', '2000', '5000', '10000'];
  final _formKey = GlobalKey<FormState>();

  ViewMode _mode = ViewMode.standardValue;
  String ? message;

  bool userCancelNotice = false;

  @override
  Widget build(BuildContext context) {
    final pov = Provider.of<Brain>(context);

    Map<String, bool> myServices = pov.airtimeProviders;



    List<String> networks = myServices.keys.toList();

    bool oneServiceIsDown = myServices.containsValue(false);

    if (oneServiceIsDown) {
      final unavailable = MyFormatManager.getUnavailableServices(myServices);
      message = MyFormatManager.formatUnavailable(unavailable, 'airtime gift purchase');
    }

    return  Scaffold(
      appBar: AppBar(
        title: Text('Airtime Gift'),
      ),
      body: Form(
        key: _formKey,
        child: Container(
            padding: EdgeInsets.only(left: 15, right: 15, top: 30),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                    iconEnabledColor: Colors.white,
                    value: _selectedNetwork,
                    menuMaxHeight: 200,
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                    decoration: const InputDecoration(
                      filled: true,
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
                  _buildToggle(),
                  SizedBox(height: 20,),
                  _mode == ViewMode.standardValue ?
                  DropdownButtonFormField<String>(
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    dropdownColor: kCardColor,
                    padding: EdgeInsets.only(left: 10, right: 10),
                    iconSize: 30,
                    iconEnabledColor: Colors.white,
                    value: _selectedValue,
                    menuMaxHeight: 200,
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                    decoration: const InputDecoration(
                      labelText: 'Value on The Recharge Card',
                      labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                    ),
                    // style: const TextStyle(color: Colors.black),
                    items: value.map((range) {
                      return DropdownMenuItem<String>(
                          value: range,
                          child: Text(range, style: TextStyle(color: Colors.white),));
                    }).toList(),
                    onChanged: (val) {
                      // else if (val != null) {setState(() => selectedDateRange = val);};
                      setState(() => _selectedValue = val!);
                    },
                  )
                      : TextFormField(
                    controller: _amountController,

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
                  TextFormField(
                    controller: _phoneController,
                    cursorColor: Colors.white,

                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    decoration: InputDecoration(
                      filled: true,
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
                    controller: _senderController,

                    cursorColor: Colors.white,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      filled: true,
                      labelText: 'Sender Name',
                      hintText: 'John Steve',

                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'This field is required';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20,),
                  TextFormField(
                    controller: _recipientNameController,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    cursorColor: Colors.white,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      filled: true,
                      labelText: 'Recipient Name',
                      hintText: 'Angela Kieth',

                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'This field is required';
                      }
                      return null;
                    },
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
                            if (_formKey.currentState!.validate()) {
                              double bonus = pov.rCPersonalPercent * double.parse(_selectedValue);

                              String giftAmount = _mode == ViewMode.standardValue? _selectedValue :
                              _amountController.text.replaceAll(',', '');
                              showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  builder: (context) =>
                                      ConfirmationPage(
                                        amount: giftAmount,
                                        bonusEarn: (bonus).toDouble(),
                                        isRecharge: false,
                                        receiptData: {
                                          'Product Name' : '$_selectedNetwork Airtime Gift',
                                          'Actual Amount' : '$giftAmount NGN',
                                          'Recipient Mobile' : '0${_phoneController.text}',
                                          'Sender Name' : _senderController.text,
                                          'Receiver Name' : _recipientNameController.text,
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
                                                    phone: _phoneController.text,
                                                    serviceId: _selectedNetwork.toLowerCase(),
                                                    amount: giftAmount,
                                                    clientRequestId: '',
                                                    isRecharge: false,
                                                    useReward: useReward,
                                                );
                                                return res;
                                              }
                                              catch(e) {
                                                rethrow;
                                              }
                                            },
                                            airtimeGiftFunction: () {
                                              Navigator.pushReplacement(context,
                                                  MaterialPageRoute(builder: (context) =>
                                                      TemplateSelectionScreen(
                                                amount: _mode == ViewMode.standardValue? _selectedValue : _amountController.text,
                                                sender: _senderController.text,
                                                recipient: _recipientNameController.text,
                                                productName: '$_selectedNetwork Airtime Gift',
                                                phoneNumber: '+234 ${_phoneController.text}',
                                              )));
                                            },
                                            isGift: true
                                          );
                                        },
                                      )
                              );
                            }
                          },
                          child: Text('Proceed', style: TextStyle(color: Colors.black),)
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

  Widget _buildToggle() {

    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(12),
        topRight: Radius.circular(12),
        bottomLeft: Radius.circular(12),
        bottomRight: Radius.circular(12)
      ),
      child: CupertinoSegmentedControl<ViewMode>(
        groupValue: _mode,
        borderColor: Colors.black,
        selectedColor: kIconColor,
        unselectedColor: Colors.black,
        padding: EdgeInsets.only(left: 0, bottom: 10),
        children: {
          ViewMode.standardValue: Container(
            decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),

              ),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 6, horizontal: 6),
              child: Text('Standard Values', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),),
            ),
          ),
          ViewMode.customValue: Padding(
            padding: EdgeInsets.symmetric(vertical: 6, horizontal: 6),
            child: Text('Custom Values', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),),
          ),
        },
        onValueChanged: (v) => setState(() => _mode = v),
      ),
    );
  }

}
