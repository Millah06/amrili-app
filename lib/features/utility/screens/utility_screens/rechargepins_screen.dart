import 'package:everywhere/shared/widgets/confirmation_page.dart';
import 'package:everywhere/components/transacrtion_pin.dart';
import 'package:everywhere/constraints/constants.dart';
import 'package:everywhere/services/receipt_builder.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../services/brain.dart';
import '../../../../services/purchase_service.dart';
import '../../../../services/transaction_service.dart';

class RechargePinsBusiness extends StatefulWidget {
  const RechargePinsBusiness({super.key});

  @override
  State<RechargePinsBusiness> createState() => _RechargePinsBusinessState();
}

class _RechargePinsBusinessState extends State<RechargePinsBusiness> {

  String _selectedNetwork = 'MTN';
  String _selectedValue = '200';
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _businessNameController = TextEditingController();

  List networks = ['MTN', 'AIRTEL', 'GLO', '9MOBILE'];
  List value = ['100', '200', '500', '1000'];

  String pins = "12345678901234567,23456789012345678,"
      "34567890123456789,45678901234567890,56789012345678901,67890123456789012,"
      "78901234567890123,89012345678901234,90123456789012345,"
      "78901234567890123,89012345678901234,90123456789012345,"
      "78901234567890123,89012345678901234,90123456789012345,"
      "78901234567890123,89012345678901234,90123456789012345,90123456789012345,78901234567890123,89012345678901234,90123456789012345";

  String serials = "98765432101234567,87654321098765432,76543210987654321,"
      "65432109876543210,54321098765432109,43210987654321098,32109876543210987,"
      "21098765432109876,10987654321098765,"
      "78901234567890123,89012345678901234,"
      "90123456789012345,78901234567890123,89012345678901234,90123456789012345,"
      "78901234567890123,89012345678901234,90123456789012345,90123456789012345,78901234567890123,89012345678901234,90123456789012345";

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {

    final pov = Provider.of<Brain>(context);

    return  Scaffold(
      appBar: AppBar(
        title: Text('Recharge Card Business'),
      ),
      body: Form(
        key: _formKey,
        child: Container(
            padding: EdgeInsets.only(left: 15, right: 15, top: 30),
            child: SingleChildScrollView(
              child: Column(
                children: [
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
                      setState(() => _selectedNetwork = val!);
                    },
                  ),
                  SizedBox(height: 20,),
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
                  ),
                  SizedBox(height: 20,),
                  TextFormField(
                    controller: _quantityController,
                    cursorColor: Colors.white,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      suffix: Text('Cards', style: TextStyle(color: Colors.white, fontSize: 16,
                          fontWeight: FontWeight.w900)),
                        labelText: 'Quantity',
                        hintText: '50',
                        labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
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
                    controller: _businessNameController,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    cursorColor: Colors.white,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                        labelText: 'Business Name',
                        hintText: 'Everywhere Sub',
                        labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'This field is required';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20,),
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
                              double bonus = pov.rCBusinessPercent *
                                  double.parse(_selectedValue) *
                                  int.parse(_quantityController.text);
                              showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  builder: (context) =>
                                      ConfirmationPage(
                                        amount: '${int.parse(_selectedValue) * int.parse(_quantityController.text)}',
                                        isRecharge: true,
                                        bonusEarn: (bonus).toDouble(),
                                        receiptData: {
                                          'Product Name' : '$_selectedNetwork Recharge Pins',
                                          'Business Name' : _businessNameController.text,
                                          'Actual Amount' : '${int.parse(_selectedValue) * int.parse(_quantityController.text)} NGN',
                                          'Value Per Card' : _selectedValue,
                                          'Bonus to Earn' : '$kNaira${(bonus).toStringAsFixed(2) }'
                                        },
                                        onTap: (amount, reward, useReward) {
                                          // ReceiptBuilder().exportToPdf('', context, myData: {
                                          //   'Product Name' : '$_selectedNetwork Recharge PIN',
                                          //   'Amount' : '${int.parse(_selectedValue) * int.parse(_quantityController.text)} NGN',
                                          //   'Business Name' : _businessNameController.text,
                                          //   'Transaction ID' : '123445597669900098',
                                          //   'Date' : DateTime.now(),
                                          //   'Status' : 'Successful',
                                          //   'pins' : pins.split(','),
                                          //   'numberOfCards' : _quantityController.text
                                          // });
                                          TransactionService.handlePurchase(
                                            context: context,
                                            purchaseFunction: () async {
                                              try {
                                                final res = await PurchaseItems(context: context)
                                                    .purchaseRechargePin(
                                                    _selectedNetwork,
                                                    _selectedValue,
                                                    _quantityController.text,
                                                    _businessNameController.text
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
