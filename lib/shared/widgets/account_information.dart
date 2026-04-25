import 'package:everywhere/components/reusable_card.dart';
import 'package:everywhere/features/marketPlace/widgets/shared_widgets.dart';
import 'package:everywhere/providers/user_provider.dart';
import 'package:everywhere/shared/utils/info_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../constraints/constants.dart';
import '../../constraints/vendor_theme.dart';
import '../../services/brain.dart';
import '../utils/flush_bar_message.dart';

class AccountInformation extends StatelessWidget {
  final TextEditingController _preferredBank = TextEditingController();

  String preferredBank = 'Paystack';
  AccountInformation({super.key});

  @override
  Widget build(BuildContext context) {
    final pov = Provider.of<UserProvider>(context);
    final PageController _pageController = PageController(viewportFraction: 0.95);
    if (pov.user == null) {
      return VErrorState(message: 'No User found', onRetry: () {});
    }
    if (pov.user!.virtualAccounts.isEmpty) {
      Map<String, dynamic> banks = {
        'Wema Bank': 'wema-bank',
        'Paystack': 'titan-paystack'
      };
      return Padding(
          padding: EdgeInsets.only(left: 12, right: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const InfoBox(text: 'You Currently do not have any active account, generate it now'),
            const SizedBox(height: 10,),
            Text(textAlign: TextAlign.right,
              'Select a bank',  style: TextStyle(color: VendorTheme.textMuted),),
            const SizedBox(height: 10,),
            Flexible(
              child: VDropdown(
                value: preferredBank,
                items: banks.keys.map((bank) => DropdownMenuItem(value: bank, child: Text(bank))).toList() ,
                onChanged: (value) {

                  pov.setPreferredBank(banks[value]);
                  print(value);
                },
                label: 'Preferred Bank',
              ),
            ),
            const SizedBox(height: 10,),
            VButton(label: 'Generate Now!', onTap: () async {

              showDialog(context: context, builder: (_) =>
                  Center(
                    child: CircularProgressIndicator(
                      value: 20,
                      backgroundColor: kCardColor,
                      color: kButtonColor,
                    ),
                  ));

              try {
                final ok = await pov.generateVirtualAccount();
                await pov.loadUser();
                Navigator.pop(context);
              if (ok) {
                FlushBarMessage.showFlushBar(context: context, message: "Successfully Generated");
              }}
              catch(e) {
                Navigator.pop(context);

                FlushBarMessage.showFlushBar(
                    context: context, message: e.toString(),
                  icon: Icon(Icons.error_outline,
                    color: kErrorIconColor, size: 30,),
                );

              }
              // if (context.mounted) {

              // }
            })
          ],
        ),
      );
    }
    return  Column(
      children: [
        Container(
          alignment: Alignment.topRight,
          padding: EdgeInsets.only(right: 20),
          child: SmoothPageIndicator(
            controller: _pageController,
            count: 3,
            effect: ExpandingDotsEffect(
              dotColor: Colors.grey,
              activeDotColor: Colors.white,
              dotHeight: 6,
              dotWidth: 6,
            ),
          ),
        ),
        ReusableCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Account Name', style:
                        TextStyle(fontFamily: 'DejaVu Sans', fontSize: 11,
                            color: Colors.white70),),
                        Text(pov.user!.name.split('/').sublist(1,2).join(' '),
                          style: TextStyle(fontFamily: 'DejaVu Sans', fontSize: 12,
                              fontWeight: FontWeight.w900),),
                        SizedBox(height: 35,),
                        Text('Account Number', style: TextStyle(fontFamily: 'DejaVu Sans', fontSize: 11, color: Colors.white70),),
                        Row(
                          children: [
                            Text(pov.user!.virtualAccounts.first.accountNumber,
                              style: TextStyle(fontFamily: 'DejaVu Sans',
                                  fontSize: 12, fontWeight: FontWeight.w900),),
                            SizedBox(width: 7,),
                            GestureDetector(
                                onTap: () {
                                  Clipboard.setData(
                                      ClipboardData(text: pov.user!.virtualAccounts.first.accountNumber));
                                  FlushBarMessage
                                      .showFlushBar(
                                      context: context,
                                      message: 'Copied Successfully!'
                                  );
                                },
                                child: Icon(Icons.copy_sharp, size: 15, color: kIconColor,)
                            ),
                            SizedBox(width: 7,),
                            GestureDetector(
                                onTap: () async {
                                  try {
                                    await SharePlus.instance.share(
                                      ShareParams(
                                          subject: 'NexPay Account Details',
                                          title: 'NexPay Account Details',
                                          text: 'Account Name: ${pov.user!.name} \n\n Account Number: ${pov.user!.virtualAccounts.first.accountNumber} \n\n'
                                              ' Bank Name: ${pov.user!.virtualAccounts.first.bankName}'
                                      ),
                                    );

                                  } catch (e) {
                                    print("Error generating image: $e");
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Something went wrong. Try again!')),
                                    );
                                  }
                                },
                                child: Icon(Icons.share_rounded, size: 15, color: kIconColor,)
                            )
                          ],
                        ),
                        SizedBox(height: 35,),
                        Text('Wallet Funding Fees', style:
                        TextStyle(fontFamily: 'DejaVu Sans', fontSize: 11,
                            color: Colors.white70),),
                        Text('${kNaira}${20}',
                          style: TextStyle(fontFamily: 'DejaVu Sans', fontSize: 12,
                              fontWeight: FontWeight.w900),),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bank Name', style: TextStyle(fontFamily: 'DejaVu Sans', fontSize: 11, color: Colors.white70),),
                        Text(pov.user!.virtualAccounts.first.bankName, style: TextStyle(fontFamily: 'DejaVu Sans', fontSize: 12, fontWeight: FontWeight.w900),),
                        SizedBox(height: 35,),
                        Text('Status', style: TextStyle(fontFamily: 'DejaVu Sans', fontSize: 11, color: Colors.white70),),
                        Text(pov.user!.virtualAccounts.first.status.toString().replaceAll('a', 'A'),
                          style: TextStyle(fontFamily: 'DejaVu Sans',
                              fontSize: 12, fontWeight: FontWeight.w900),),
                        SizedBox(height: 35,),
                        Text('Other Fees', style:
                        TextStyle(fontFamily: 'DejaVu Sans', fontSize: 11,
                            color: Colors.white70),),
                        Text('None',
                          style: TextStyle(fontFamily: 'DejaVu Sans', fontSize: 12,
                              fontWeight: FontWeight.w900),),
                      ],
                    )
                  ],
                ),

              ],
            )),
      ],
    );
  }
}
