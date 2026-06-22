import 'package:another_flushbar/flushbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:everywhere/features/utility/models/internet_services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../providers/user_provider.dart';
import '../../../../shared/widgets/confirmation_page.dart';
import '../../../../../components/order_frame.dart';
import '../../../../../components/transaction_pin.dart';
import '../../../../../constraints/constants.dart';
import '../../../../../features/utility/models/plan_model.dart';
import '../../../../../services/brain.dart';
import '../../../../services/purchase_service.dart';
import '../../../../services/transaction_service.dart';
import '../../services/utility_purchase.dart';

enum ViewMode {  email, accountID, standardValue }

class InternetServicesScreen extends StatefulWidget {
  const InternetServicesScreen({super.key});


  @override
  State<InternetServicesScreen> createState() => _InternetServicesScreenState();
}

class _InternetServicesScreenState extends State<InternetServicesScreen> with TickerProviderStateMixin {

  TabController ? _tabController;

  Map<String, List<InternetCategoryData>> _categories = {};
  bool isLoading = true;
  bool readyToShowName = false;
  String _selectedNetwork = 'Smile Network';

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
          length: _categories[_selectedNetwork]!.length, vsync: this);
      isLoading = false;
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _tabController?.dispose();
    super.dispose();
  }

  final TextEditingController _idController = TextEditingController();

  List networks = ['Smile Network', 'Spectra Net'];
  final _formKey = GlobalKey<FormState>();
  Future<Map<String, dynamic>?>? customerDetails;
  String accountID = '';

  Future<Map<String, List<InternetCategoryData>>> fetchCategories() async {
    final ref = FirebaseDatabase.instanceFor( app: Firebase.app(),
        databaseURL: "https://everywhere-9278c-default-rtdb.europe-west1.firebasedatabase.app/"
    ).ref('internetServices');
    final snapshot = await ref.get();

    if (!snapshot.exists) throw Exception('No data found');

    final Map<String, dynamic> data = Map<String, dynamic>.from(snapshot.value as Map);

    final Map<String, List<InternetCategoryData>> result = {};

    data.forEach((networkKey, categoryListRaw) {
      final List<dynamic> categoryList = List<dynamic>.from(categoryListRaw);

      final List<InternetCategoryData> categoryDataList = categoryList.map((categoryRaw) {
        final Map<String, dynamic> categoryMap = Map<String, dynamic>.from(categoryRaw);
        return InternetCategoryData.fromMap(categoryMap);
      }).toList();

      result[networkKey] = categoryDataList;
    });

    return result;
  }

  ViewMode _mode = ViewMode.accountID;

  Widget _buildPlanGrid(List<InternetPlan> plans, int tabIndex) {
    int ? selectedIndex = _selectedIndices[tabIndex];
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: 15, left: 0, right: 0),
      child: GridView.builder(
          gridDelegate:  SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.7,
            crossAxisSpacing: 30,
            mainAxisSpacing: 15,
            // mainAxisExtent: 120
          ),
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
                            color: isSelected ? kButtonColor : kCardColor, width: 2)
                    ),
                    padding: EdgeInsets.only(left: 0, right: 0, top: 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(plan.description,
                              style: TextStyle(color: Colors.white,
                                  fontSize: 12, fontWeight: FontWeight.w900), textAlign: TextAlign.center,),
                            SizedBox(height: 4,),
                            Text(plan.duration, style: TextStyle(color: Colors.white54),),
                            SizedBox(height: 6,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('₦',  style: TextStyle(color: Colors.white54,
                                    fontWeight: FontWeight.w700, fontSize: 13)),
                                SizedBox(width: 3,),
                                Text(plan.price.split('.').first,
                                  style: TextStyle(color: Colors.white,
                                      fontWeight: FontWeight.w700, fontSize: 18),),
                              ],
                            ),
                          ],
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
                            child: Center(child: Text('$kNaira${double.parse(plan.price) * 0.01} cashback',
                              style: TextStyle(color: Colors.black, fontSize: 10,
                                  fontWeight: FontWeight.w700), textAlign: TextAlign.center,)),
                          )
                      ],
                    ),
                  ),
                  if (isSelected)
                    Positioned(
                        top: 2,
                        right: 2,
                        child: Icon(Icons.check_circle, size: 15, color: kIconColor,)
                    )
                ],
              ),
            );
          }
      ),
    );
  }

  bool cableNumberIsIncorrect = true;

  Color buttonColor = kButtonColor;
  Color textColor = Colors.black;

  final TextEditingController _emailController = TextEditingController();
  TextEditingController _accountController = TextEditingController();


  @override
  Widget build(BuildContext context) {

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Internet Services'),
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
                        value: _selectedNetwork,
                        menuMaxHeight: 200,
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                        decoration: const InputDecoration(
                          labelText: 'Network',
                          labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'This field is required';
                          }
                          return null;
                        },
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
                        cursorColor: Colors.white,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        keyboardType: TextInputType.phone,
                        controller: _idController,
                        maxLength: 10,
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          prefix: Text('+234 | ',
                            style: TextStyle(color: Colors.white, fontSize: 16,
                                fontWeight: FontWeight.w900),),
                          hintText: '8023344567',
                          labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'This field is required';
                          }
                          if (value.startsWith('0', 0)) {
                            return 'Phone number can\'n start with zero';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20,),
                      Padding(
                        padding: const EdgeInsets.only(left: 0),
                        child: Text('Data Plans', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),),
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
    final pov = Provider.of<Brain>(context);

    Future<Map<String, dynamic>> validateSmileNetwork(String email) async {
      final result = await PurchaseItems(context: context).verifySmile(email);
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
      _formKey.currentState?.validate();

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

    return Scaffold(
      appBar: AppBar(
        title: Text('Internet Services'),
      ),
      body: Form(
        key: _formKey,
        child: Container(
            padding: EdgeInsets.only(left: 15, right: 15, top: 30),
            child: SingleChildScrollView(
              clipBehavior: Clip.none,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
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
                      labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'This field is required';
                      }
                      return null;
                    },
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
                  SizedBox(height: 10,),
                  _mode == ViewMode.accountID ?
                  TextFormField(
                    cursorColor: Colors.white,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    keyboardType: TextInputType.number,
                    controller: _idController,
                    decoration: InputDecoration(
                      labelText: 'Account ID',
                      hintText: '3245902891',
                      labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'This field is required';
                      }
                      return null;
                    },
                    onChanged: (value) async {

                    },
                  ) :  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      TextFormField(
                        controller: _emailController,
                        cursorColor: Colors.white,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Registered Email',
                          hintText: 'johnny@gmail.com',
                          labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),

                        ),
                        onChanged: (value) {

                        },
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'This field is required';
                          }
                          if (cableNumberIsIncorrect) {
                            return 'Incorrect Cable Number';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 10,),
                      GestureDetector(
                        onTap: () {
                          if (_emailController.text.isNotEmpty) {
                            setState(() {
                              customerDetails = validateSmileNetwork(
                                _emailController.text,
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
                                  visible: !cableNumberIsIncorrect,
                                  child:  Icon(Icons.check_circle, color: Colors.black, size: 15,),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // SizedBox(height: 15,),
                  Visibility(
                      visible: readyToShowName,
                      child: Padding(
                        padding: EdgeInsets.only(top: 10, bottom: 15),
                        child: Column(
                          children: [
                            FutureBuilder<Map<String, dynamic>?>(
                                future: customerDetails,
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
                                  _idController.text = snapshot.data?['accountID'];
                                  return Stack(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.only(left: 10, right: 15, top: 10, bottom: 10),
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
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text('Name', style: GoogleFonts.raleway(fontSize: 11),),
                                                      Text('Account ID', style: GoogleFonts.raleway(fontSize: 11),),
                                                      Text('Number of Accounts', style: GoogleFonts.raleway(fontSize: 11),)
                                                    ],
                                                  ),
                                                  SizedBox(width: 10,),
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(snapshot.data?['name'] ?? 'No named found',
                                                        style:
                                                        GoogleFonts.inter(fontWeight: FontWeight.w600,
                                                            fontSize: 12),),
                                                      Text('${snapshot.data?['accountID']}' ?? 'No ID',
                                                        style:
                                                        GoogleFonts.inter(fontWeight: FontWeight.w600,
                                                            fontSize: 12),),
                                                      Text(snapshot.data?['numberOfAccounts'] ?? 'Not provided', style:
                                                      GoogleFonts.inter(fontWeight: FontWeight.w600,
                                                          fontSize: 12),)
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Positioned(
                                            right: 2,
                                            top: 2,
                                            child: Icon(Icons.check_circle,
                                              color: Color(0xFF21D3ED), size: 15,)
                                        ),
                                      ]
                                  );
                                }
                            )
                          ],
                        ),
                      )
                  ),
                  SizedBox(height: 10,),
                  Padding(
                    padding: const EdgeInsets.only(left: 0),
                    child: Text('Internet Plans', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),),
                  ),
                  _categories[_selectedNetwork] == null ?
                   SizedBox() :
                  Container(
                    color: Color(0xFF0F172A),
                    padding: EdgeInsets.only(top: 10),
                    child: TabBar(
                      controller: _tabController,
                      tabs: [
                        ...?_categories[_selectedNetwork]?.map((x) => Text(x.category, style: GoogleFonts.raleway())),
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
                  _categories[_selectedNetwork] == null ?
                  SizedBox(
                    height: 100,
                    child: Center(
                      child: Text('Service Temporarily not available, please try again later!',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
                        textAlign: TextAlign.center,),
                    ),
                  ) :
                  SizedBox(
                    height: 300, // or MediaQuery.of(context).size.height * 0.5
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        ...List.generate(
                            _categories[_selectedNetwork]!.length,
                                (index) {
                              return  _buildPlanGrid(
                                  _categories[_selectedNetwork]![index].plans, index);
                            }
                        )
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
                              int tabIndex = _tabController!.index;
                              int? selectedIndex = _selectedIndices[tabIndex];
                              if (_formKey.currentState!.validate()) {
                                if (selectedIndex == null) {
                                  ScaffoldMessenger
                                      .of(context).
                                  showSnackBar(SnackBar(content: Text('Please!, select a plan')));
                                  return;
                                }
                                final plan = _categories[_selectedNetwork]?[tabIndex].plans[selectedIndex];

                                double bonus = pov.internetPercent * double.parse(plan!.price);

                                final ok = await UtilityPurchase.buy(
                                  context,
                                  amount: double.parse(plan.price),
                                  productName:'$_selectedNetwork Data',
                                  service: 'smile',
                                  serviceID: 'smile-direct',
                                  phone: '080197894930',
                                  billersCode: _idController.text,
                                  variationCode: plan.variationCode,
                                  // useReward: _useReward,
                                );
                                // if (ok) _resetForm();

                                // showModalBottomSheet(
                                //     context: context,
                                //     isScrollControlled: true,
                                //     builder: (context) =>
                                //         ConfirmationPage(
                                //           isRecharge: true,
                                //           amount: plan.price,
                                //           bonusEarn: (bonus).toDouble(),
                                //           receiptData: {
                                //             'Product Name' : '$_selectedNetwork Data',
                                //             'Actual Amount' : '${plan.price} NGN',
                                //             'Plan' : '${plan.description} ${plan.duration}',
                                //             'Account ID': _idController.text,
                                //             'Bonus to Earn' : '$kNaira${(bonus).toStringAsFixed(2) }'
                                //           },
                                //           onTap: (amount, reward, useReward) {
                                //             TransactionService.handlePurchase(
                                //               context: context,
                                //               purchaseFunction: () async {
                                //                 try {
                                //                   final res = await
                                //                   PurchaseItems(context: context).purchaseSmile(
                                //                     _selectedNetwork,
                                //                       plan.variationCode,
                                //                       context.read<UserProvider>().user?.phone ?? ''
                                //                   );
                                //                   return res;
                                //                 }
                                //                 catch (e) {
                                //                   rethrow;
                                //                 }
                                //               },
                                //             );
                                //           },
                                //         )
                                // );
                              }
                            },
                            child: Text('Buy Now', style: TextStyle(color: Colors.black),)
                        ),
                      ],
                    ),
                  ),
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
          ViewMode.accountID: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),

            ),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 6, horizontal: 6),
              child: Text('Account ID', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),),
            ),
          ),
          ViewMode.email: Padding(
            padding: EdgeInsets.symmetric(vertical: 6, horizontal: 6),
            child: Text('Email', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),),
          ),
        },
        onValueChanged: (v) => setState(() => _mode = v),
      ),
    );
  }

}
