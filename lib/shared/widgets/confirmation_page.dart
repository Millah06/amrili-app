import 'package:dotted_border/dotted_border.dart';
import 'package:everywhere/components/dash_line.dart';
import 'package:everywhere/components/reusable_card.dart';
import 'package:everywhere/components/swicht.dart';
import 'package:everywhere/components/wallet_balance.dart';
import 'package:everywhere/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../constraints/constants.dart';
import '../../services/brain.dart';
import 'account_information.dart';
import '../utils/flush_bar_message.dart';



class ConfirmationPage extends StatefulWidget {

  final String amount;
  final double bonusEarn;
  final Function(double, double, bool) onTap;
  final Map<String, dynamic> receiptData;
  final bool isRecharge;
  const ConfirmationPage({super.key,
    required this.amount,
    required this.onTap,
    required this.receiptData,
    required this.isRecharge,
    required this.bonusEarn});



  @override
  State<ConfirmationPage> createState() => _ConfirmationPageState();
}

class _ConfirmationPageState extends State<ConfirmationPage> {

  bool rewardIsToggle = false;
  double finalAmount = 0;
  double updatedReward = 0;
  Color buttonColor = kButtonColor;
  Color textColor = Colors.black;

  @override
  Widget build(BuildContext context) {

    final pov = Provider.of<UserProvider>(context, listen: false).user;

    double productAmount =  double.parse(widget.amount);

    double actualReward =  pov!.wallet.fiat.rewardBalance;

    final formatter = NumberFormat('#,##0.00');

    if (rewardIsToggle) {
      if (widget.isRecharge) {
        if (productAmount > actualReward) {
          finalAmount = productAmount - actualReward - widget.bonusEarn;
          updatedReward = 0;
        }
        // having issue
        else {
          finalAmount = 0;
          updatedReward = actualReward - (productAmount - widget.bonusEarn);
        }
      }
      else {
        if (productAmount > actualReward) {
          finalAmount = productAmount - actualReward;
          updatedReward = 0 + widget.bonusEarn;
        }
        else {
          finalAmount = 0;
          updatedReward = (actualReward - productAmount) + widget.bonusEarn;
        }
      }
    }

    else {
      if (widget.isRecharge) {
        finalAmount = productAmount - widget.bonusEarn;
        updatedReward = actualReward;
      }

      else {
        finalAmount = productAmount;
        updatedReward = actualReward + widget.bonusEarn;
      }
    }

    bool inSufficientFunds = finalAmount > pov.wallet.fiat.availableBalance;

    if (inSufficientFunds) {
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

    final formatted = formatter.format(productAmount); // e.g. "2,000.45"
    final parts = formatted.split('.'); // ["2,000", "45"]

    final formattedFinal = formatter.format(finalAmount); // e.g. "2,000.45"
    final partsFinal = formattedFinal.split('.');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 15, right: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 50,
                height: 40,
                decoration: BoxDecoration(

                ),
                child: Image.asset('images/receipt2.png', width: 50, height: 40,),
              ),
              Text('Pay Securely', style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'DejaVu Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.bold
              ),),

            ],
          ),
        ),
        Center(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text.rich(
                    TextSpan(
                    style: TextStyle(
                        decoration:  widget.isRecharge || rewardIsToggle ?
                        TextDecoration.lineThrough : TextDecoration.none,
                      decorationColor: Colors.white,
                      decorationThickness: 2,
                      color: widget.isRecharge || rewardIsToggle ? Colors.grey : Colors.white
                    ),
                    children: [
                      TextSpan(
                        text: kNaira,
                        style: TextStyle(
                            fontSize: widget.isRecharge || rewardIsToggle ? 9 : 15, // smaller decimal part
                            fontWeight: FontWeight.w900
                        ),
                      ),
                      TextSpan(
                        text: parts[0],
                        style: TextStyle(
                          fontSize: widget.isRecharge || rewardIsToggle ? 18 : 30,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'DejaVu Sans',
                        ),
                      ),
                      TextSpan(
                        text: '.${parts[1]}',
                        style: TextStyle(
                            fontSize: widget.isRecharge || rewardIsToggle ? 9 : 12, // smaller decimal part
                            color: Colors.white54,
                            fontWeight: FontWeight.w900
                        ),
                      ),
                    ],
                  ),)
                ],
              ),
              Visibility(
                visible: widget.isRecharge || rewardIsToggle,
                child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('Pay', style: GoogleFonts.raleway(fontSize: 14,
                      fontWeight: FontWeight.bold, color: Colors.white),),
                  SizedBox(width: 5,),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: kNaira,
                          style: TextStyle(
                              fontSize: 15, // smaller decimal part
                              color: Colors.white,
                              fontWeight: FontWeight.w900
                          ),
                        ),
                        TextSpan(
                          text: partsFinal[0],
                          style: TextStyle(
                            fontSize: 30, // big integer part
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'DejaVu Sans',
                          ),
                        ),
                        TextSpan(
                          text: '.${partsFinal[1]}',
                          style: TextStyle(
                              fontSize: 12, // smaller decimal part
                              color: Colors.white54,
                              fontWeight: FontWeight.w900
                          ),
                        ),
                      ],
                    ),)
                ],
              ),)
            ],
          ),
        ),
        SizedBox(height: 10,),
        Padding(
          padding: const EdgeInsets.only(left: 15, right: 15),
          child: Column(
            children: [
              ...List.generate(widget.receiptData.length, (index)
              {
                String key = widget.receiptData.keys.toList()[index];
                dynamic value = widget.receiptData.values.toList()[index];
                if (key == 'Status' || key == 'Date'
                    || key == 'pins' ||
                    key == 'waec_registration-tokens' || key == 'waec_result_cards') {
                  return SizedBox();
                }
                return Column(
                  children: [
                    key == 'Bonus to Earn' || key == 'Token' ?
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(key,
                          style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.bold
                          ),),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('+ $value',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: kIconColor
                              ),),
                            SizedBox(width: 5,),
                            GestureDetector(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: value));
                                FlushBarMessage
                                    .showFlushBar(
                                    context: context,
                                    message: 'Token Copied Successfully!'
                                );
                              },
                              child: Icon(Icons.gpp_good, size: 15, color: kIconColor,),
                            )
                          ],
                        ),
                      ],
                    ) :
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(key,
                          style:GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: Colors.white70
                          ),),
                        SizedBox(width: 25,),
                        Flexible(
                          child: Text(softWrap: false, value,
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold
                            ),),
                        ),
                      ],
                    ),
                    SizedBox(height: 10,),

                  ],
                );
              }
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Top From Bonus ($kNaira${kFormatter.format(pov.wallet.fiat.rewardBalance)}) ', style: kConfirmationKey,),

                  TinySwitch(
                      value: rewardIsToggle,
                      activeColor: kButtonColor,
                      inactiveColor: Colors.grey,
                      onChanged: (newValue) {
                        setState(() {
                          rewardIsToggle = newValue;
                        });
                      }
                  )
                ],
              )
            ],
          ),
        ),
        SizedBox(height: 10,),
        Padding(
          padding: const EdgeInsets.only(left: 15, right: 15, bottom: 15),
          child: DashedLine(),
        ),
        Container(
          margin: EdgeInsets.only(left: 12, right: 12, bottom: 10, top: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Color(0xFF1E293B),
          ),
          child: DottedBorder(
            options: RoundedRectDottedBorderOptions(
                radius: Radius.circular(10),
                padding: EdgeInsets.only(bottom: 10, left: 15, right: 15, top: 10),
                color: Colors.transparent,
              dashPattern: [1, 1]
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.shield_moon_outlined, size: 18, color: kIconColor,),
                        SizedBox(width: 2,),
                        Text('Available Balance ($kNaira${kFormatterNo.format(pov.wallet.fiat.availableBalance)})',
                          style: kSetting.copyWith(fontWeight: FontWeight.w700, color: Colors.white70, fontSize: 14),),
                      ],
                    ),
                    Icon(Icons.check_circle, color: kIconColor, size: 18,)
                  ],
                ),
                SizedBox(height: 10,),
                DashedLine(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.account_balance_rounded, size: 12, color: kIconColor,),
                        SizedBox(width: 5,),
                        Text('Account Balance After Transaction',
                          style: GoogleFonts.raleway(fontWeight: FontWeight.w700, fontSize: 10),),
                      ],
                    ),
                    inSufficientFunds ? Text('Insufficient Funds', style: TextStyle(fontSize: 12,
                        color: Colors.white, fontWeight: FontWeight.bold), ) : Row(
                      children: [
                        Text(kNaira,
                          style: TextStyle(fontSize: 12,
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 3,),
                        BalanceText(pov.wallet.fiat.availableBalance - finalAmount, 16, 10)
                      ],
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.card_giftcard, size: 12, color: kIconColor,),
                        SizedBox(width: 5,),
                        Text('Reward Balance After Transaction',
                          style: GoogleFonts.raleway(fontWeight: FontWeight.w700, fontSize: 10 ),),
                      ],
                    ),
                    Row(
                      children: [
                        Text(kNaira, style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),),
                        SizedBox(width: 3,),
                        BalanceText(updatedReward, 16, 10)
                      ],
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
        SizedBox(height: 15,),
        Padding(
          padding: const EdgeInsets.only(bottom: 15.0),
          child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  elevation: 4,
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 120),
                side: BorderSide.none
              ),

              onPressed: () {
                inSufficientFunds ? showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    icon: Icon(Icons.warning_sharp, color: kErrorIconColor,),
                    actionsPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                    title: Text("Oops!! You're running out of funds", style: kAlertTitle,
                      textAlign: TextAlign.center,),
                    backgroundColor: kCardColor,
                    // shape:
                    // RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    content: Padding(
                      padding: EdgeInsets.all(10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Fund your wallet to proceed with the transaction or cancel', style: kAlertContent),
                          SizedBox(height: 10),
                        ],
                      ),
                    ),
                    actions: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                elevation: 4,
                                padding: EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 20),
                                side: BorderSide(
                                    color: kButtonColor
                                ),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)
                                ),
                              ),
                              onPressed: ()  async {
                                Navigator.pop(context);
                              },
                              child: Row(
                                children: [
                                  Icon(Icons.cancel, color: Colors.white,),
                                  SizedBox(width: 5,),
                                  Text('Leave', style: TextStyle(color: Colors.white),),
                                ],
                              )
                          ),
                          // SizedBox(width: 10,),
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kButtonColor,
                                elevation: 4,
                                padding: EdgeInsets.symmetric(vertical:
                                10, horizontal: 20),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)
                                ),
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                showModalBottomSheet(
                                  context: context, builder: (context) => FractionallySizedBox(
                                  heightFactor: 0.4,
                                  child: AccountInformation(),
                                ),
                                  isScrollControlled: true,
                                  showDragHandle: true,
                                  // backgroundColor: Color(0xFF333333),
                                );
                              },
                              child: Row(
                                children: [
                                  FaIcon(
                                    FontAwesomeIcons.plusCircle,
                                    color: Colors.black,
                                  ),
                                  SizedBox(width: 5,),
                                  Text('Add now', style: TextStyle(color: Colors.black),),
                                ],
                              )
                          ),

                        ],
                      )
                    ],
                  ),
                )
                    : widget.onTap(finalAmount, updatedReward, rewardIsToggle);
              },
              child: Text('Buy Now', style: TextStyle(color: textColor),)
          ),
        ),
      ],
    );
  }
}


