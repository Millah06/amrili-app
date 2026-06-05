import 'package:everywhere/services/transaction_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../shared/widgets/confirmation_page.dart';
import '../../../../components/formatters.dart';
import '../../../../components/notice_banner.dart';
import '../../../../constraints/constants.dart';
import '../../../../constraints/firebase_constant.dart';
import '../../../../features/utility/models/plan_model.dart';
import '../../../../services/brain.dart';
import '../../../../services/purchase_service.dart';
import '../../services/utility_purchase.dart';

class DataScreen extends StatefulWidget {
  const DataScreen({super.key});

  @override
  State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> with TickerProviderStateMixin {

  TabController ? _tabController;

  Map<String, List<CategoryData>> _categories = {};
  bool isLoading = true;
  String _selectedNetwork = 'MTN';

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

  final TextEditingController _phoneController = TextEditingController();

  // List networks = ['MTN', 'Airtel', 'Glo', '9Mobile'];
  String?  message;
  final _formKey = GlobalKey<FormState>();

  Future<Map<String, List<CategoryData>>> fetchCategories() async {
    final ref = FirebaseDatabase.instanceFor( app: Firebase.app(),
        databaseURL: "https://everywhere-9278c-default-rtdb.europe-west1.firebasedatabase.app/"
    ).ref('dataPlans');
    final snapshot = await ref.get();

    if (!snapshot.exists) throw Exception('No data found');

    final Map<String, dynamic> data = Map<String, dynamic>.from(snapshot.value as Map);

    final Map<String, List<CategoryData>> result = {};

    data.forEach((networkKey, categoryListRaw) {
      final List<dynamic> categoryList = List<dynamic>.from(categoryListRaw);

      final List<CategoryData> categoryDataList = categoryList.map((categoryRaw) {
        final Map<String, dynamic> categoryMap = Map<String, dynamic>.from(categoryRaw);
        return CategoryData.fromMap(categoryMap);
      }).toList();

      result[networkKey] = categoryDataList;
    });

    return result;
  }

  Widget _buildPlanGrid(List<Plan> plans, int tabIndex) {
    int ? selectedIndex = _selectedIndices[tabIndex];
    final pov = Provider.of<Brain>(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: 15, left: 0, right: 0),
      child: GridView.builder(
          gridDelegate:  SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
            childAspectRatio: 0.7,
            crossAxisSpacing: 20,
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
                            Text(plan.quantity,
                              style: TextStyle(color: Colors.white,  fontSize: 12,
                                  fontWeight: FontWeight.w900, ), textAlign: TextAlign.center,),
                            SizedBox(height: 4,),
                            Text(plan.duration, style: TextStyle(color: Colors.white54),),
                            SizedBox(height: 6,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('₦',  style: TextStyle(color: Colors.white54,
                                    fontWeight: FontWeight.w700, fontSize: 13)),
                                SizedBox(width: 3,),
                                Text(kFormatterNo.format(double.parse(plan.price.split('.').first)),
                                  style: GoogleFonts.poppins(color: Colors.white,
                                      fontWeight: FontWeight.w600, fontSize: 17),),
                              ],
                            ),
                            if (plan.social != '' && plan.social.isNotEmpty)
                              Container(
                                color: Colors.black,
                                child: Text(textAlign: TextAlign.center,
                                  plan.social, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900),),
                              )
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
                          child: Center(child:Text('$kNaira${(double.parse(plan.price) * pov.dataPercent).toStringAsFixed(2)} cashback',
                            style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w700),)),
                        )
                      ],
                    ),
                  ),
                  if (isSelected)
                    Positioned(
                        top: 2,
                        right: 2,
                      child: Icon(Icons.check_circle, size: 15 , color: kIconColor,)
                  )
                ],
              ),
            );
          }
      ),
    );
  }

  String? currentRequestId;

  @override
  Widget build(BuildContext context) {

    final pov = Provider.of<Brain>(context);

    Map<String, bool> myServices = pov.dataProviders;



    List<String> networks = myServices.keys.toList();

    bool oneServiceIsDown = myServices.containsValue(false);

    if (oneServiceIsDown) {
      final unavailable = MyFormatManager.getUnavailableServices(myServices);
      message = MyFormatManager.formatUnavailable(unavailable, 'data');
    }

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Mobile Data Purchase'),
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
                        },
                      ),
                      SizedBox(height: 20,),
                      TextFormField(
                        cursorColor: Colors.white,

                        keyboardType: TextInputType.phone,
                        controller: _phoneController,
                        maxLength: 10,
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          prefix: Text('+234 | ',
                            style: TextStyle(color: Colors.white, fontSize: 16,
                                fontWeight: FontWeight.w900),),
                          hintText: '8023344567',

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


    return Scaffold(
      appBar: AppBar(
        title: Text('Mobile Data Purchase'),
      ),
      body: Form(
        key: _formKey,
        child: Container(
            padding: EdgeInsets.only(left: 12, right: 12, top: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Visibility(
                  visible: oneServiceIsDown,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: NoticeBanner(noticeMessage: message ?? 'none',),
                  ),
                ),
                DropdownButtonFormField<String>(

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
                    setState(() {
                      _selectedNetwork = val!;
                      _selectedIndices.clear();
                      _tabController?.dispose();
                      _tabController = TabController(
                          length: _categories[_selectedNetwork]?.length ?? 0,
                          vsync: this,
                          initialIndex: 0
                      );
                    });

                  },
                ),
                SizedBox(height: 20,),
                TextFormField(
                  cursorColor: Colors.white,

                  keyboardType: TextInputType.phone,
                  controller: _phoneController,
                  maxLength: 10,
                  decoration: InputDecoration(
                      labelText: 'Phone Number',
                      prefix: Text('+234 | ',
                        style: TextStyle(color: Colors.white, fontSize: 14,
                            fontWeight: FontWeight.w900),),
                      hintText: '8023344567',

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
                _categories[_selectedNetwork] == null || oneServiceIsDown ?
                    SizedBox() :
                Container(
                  color: Color(0xFF0F172A),
                  padding: EdgeInsets.only(top: 10),
                  child: TabBar(
                    controller: _tabController,
                    tabs: [
                       ...?_categories[_selectedNetwork]?.map((x) => Text(x.category, style: GoogleFonts.raleway(),)),
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
                _categories[_selectedNetwork] == null || oneServiceIsDown ?
                SizedBox(
                  height: 100,
                  child: Center(
                    child: Text('Service Temporarily not available, please try again later!',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
                      textAlign: TextAlign.center,),
                  ),
                ) :
                Expanded(
                  child: TabBarView(
                    key: ValueKey<String>(_selectedNetwork),
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
                              double bonus = pov.dataPercent * double.parse(plan!.price);
                              final ok = await UtilityPurchase.buy(
                                context,
                                amount: double.parse(plan.price),
                                productName: '$_selectedNetwork ${plan.quantity}',
                                service: 'data',
                                serviceID: _selectedNetwork.toLowerCase(),
                                phone: '0${_phoneController.text}',
                                variationCode: plan.variationCode,
                                useReward: true,
                                isRecharge: false,
                              );
                              // if (ok) _resetForm();
                            }
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
}
