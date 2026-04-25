import 'package:everywhere/shared/widgets/confirmation_page.dart';
import 'package:everywhere/components/transacrtion_pin.dart';
import 'package:everywhere/constraints/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../services/brain.dart';
import '../../../../services/purchase_service.dart';
import '../../../../services/transaction_service.dart';

class WaecServices extends StatefulWidget {
  const WaecServices({super.key});

  @override
  State<WaecServices> createState() => _WaecServicesState();
}

class _WaecServicesState extends State<WaecServices> {

  String ? _selectedSubService;
  String ? _selectedService;

  bool isSchool = false;

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _schoolNameController = TextEditingController();

  List serviceType = ['WAEC Registration', 'WAEC Result Checker'];
  Map<String, dynamic> ? currentData;
  final _formKey = GlobalKey<FormState>();

  bool isLoading = true;

  List<dynamic> waecRegistration = [];
  List<dynamic> waecPin = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async  {
    final fetchedWaecPin = await Brain().getAvailableWaecPin();
    final fetchedRegistration = await Brain().getAvailableWaecRegistration();
    setState(() {
      waecRegistration = fetchedRegistration;
      waecPin = fetchedWaecPin;
      isLoading = false;
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _phoneController.dispose();
    _quantityController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('WAEC Services'),
        ),
        body: Container(
            padding: EdgeInsets.only(left: 15, right: 15, top: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ...List.generate(3, (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: Shimmer.fromColors(
                          baseColor: kCardColor,
                          highlightColor: Colors.grey.shade600,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[900],
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    )),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Row(
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
                          },
                          child: Text('Buy Now', style: TextStyle(color: Colors.black),)
                      ),
                    ],
                  ),
                ),
              ],
            )
        ),
      );
    }

    final pov = Provider.of<Brain>(context);
    List myWaecSubType = _selectedService == 'WAEC Registration' ? waecRegistration : waecPin;

    return  Scaffold(
      appBar: AppBar(
        title: Text('WAEC Services'),
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
                    value: _selectedService,
                    menuMaxHeight: 200,
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                    decoration: const InputDecoration(
                      labelText: 'Service Type',
                      labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                    ),
                    // style: const TextStyle(color: Colors.black),
                    items: serviceType.map((range) {
                      return DropdownMenuItem<String>(
                          value: range,
                          child: Text(range, style: TextStyle(color: Colors.white),));
                    }).toList(),
                    onChanged: (val) {
                      // else if (val != null) {setState(() => selectedDateRange = val);};
                      setState(()  {
                        _selectedService = val!;
                        _selectedSubService = null;
                      });
                    },
                  ),
                  Visibility(
                    visible: _selectedService != null,
                    child: Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: DropdownButtonFormField<String>(
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      dropdownColor: kCardColor,
                      padding: EdgeInsets.only(left: 10, right: 10),
                      iconSize: 30,
                      iconEnabledColor: Colors.white,
                      value: _selectedSubService,
                      menuMaxHeight: 200,
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                      decoration: const InputDecoration(
                        labelText: 'Service Type',
                        labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),

                      ),
                      // style: const TextStyle(color: Colors.black),
                      items: myWaecSubType.map((range) {
                        return DropdownMenuItem<String>(
                            value: range['name'],
                            child: Text(range['name'].split('-').first!, style: TextStyle(color: Colors.white),));
                      }).toList(),
                      onChanged: (val) {
                        // else if (val != null) {setState(() => selectedDateRange = val);};
                        setState(() {
                          _selectedSubService = val!;
                          currentData = myWaecSubType.firstWhere((theMap)
                          => theMap['name'] == _selectedSubService.toString());
                        }
                        );
                      },
                    ),
                    ),
                  ),
                  SizedBox(height: 20,),
                  TextFormField(
                    controller: _quantityController,
                    cursorColor: Colors.white,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      suffix: Text('Candidates', style: TextStyle(color: Colors.white, fontSize: 16,
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
                    onChanged: (value) {
                      if (int.tryParse(value)! > 1) {
                        setState(() {
                          isSchool = true;
                        });
                      }
                      else {
                        setState(() {
                          isSchool = false;
                        });
                      }
                    },
                  ),
                  Visibility(
                    visible: isSchool,
                    child: Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: TextFormField(
                          controller: _schoolNameController,
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                          cursorColor: Colors.white,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            labelText: 'School Name',
                            hintText: 'Oxford High School',
                            labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'This field is required';
                            }
                            return null;
                            },
                        ),
                    ),
                  ),
                  SizedBox(height: 20,),
                  TextFormField(
                    controller: _phoneController,
                    cursorColor: Colors.white,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      prefix: Text('+234 | ',
                        style: TextStyle(color: Colors.white, fontSize: 16,
                            fontWeight: FontWeight.w900),),
                      labelText: 'Phone Number',
                      hintText: '8023344567',
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
                              showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  builder: (context) =>
                                      ConfirmationPage(
                                        amount: '${double.parse(currentData?['variation_amount']) * int.parse(_quantityController.text)}',
                                        isRecharge: false,
                                        bonusEarn: (pov.rCPersonalPercent * double.parse(currentData?['variation_amount']) * int.parse(_quantityController.text)).toDouble(),
                                        receiptData: {
                                          'Product Name' : currentData?['name'],
                                          'Actual Amount' : '$kNaira${(
                                              double.parse(currentData!['variation_amount']) *
                                                  int.parse(_quantityController.text)).toStringAsFixed(2)} NGN',
                                          'Phone Number' : '0${_phoneController.text}',
                                          if (int.parse(_quantityController.text) > 1)
                                            'School Name' : _schoolNameController.text,
                                          if (int.parse(_quantityController.text) > 1)
                                            'Number Of Candidates' : _quantityController.text,
                                          'Bonus to Earn' : '$kNaira${(pov.airtimePercent *
                                              double.parse(currentData!['variation_amount']) *
                                              int.parse(_quantityController.text)).toStringAsFixed(2) }'

                                        },
                                        onTap: (amount, reward, useReward) {
                                          TransactionService.handlePurchase(
                                            context: context,

                                            purchaseFunction: () async {
                                              try {
                                                final res =
                                                _selectedService == 'WAEC Result Checker' ? await PurchaseItems(context: context)
                                                    .purchaseWaecResultPin(
                                                    int.parse(_quantityController.text),
                                                    _phoneController.text,
                                                    currentData?['variation_code'],
                                                    isSchool ? (double.parse(currentData?['variation_amount'])
                                                        * double.parse(_quantityController.text)).toString() : currentData?['variation_amount']

                                                ) :
                                                await PurchaseItems(context: context)
                                                    .purchaseWaecRegistration(
                                                  _phoneController.text,
                                                  currentData?['variation_code'],
                                                  isSchool ? (double.parse(currentData?['variation_amount'])
                                                      * double.parse(_quantityController.text)).toString() : currentData?['variation_amount'],
                                                  int.parse(_quantityController.text),

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
