import 'package:dotted_border/dotted_border.dart';
import 'package:everywhere/components/electric_plan_frame.dart';
import 'package:everywhere/features/utility/models/electric_plan.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/confirmation_page.dart';
import '../../../../components/formatters.dart';
import '../../../../components/notice_banner.dart';
import '../../../../components/textInput_formater.dart';
import '../../../../constraints/constants.dart';
import '../../../../services/brain.dart';
import '../../../../services/purchase_service.dart';
import '../../../../services/transaction_service.dart';
import '../../services/utility_purchase.dart';

enum ViewMode {  standardValue, customValue}

class ElectricScreen extends StatefulWidget {
  const ElectricScreen({super.key});

  @override
  State<ElectricScreen> createState() => _ElectricScreenState();
}

class _ElectricScreenState extends State<ElectricScreen>  with SingleTickerProviderStateMixin {

  TabController ? _tabController;

  bool readyToShowName = false;
  bool adIsTouch = false;
  Future<Map<String, dynamic>?>? customerDetails;

  String _selectedProvider = 'Jos Electricity';
  String _selectedMeterType = 'Prepaid';
  final TextEditingController _meterNumberController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  List meterType = ['Prepaid', 'Postpaid'];

  Map<String, List<ElectricPlanModel>> electricPlans = {
    'Regular': [
      ElectricPlanModel(amount: 1000),
      ElectricPlanModel(amount: 2000),
      ElectricPlanModel(amount: 5000),
      ElectricPlanModel(amount: 9000),
      ElectricPlanModel(amount: 10000),
      ElectricPlanModel(amount: 15000),
    ],
    'Wise Man': [
      ElectricPlanModel(amount: 3000),
      ElectricPlanModel(amount: 6000),
      ElectricPlanModel(amount: 11000),
      ElectricPlanModel(amount: 18000),
      ElectricPlanModel(amount: 30000),
      ElectricPlanModel(amount: 45000),
    ],
    'Monthly': [
      ElectricPlanModel(amount: 25000),
      ElectricPlanModel(amount: 60000),
      ElectricPlanModel(amount: 75000),
      ElectricPlanModel(amount: 35000),
      ElectricPlanModel(amount: 60000),
      ElectricPlanModel(amount: 100000),
    ]
  };



  bool meterNumberIsIncorrect = true;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _tabController = TabController(length: electricPlans.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    // TODO: implement dispose
    super.dispose();
  }

  Color buttonColor = kButtonColor;
  Color textColor = Colors.black;

  String?  message;

  bool userCancelBanner = false;

  ViewMode _mode = ViewMode.standardValue;

  int ? _selectedIndex;

