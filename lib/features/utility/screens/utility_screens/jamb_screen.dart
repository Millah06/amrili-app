import 'package:everywhere/shared/widgets/confirmation_page.dart';
import 'package:everywhere/components/transacrtion_pin.dart';
import 'package:everywhere/constraints/constants.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../services/brain.dart';
import '../../../../services/purchase_service.dart';
import '../../../../services/transaction_service.dart';

class JambServices extends StatefulWidget {
  const JambServices({super.key});

  @override
  State<JambServices> createState() => _JambServicesState();
}

class _JambServicesState extends State<JambServices> {

  String ? _selectedService;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _profileCodeController = TextEditingController();

  List networks = ['MTN', 'Airtel', 'Glo', '9mobile'];
  Map<String, dynamic> ? currentData;
  final _formKey = GlobalKey<FormState>();
  Future<String?>? customerName;
  bool readyToShowName = false;
  List<dynamic> jambServices = [];
  bool isLoading = true;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async  {
    final fetchedJamb = await Brain().getAvailableJambServices();
    setState(() {
      isLoading = false;
      jambServices = fetchedJamb;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('JAMB Services'),
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
    List myJambServices = jambServices;

    return  Scaffold(
      appBar: AppBar(
        title: Text('JAMB Services'),
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


                    ),
                    // style: const TextStyle(color: Colors.black),
                    items: myJambServices.map((range) {
                      return DropdownMenuItem<String>(
                          value: range['name'],
                          child: Text(range['name']!, style: TextStyle(color: Colors.white),));
                    }).toList(),
                    onChanged: (val) {
                      // else if (val != null) {setState(() => selectedDateRange = val);};
                      setState(() {
                      _selectedService = val!;
                      currentData = myJambServices.firstWhere((theMap) => theMap['name'] == _selectedService.toString());
                      }
                      );
                    },
                  ),
                  SizedBox(height: 20,),
                  TextFormField(
                    controller: _profileCodeController,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    cursorColor: Colors.white,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        labelText: 'Profile Code',
                        hintText: '2023CGGHIDFDD',

                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'This field is required';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      if (value.length == 10) {
                        customerName = PurchaseItems(context: context).verifyJambCandidate(_phoneController.text, 'jamb');
                        setState(() {
                          readyToShowName = true;
                        });
                      }
                      else if (value.length < 10) {
                        setState(() {
                          readyToShowName = false;
                        });
                      }
                    },
                  ),
                  SizedBox(height: 15,),
                  Visibility(
                      visible: readyToShowName,
                      child: Column(
                        children: [
                          FutureBuilder<String?>(
                              future: customerName,
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value: 5,
                                      backgroundColor: kCardColor,
                                      color: kButtonColor,
                                    ),
                                  );
                                }
                                return Container(
                                  padding: EdgeInsets.only(left: 10, right: 10, top: 0, bottom: 0),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      // color: Color(0xFF1E293B),
                                      border: Border.all(
                                          color: Colors.white70,
                                          width: 0.5
                                      )
                                  ),
                                  child: ListTile(
                                    contentPadding: EdgeInsets.symmetric(vertical: 0),
                                    leading: Icon(Icons.person, color:  Color(0xFF21D3ED),
                                      size: 26,),
                                    title: Text(snapshot.data!,
                                      style:
                                      TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.white),),
                                    trailing: FaIcon(Icons.check_circle,
                                      color:  Color(0xFF21D3ED),
                                      size: 26,
                                    ),
                                  )
                                );
                              }
                          )
                        ],
                      )
                  ),
                  SizedBox(height: 15,),
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
                                        amount: '${currentData?['variation_amount']}',
                                        bonusEarn: (pov.rCPersonalPercent * double.parse(currentData?['variation_amount'])).toDouble(),
                                        isRecharge: false,
                                        receiptData: {
                                          'Product Name' : _selectedService,
                                          'Actual Amount' : '${currentData?['variation_amount']} NGN',
                                          'Phone Number' : '0${_phoneController.text}',
                                          'Bonus to Earn' : '$kNaira${(pov.jambPercent * double.parse(currentData?['variation_amount'])).toStringAsFixed(2)}'
                                        },
                                        onTap: (amount, reward, useReward) {
                                          TransactionService.handlePurchase(
                                            context: context,
                                            purchaseFunction: () async {
                                              try {
                                                final res = await PurchaseItems(context: context)
                                                    .purchaseJamb(
                                                    _profileCodeController.text, _phoneController.text,
                                                    currentData?['variation_code'],
                                                    currentData?['variation_amount']
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
