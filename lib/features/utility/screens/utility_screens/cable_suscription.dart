import 'package:everywhere/components/formatters.dart';
import 'package:everywhere/components/notice_banner.dart';
import 'package:everywhere/providers/user_provider.dart';
import 'package:everywhere/services/purchase_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../shared/widgets/confirmation_page.dart';
import '../../../../constraints/constants.dart';
import '../../../../constraints/firebase_constant.dart';
import '../../../../services/brain.dart';
import '../../../../services/transaction_service.dart';
import '../../models/tv_model.dart';

class CableSubscription extends StatefulWidget  {
  const CableSubscription({super.key});

  @override
  State<CableSubscription> createState() => _CableSubscriptionState();
}

class _CableSubscriptionState extends State<CableSubscription> with TickerProviderStateMixin {

  TabController ? _tabController;

  Map<String, List<TvCategoryData>> _categories = {};
  bool isLoading = true;
  String _selectedProvider = 'DStv';
  bool readyToShowName = false;
  bool cableNumberIsIncorrect = true;

  final Map<int, int?> _selectedIndices = {};

  @override
  void initState() {
    // TODO: implement initState
    _fetchData();
    super.initState();
  }

  Future<void> _fetchData() async  {
    final fetchedCategories = await fetchCategories();
    setState(() {
      _categories = fetchedCategories;
      _tabController = TabController(
          length: _categories[_selectedProvider]!.length, vsync: this);
      isLoading = false;
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _tabController?.dispose();
    _smartController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  final TextEditingController _smartController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  // List providers = ['DStv', 'GOtv', 'StarTimes', 'SHOWMAX'];
  String ? message;
  bool userCancelNotice = false;
  final _formKey = GlobalKey<FormState>();
  Future<Map<String, dynamic>?>? customerDetails;

  Future<Map<String, List<TvCategoryData>>> fetchCategories() async {
    final ref = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: "https://everywhere-9278c-default-rtdb.europe-west1.firebasedatabase.app/"
    ).ref('tv');
    final snapshot = await ref.get();

    if (!snapshot.exists) throw Exception('No data found');

    final Map<String, dynamic> data = Map<String, dynamic>.from(snapshot.value as Map);

    final Map<String, List<TvCategoryData>> result = {};

    data.forEach((networkKey, categoryListRaw) {
      final List<dynamic> categoryList = List<dynamic>.from(categoryListRaw);

      final List<TvCategoryData> categoryDataList = categoryList.map((categoryRaw) {
        final Map<String, dynamic> categoryMap = Map<String, dynamic>.from(categoryRaw);
        return TvCategoryData.fromMap(categoryMap);
      }).toList();

      result[networkKey] = categoryDataList;
    });

    return result;
  }

  Widget _buildPlanGrid(List<TvPlan> plans, int tabIndex) {
    int ? selectedIndex = _selectedIndices[tabIndex];
    final pov = Provider.of<Brain>(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: 15, left: 0, right: 0),
      child: GridView.builder(
          gridDelegate:  SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1,
              crossAxisSpacing: 30,
              mainAxisSpacing: 15,
          ),
          shrinkWrap: true,
          itemCount: plans.length,
          itemBuilder: (context, index) {
            final plan = plans[index];
            bool isSelected = selectedIndex == index;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedIndices[tabIndex] = index;
                  isSelected = !isSelected;
                });
              },
              child: Stack(
                children: [
                  Container(
                    width: 150,
                    decoration: BoxDecoration(
                        color: isSelected ? Colors.transparent : kCardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: isSelected ? kButtonColor : kCardColor, width: 1.5)
                    ),
                    padding: EdgeInsets.only(left: 0, right: 0, top: 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Center(
                                child: Padding(
                                  padding: EdgeInsets.only(left: 10, right: 10, bottom: 10),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(plan.description,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(color: Colors.white,
                                            fontSize: 12, fontWeight: FontWeight.w700),),
                                      SizedBox(height: 4,),
                                      Text(plan.duration,
                                        style: TextStyle(color: Colors.white54,
                                            fontWeight: FontWeight.w700, fontSize: 15),),
                                      SizedBox(height: 6,),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text('₦',  style: TextStyle(color: Colors.white54,
                                              fontWeight: FontWeight.w700, fontSize: 14)),
                                          SizedBox(width: 3,),
                                          Text(kFormatterNo.format(double.tryParse(plan.price.split('.').first)),
                                            style: GoogleFonts.poppins(color: Colors.white,
                                                fontWeight: FontWeight.w600, fontSize: 17),),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            ],
                          ),
                        ),
                        Container(
                            height: 15,
                            width: 150,
                            decoration: BoxDecoration(
                                color: Colors.white70,
                                borderRadius: BorderRadius.only(
                                    bottomRight: Radius.circular(12),
                                    bottomLeft: Radius.circular(12)
                                )
                            ),
                            child: Center(child: 
                            Text('$kNaira${(double.parse(plan.price) * pov.cablePercent).toStringAsFixed(2)} cashback',
                              style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w700),)),
                          )
                      ],
                    ),
                  ),
                  if (isSelected)
                    Positioned(
                        top: 2,
                        right: 2,
                        child: Icon(Icons.check_circle, color: kIconColor, size: 15)
                    )
                ],
              ),
            );
          }
      ),
    );
  }

  Color buttonColor = kButtonColor;
  Color textColor = Colors.black;
  String ? currentRequestId;

  @override
  Widget build(BuildContext context) {

    final pov = Provider.of<Brain>(context);

    Map<String, bool> myServices = pov.cableProviders;



    List<String> providers = myServices.keys.toList();

    bool oneServiceIsDown = myServices.containsValue(false);

    if (oneServiceIsDown) {
      final unavailable = MyFormatManager.getUnavailableServices(myServices);
      message = MyFormatManager.formatUnavailable(unavailable, 'subscription');
    }



    Future<Map<String, dynamic>> validateCable(String cableNumber, String selectedProvider) async {
      final result = await PurchaseItems(context: context).verifyCable(cableNumber, selectedProvider);
      print(result);
      if (result!.isEmpty) {
        setState(() {
          cableNumberIsIncorrect = true;
          readyToShowName = false;
        });

      }
      else {
        setState(() {
          cableNumberIsIncorrect = false;
        });
      }

      _formKey.currentState!.validate();

      return result;
    }

    if (cableNumberIsIncorrect) {
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

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Cable Subscription'),
        ),
        body: Form(
          key: _formKey,
          child: Container(
              padding: EdgeInsets.only(left: 15, right: 15, top: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        dropdownColor: kCardColor,
                        padding: EdgeInsets.only(left: 10, right: 10),
                        iconSize: 30,
                        iconDisabledColor: kButtonColor,
                        iconEnabledColor: kButtonColor,
                        value: _selectedProvider,
                        menuMaxHeight: 200,
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                        decoration: const InputDecoration(
                          labelText: 'Providers',

                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'This field is required';
                          }
                          return null;
                        },
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
                            _selectedIndices.clear();
                            _tabController?.dispose();
                            _tabController = TabController(
                                length: _categories[_selectedProvider]!.length,
                                vsync: this,
                                initialIndex: 0
                            );
                          });
                        },
                      ),
                      SizedBox(height: 20,),
                      TextFormField(
                        cursorColor: Colors.white,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          prefix: _selectedProvider == 'StarTimes ON'
                              || _selectedProvider == 'SHOWMAX' ? Text('+234 | ',
                            style: TextStyle(color: Colors.white, fontSize: 16,
                                fontWeight: FontWeight.w900),) : Text(''),
                          labelText: _selectedProvider == 'StarTimes ON'
                              || _selectedProvider == 'SHOWMAX' ? 'Enter Your Mobile Number'
                              : 'Enter Your Smartcard Number',
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
                      Padding(
                        padding: const EdgeInsets.only(left: 0),
                        child: Text('TV Plans', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),),
                      ),
                    ],
                  ),
                  SizedBox(height: 10,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ...List.generate(5, (index) => SizedBox(
                        width: 60,
                        height: 20,
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
                      )),
                    ],
                  ),
                  SizedBox(height: 10,),
                  Expanded(
                    child: Center(
                      child: GridView.builder(
                          gridDelegate:  SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.7,
                            crossAxisSpacing: 30,
                            mainAxisSpacing: 15,
                            // mainAxisExtent: 120
                          ),
                          itemCount: 12,
                          itemBuilder: (context, index) {
                            return SizedBox(
                              width: 150,
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
                            );
                          }
                      ),
                    ),
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
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Cable Subscription'),
      ),
      body: Form(
        key: _formKey,
        child: Container(
            padding: EdgeInsets.only(left: 12, right: 12, top: 20),
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
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                  dropdownColor: kCardColor,
                  padding: EdgeInsets.only(left: 10, right: 10),
                  iconSize: 25,
                  iconDisabledColor: kButtonColor,
                  iconEnabledColor: kButtonColor,
                  value: _selectedProvider,
                  menuMaxHeight: 200,
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  decoration: const InputDecoration(
                    labelText: 'Providers',

                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'This field is required';
                    }
                    return null;
                  },
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
                      _selectedIndices.clear();
                      _tabController?.dispose();
                      readyToShowName = false;
                      cableNumberIsIncorrect = true;
                      _tabController = TabController(
                          length: _categories[_selectedProvider]!.length,
                          vsync: this,
                          initialIndex: 0
                      );
                    });
                  },
                ),
                SizedBox(height: 20,),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TextFormField(
                      controller: _smartController,
                      cursorColor: Colors.white,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        prefix: _selectedProvider == 'StarTimes ON'
                            || _selectedProvider == 'SHOWMAX' ? Text('+234 | ',
                          style: TextStyle(color: Colors.white, fontSize: 14,
                              fontWeight: FontWeight.w900),) : Text(''),
                        labelText: _selectedProvider == 'StarTimes ON'
                            || _selectedProvider == 'SHOWMAX' ? 'Enter Your Mobile Number'
                            : 'Enter Your Smartcard Number',
                        hintText: '8023344567',

                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'This field is required';
                        }
                        if (cableNumberIsIncorrect) {
                          return 'Incorrect Cable Number';
                        }
                        return null;
                      },
                      onChanged: (value) {

                      },
                    ),
                    SizedBox(height: 10,),
                    GestureDetector(
                      onTap: () {
                        if (_smartController.text.isNotEmpty) {
                          setState(() {
                            customerDetails = validateCable(_smartController.text, _selectedProvider.toLowerCase());
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
                                visible: !cableNumberIsIncorrect,
                                  child:  Padding(
                                    padding: EdgeInsets.only(left: 4),
                                    child: Icon(Icons.check_circle, color: Colors.black, size: 15,),
                                  ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Visibility(
                    visible: readyToShowName,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 15),
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
                                Map verifiedInformation = {
                                  'Merchant Name' : snapshot.data?['name'] ?? 'Name not Found',
                                  'Current Plan' :  '${snapshot.data?['status']} to'
                                      ' ${snapshot.data?['provider']}' ?? 'Address not fount',
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
                                              ...List.generate(2, (index) {
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
                                        ],
                                      ),
                                    ),
                                    Positioned(
                                      right: 2,
                                        top: 2,
                                        child: Icon(Icons.check_circle,
                                          color: Color(0xFF21D3ED),
                                          size: 15,
                                        )
                                    ),
                                  ]
                                );
                              }
                          )
                        ],
                      ),
                    )
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 0),
                  child: Text('TV Plans', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),),
                ),
                _categories[_selectedProvider] == null || myServices[_selectedProvider] == false ?
                  SizedBox() :
                Container(
                  color: Color(0xFF0F172A),
                  padding: EdgeInsets.only(top: 10),
                  child: TabBar(
                    controller: _tabController,
                    tabs: [
                      ...?_categories[_selectedProvider]?.map((x) =>
                          Text(x.category, style: GoogleFonts.raleway())),
                    ],
                    tabAlignment: TabAlignment.start,
                    isScrollable: true,
                    dividerHeight: 0,
                    labelColor: Colors.white,
                    labelStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                    labelPadding: EdgeInsets.only(right: 30, bottom: 5),
                    indicatorColor: Color(0xFF21D3ED),
                    indicator: UnderlineTabIndicator(
                      borderSide: BorderSide(width: 2, color:  Color(0xFF21D3ED)),
                      insets: EdgeInsets.symmetric(horizontal: 0),
                    ),
                  ),
                ),
                _categories[_selectedProvider] == null  || myServices[_selectedProvider] == false ?
                SizedBox(
                  height: 100,
                  child: Center(
                    child: Text('Service Temporarily not available, please try again later!',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
                      textAlign: TextAlign.center,),
                  ),
                ) :
                Expanded(
                  flex: readyToShowName ? 6 : 10,
                  child: TabBarView(
                    key: ValueKey<String>(_selectedProvider),
                    controller: _tabController,
                    children: [
                      ...List.generate(
                          _categories[_selectedProvider]!.length,
                              (index) {
                            return  _buildPlanGrid(
                                _categories[_selectedProvider]![index].tvPlans,
                                index);
                          }
                      )
                    ],
                  ),
                ),
                SizedBox(height: 10,),
                Expanded(
                  flex: 2,
                  child: Padding(
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
                              print(cableNumberIsIncorrect);
                              int tabIndex = _tabController!.index;
                              int? selectedIndex = _selectedIndices[tabIndex];
                              if (_formKey.currentState!.validate()) {
                                if (selectedIndex == null) {
                                  ScaffoldMessenger
                                      .of(context).
                                  showSnackBar(SnackBar(content: Text('Please!, select a plan')));
                                  return;
                                }
                                final plan = _categories[_selectedProvider]?[tabIndex].tvPlans[selectedIndex];

                                double bonus = pov.cablePercent * double.parse(plan!.price);

                                showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    builder: (context) =>
                                        ConfirmationPage(
                                          amount: '${plan?.price}',
                                          bonusEarn: (bonus).toDouble(),
                                          isRecharge: false,
                                          receiptData: {
                                            'Product Name' : '$_selectedProvider Subscription',
                                            'SmartCard Number' : _smartController.text,
                                            'Actual Amount' : '${plan.price} NGN',
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
                                                      .purchaseTV(
                                                      variationCode:  plan.variationCode,
                                                      serviceID: _selectedProvider,
                                                      phoneNumber:  context.read<UserProvider>().user?.phone ?? '',
                                                      cableNumber:  _smartController.text,
                                                      clientRequestId: currentRequestId!,
                                                      humanRef: humanReference,
                                                      isRecharge: false,
                                                      useReward: useReward,
                                                      amount: plan.price,
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
                            child: Text('Buy Now', style: TextStyle(color:  Colors.black,),)
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
        ),
      ),
    );
  }
}