  @override
  Widget build(BuildContext context) {

    final pov = Provider.of<Brain>(context);

    Map<String, bool> myServices = pov.electricProviders;



    List<String> providers = myServices.keys.toList();

    bool oneServiceIsDown = myServices.containsValue(false);

    if (oneServiceIsDown) {
      final unavailable = MyFormatManager.getUnavailableServices(myServices);
      message = MyFormatManager.formatUnavailable(unavailable, 'payment');
    }

    Future<Map<String, dynamic>> validateMeterNumber(String meterType, String selectedProvider, meterNumber) async {
      final result = await PurchaseItems(context: context).verifyMeter(
          meterType: meterType, meterNumber: meterNumber, selectedProvider: selectedProvider);
      if (result!.isEmpty) {
        setState(() {
          meterNumberIsIncorrect = true;
          readyToShowName = false;
        });

      }
      else {
        setState(() {
          meterNumberIsIncorrect = false;
        });
      }
      _formKey.currentState?.validate();

      return result;
    }

    if (meterNumberIsIncorrect) {
      setState(() {
        textColor = Colors.white60;
        buttonColor = Color(0x3321DEED);
      });
    }

    else {
      setState(() {
        textColor = Colors.black;
        buttonColor = kButtonColor;
      });
    }


    return DefaultTabController(
      initialIndex: 1,
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Electricity Unit Purchase'),
        ),
        body: Form(
          key: _formKey,
          child: Stack(
            children: [
              Positioned(
                right: 10,
                  top: 10,
                  child: Container(
                    margin: EdgeInsets.only(bottom: 0),
                    alignment: Alignment.topRight,
                    decoration: BoxDecoration(
                      color: Color(0xFF1E293B),
                        border: Border.all(
                            color:  Color(0xFFE3E3E3),
                            width: 0.4
                        )
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          FaIcon(FontAwesomeIcons.userPlus, size: 14,),
                          SizedBox(width: 7,),
                          Text('Easily Load from Recent Beneficiary',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900),),
                        ],
                      ),
                    ),
                  )
              ),
              Container(
                padding: EdgeInsets.only(left: 12, right: 12, top: 45),
                child: SingleChildScrollView(
                  // padding: EdgeInsets.zero,
                  clipBehavior: Clip.none,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      userCancelBanner? SizedBox() : Visibility(
                        visible: oneServiceIsDown,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: NoticeBanner(
                            noticeMessage: message ?? '34',
                            onClose: () {
                              setState(() {
                                userCancelBanner = true;
                              });
                            },
                          ),
                        ),
                      ),
                      DropdownButtonFormField<String>(
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                        dropdownColor: kCardColor,
                        padding: EdgeInsets.only(left: 10, right: 10),
                        iconSize: 25,
                        iconEnabledColor: Colors.white,
                        value: _selectedProvider,
                        menuMaxHeight: 200,
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                        decoration: const InputDecoration(
                            labelText: 'Provider',

                        ),
                        // style: const TextStyle(color: Colors.black),
                        items: providers.map((range) {
                          return DropdownMenuItem<String>(
                              value: range,
                              child: Text(range, style: TextStyle(color: Colors.white),));
                        }).toList(),
                        onChanged: (val) {
                          // else if (val != null) {setState(() => selectedDateRange = val);};
                          setState(() {
                            _selectedProvider = val!;
                            readyToShowName = false;
                            meterNumberIsIncorrect = true;
                          });
                        },
                      ),
                      SizedBox(height: 20,),
                      DropdownButtonFormField<String>(
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        dropdownColor: kCardColor,
                        padding: EdgeInsets.only(left: 10, right: 10),
                        iconSize: 25,
                        iconEnabledColor: Colors.white,
                        value: _selectedMeterType,
                        menuMaxHeight: 200,
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                        decoration: const InputDecoration(
                            labelText: 'Meter Type',

                        ),
                        // style: const TextStyle(color: Colors.black),
                        items: meterType.map((range) {
                          return DropdownMenuItem<String>(
                              value: range,
                              child: Text(range, style: TextStyle(color: Colors.white, fontSize: 14),));
                        }).toList(),
                        onChanged: (val) {
                          // else if (val != null) {setState(() => selectedDateRange = val);};
                          setState((){
                            _selectedMeterType = val!;
                            readyToShowName = false;
                            meterNumberIsIncorrect = true;
                          });
                        },
                      ),
                      SizedBox(height: 20,),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          TextFormField(
                            controller: _meterNumberController,
                            cursorColor: Colors.white,
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                                labelText: 'Meter Number',
                                 hintText: '28023344567',


                            ),
                            onChanged: (value) {

                            },
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'This field is required';
                              }
                              if (meterNumberIsIncorrect) {
                                return 'Incorrect Cable Number';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 10,),
                          GestureDetector(
                            onTap: () {
                              if (_meterNumberController.text.isNotEmpty) {
                                setState(() {
                                  customerDetails = validateMeterNumber(
                                    _selectedMeterType,
                                    _selectedProvider,
                                    _meterNumberController.text,
                                  );
                                  readyToShowName = true;
                                });
                              }
                              else {
                                _formKey.currentState?.validate();
                              }
                            },
                            child: Card(
                              color: buttonColor,
                              elevation: 4,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                decoration: BoxDecoration(
                                  // color: buttonColor,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [BoxShadow(color: Color(0xFF177E85).withOpacity(0.4),
                                        blurRadius: 8, spreadRadius: 1, offset: Offset(0, 4))]
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Validate',
                                      style: GoogleFonts.inter(
                                          color: textColor, fontWeight: FontWeight.w900, fontSize: 11),
                                    ),
                                    Visibility(
                                      visible: !meterNumberIsIncorrect,
                                      child:  Icon(Icons.check_circle, color: Colors.black, size: 15,),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20,),
                      Visibility(
                          visible: readyToShowName,
                          child: Padding(
                            padding:  EdgeInsets.only(bottom: 20),
                            child: Column(
                              children: [
                                FutureBuilder<Map<String, dynamic>?>(
                                    future: customerDetails,
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData) {
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value: 10,
                                            backgroundColor: kCardColor,
                                            color: kButtonColor,
                                          ),
                                        );
                                      }
                                      if (snapshot.data == null || snapshot.data!.isEmpty) {
                                        return SizedBox();
                                      }
                                      print(snapshot.data);
                                      Map verifiedInformation = {
                                        'Name' : snapshot.data?['name'] ?? 'Name not Found',
                                        'Address' :  snapshot.data?['address'] ?? 'Address not fount',
                                        'Minimum Purchase' : '$kNaira${snapshot.data?['minimumPurchase'].toString()}' ?? 'Minimum Purchase not Found',
                                        'Meter Type' : snapshot.data?['meterType'] ?? 'Prepaid'
                                      };
                                      return Stack(
                                        children: [
                                          Container(
                                          padding: EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
                                            decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(10),
                                                color: Color(0xFF1E293B),
                                                border: Border.all(
                                                    color: Colors.black,
                                                    width: 0.5
                                                )
                                            ),
                                          child: Column(
                                            children: [
                                              Column(
                                                children: [
                                                  ...List.generate(4, (index) {

                                                    String key = verifiedInformation.keys.toList()[index];
                                                    String value = verifiedInformation.values.toList()[index];

                                                    return Padding(
                                                      padding: const EdgeInsets.only(top: 10),
                                                      child: Column(
                                                        children: [
                                                          Row(
                                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                            children: [
                                                              Text(key, style: GoogleFonts.raleway(fontSize: 11), ),
                                                              SizedBox(width: 50,),
                                                              Flexible(
                                                                  child: Text(softWrap: true, value, textAlign: TextAlign.end,style:
                                                                  GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 11),)
                                                              )
                                                            ],
                                                          ),
                                                          SizedBox(height: 7,)
                                                        ],
                                                      ),
                                                    );

                                                  })
                                                ],
                                              ),
                                              Visibility(
                                                visible: !adIsTouch,
                                                child: GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      adIsTouch = true;
                                                    });
                                                  },
                                                  child: Container(
                                                    margin: EdgeInsets.only(top: 10),
                                                    child: DottedBorder(
                                                      options: RectDottedBorderOptions(
                                                          color: kIconColor,
                                                          strokeWidth: 1,
                                                          dashPattern: [6, 2]
                                                      ),
                                                      child: Container(
                                                        height: 35,
                                                        decoration: BoxDecoration(
                                                            border: Border(),
                                                            color: Colors.black
                                                        ),
                                                        child: Row(
                                                          crossAxisAlignment: CrossAxisAlignment.center,
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: [
                                                            FaIcon(FontAwesomeIcons.plusCircle),
                                                            SizedBox(width: 10,),
                                                            Text('Add to Beneficiaries', style: TextStyle(color: kIconColor),)
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                          Positioned(
                                              right: 2,
                                              top: 2,
                                              child: Icon(Icons.check_circle,
                                                color: adIsTouch ? Color(0xFF21D3ED) : Colors.white70, size: 15,)
                                          ),
                                        ]
                                      );
                                    }
                                )
                              ],
                            ),
                          )
                      ),
                      _buildToggle(),
                      _mode == ViewMode.standardValue
                          ? Wrap(
                        spacing: 10,
                        runSpacing: 15,
                        children: [
                          Container(
                            color: Color(0xFF0F172A),
                            padding: EdgeInsets.only(top: 10),
                            child: TabBar(
                              controller: _tabController,
                              tabs: [
                                ...electricPlans.keys.toList().map((x) =>
                                    Text(x, style: GoogleFonts.raleway(),)),
                              ],
                              tabAlignment: TabAlignment.start,
                              isScrollable: true,
                              dividerHeight: 0,
                              labelColor: Colors.white,
                              labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                              labelPadding: EdgeInsets.only(right: 30, bottom: 5),
                              indicatorColor: Color(0xFF21D3ED),
                              indicator: UnderlineTabIndicator(
                                borderSide: BorderSide(width: 2, color:  Color(0xFF21D3ED)),
                                insets: EdgeInsets.symmetric(horizontal: 0),
                              ),
                            ),
                          ),
                          SizedBox(height: 30,),
                          Container(
                              height: 190,
                              width: double.infinity,
                              margin: EdgeInsets.only(left: 0, right: 0, top: 0),
                              padding: EdgeInsets.only(top: 10, left: 5, right: 5, bottom: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Color(0xFF1E293B),
                              ),
                              child:  TabBarView(
                                controller: _tabController,
                                children: [
                                  ...electricPlans.keys.toList().map((key) {
                                    final items = electricPlans[key]!;
                                    return GridView.builder(
                                        padding: EdgeInsets.zero,
                                        physics: NeverScrollableScrollPhysics(),
                                        gridDelegate:  SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 3,
                                          childAspectRatio: 1.07,
                                          crossAxisSpacing: 10,
                                          mainAxisSpacing: 0,
                                        ),
                                        itemCount: items.length,
                                        itemBuilder: (context, index) {
                                          final service = items[index];
                                          bool isSelected = _selectedIndex == index;
                                          return ElectricPlanFrame(
                                            cashBack: (pov.cablePercent * service.amount).toStringAsFixed(2),
                                            amount: service.amount,
                                            onTap: () {
                                              setState(() {
                                                _amountController.text = service.amount.toStringAsFixed(2);
                                                _selectedIndex = index;
                                              });
                                            },
                                            isTap: isSelected,
                                          );
                                        }
                                    );
                                  })
                                ],
                              )
                          ),
                        ],
                      )
                          :  Padding(
                          padding: EdgeInsets.only(top: 10, bottom: 10),
                        child: TextFormField(
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
                      ),
                      SizedBox(height: 10,),
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
                                onPressed: () async {
                                  if (_formKey.currentState!.validate()) {
                                    double bonus = pov.electricPercent *
                                        double.parse(_amountController.text.replaceAll(',', ''));

                                    final ok = await UtilityPurchase.buy(
                                      context,
                                      amount: double.parse(_amountController.text.replaceAll(',', '')),
                                      productName: _selectedProvider,
                                      service: 'electricity',
                                      serviceID: '${ _selectedProvider.split(' ').first.toLowerCase()}-electric',                  // e.g. 'ikeja-electric'
                                      phone:  '08087798514',
                                      billersCode: _meterNumberController.text,     // meter number
                                      variationCode:  _selectedMeterType,              // 'prepaid' | 'postpaid'
                                      // useReward: _useReward,
                                      isRecharge: false,
                                    );
                                    // if (ok) _resetForm();
                                  }
                                },
                                child: Text('Proceed', style: TextStyle(color: Colors.black),)
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
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
              child: Text('Standard Plans', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),),
            ),
          ),
          ViewMode.customValue: Padding(
            padding: EdgeInsets.symmetric(vertical: 6, horizontal: 6),
            child: Text('Custom Plan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),),
          ),
        },
        onValueChanged: (v) => setState(() => _mode = v),
      ),
    );
  }

}
