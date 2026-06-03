import 'dart:io';

import 'package:another_flushbar/flushbar.dart';
import 'package:everywhere/components/bootom_bar.dart';
import 'package:everywhere/shared/utils/flush_bar_message.dart';
import 'package:everywhere/constraints/constants.dart';
import 'package:everywhere/screens/welcome_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../components/pin_entry.dart';
import '../../models/notification_model.dart';
import '../../services/brain.dart';
import '../../services/session_service.dart';
import 'login_screen.dart';

class PasscodeScreen extends StatefulWidget {
  const PasscodeScreen({super.key});

  @override
  State<PasscodeScreen> createState() => _PasscodeScreenState();
}

class _PasscodeScreenState extends State<PasscodeScreen> {

  bool obscureText = true;

  void _auth(Future<bool> canAuth) async {
    final LocalAuthentication auth = LocalAuthentication();
    if (await canAuth) {
      final result = await auth.authenticate(
          localizedReason: 'Use Fingerprint to login',
          options: const AuthenticationOptions(biometricOnly: true)
      );
      result ? Navigator.pushAndRemoveUntil(
        context, MaterialPageRoute(builder: (_) => BottomBar()),
            (route) => false) :
      FlushBarMessage.showFlushBar(
        context: context,
        message: 'Your device does\'nt support this method, use passcode instead.',
        title: 'Ops',
        icon: Icon(Icons.error_outline,
          color: kErrorIconColor, size: 30,),
      );
    }
    else {
      FlushBarMessage.showFlushBar(
        context: context,
        message: 'Your device does\'nt support this method, use passcode instead.',
        title: 'Ops',
        icon: Icon(Icons.error_outline,
          color: kErrorIconColor, size: 30,),
      );
    }
  }

  final TextEditingController _controller = TextEditingController();
  String textDigit = '';

  Color buttonColor = Color(0x3321DEED);
  Color textColor = Colors.white60;

  @override
  Widget build(BuildContext context) {
    final pov = Provider.of<Brain>(context);
    return Scaffold(
      body: Container(
        padding: EdgeInsets.only(top: 50, bottom: 0, left: 0, right: 0),
        height: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: EdgeInsets.only(right: 15),
              child: GestureDetector(
                onTap: () async {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      icon: Icon(Icons.logout_sharp, color: kErrorIconColor,),
                      actionsPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                      title: Text('Switch Account Confirmation', style: kAlertTitle,),
                      backgroundColor: kCardColor,
                      shape:
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      content: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Are you sure, you want Switch Account?',
                                style: kAlertContent),
                            SizedBox(height: 10),
                          ],
                        ),
                      ),
                      actions: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  elevation: 4,
                                  padding: EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 30),
                                  side: BorderSide(
                                      color: kButtonColor
                                  ),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)
                                  ),
                                ),
                                onPressed: ()  async {
                                  Navigator.pop(context);
                                  final prefs = await SharedPreferences.getInstance();
                                  await FirebaseAuth.instance.signOut();
                                  await prefs.setBool('isSetupDone', false);
                                  await Hive.box<AppNotification>('notifications').clear();
                                  Provider.of<Brain>(context, listen: false).reset();
                                  Provider.of<SessionProvider>(context, listen: false).logout();
                                  Navigator.pushAndRemoveUntil(
                                    context, MaterialPageRoute(builder: (_) => WelcomeScreen()),
                                        (route) => false,);
                                },
                                child: Text('Yes', style: TextStyle(color: Colors.white),)
                            ),
                            ElevatedButton(
                                style: ElevatedButton.styleFrom(

                                  backgroundColor: kButtonColor,
                                  elevation: 4,
                                  padding: EdgeInsets.symmetric(vertical:
                                  10, horizontal: 30),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text('No', style: TextStyle(color: Colors.black),)
                            ),

                          ],
                        )
                      ],
                    ),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.swap_horiz_sharp, color: Colors.white70,),
                    SizedBox(width: 5,),
                    Text('Switch Account',
                      style: GoogleFonts.raleway(color: Colors.white,
                          fontSize: 15, fontWeight: FontWeight.w500),),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 0, left: 15, right: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image(image: AssetImage('images/eraser.png'), height: 60,
                    fit: BoxFit.cover, width: 60,),
                  SizedBox(height: 30,),
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color:  Colors.white,
                            width: 3
                        )
                    ),
                    child: ClipOval(
                        child: Image.file(File(pov.image), fit: BoxFit.cover,)
                    ),
                  ),
                  SizedBox(height: 20,),
                  Text('Username', style:
                  GoogleFonts.inter(fontWeight: FontWeight.w900,
                    fontSize: 18, letterSpacing: 0.5, height: 0),),
                  SizedBox(height: 30,),
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.black38
                      ),
                      child: TextFormField(
                        controller: _controller,
                        readOnly: true,
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                        obscureText: obscureText,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.security),
                          hintText: '6-digit PassCode',
                          suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  obscureText = !obscureText;
                                });
                              },
                              icon: FaIcon(obscureText ? FontAwesomeIcons.eyeSlash :
                              FontAwesomeIcons.eye, size: 18,)
                          ),
                        ),
                        onChanged: (value) {
                          textDigit = value;
                        },
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'This field is required';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 15),
              child: GestureDetector(
                onTap: () async {
                  final Uri uri = Uri.parse('https://wa.me/message/BZ5RBPJYF7PHE1');
                  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                  throw Exception('Could not launch');
                  }
                },
                child: Text(
                  "Forgot PassCode?",
                  style: GoogleFonts.raleway(
                    fontSize: 13,
                    color: kButtonColor,
                    fontWeight: FontWeight.w700,

                  ),
                ),
              ),
            ),
            Center(
              child: ElevatedButton(
                onPressed: () {
                   if (_controller.text.length == 6) {
                     showDialog(
                       context: context,
                       barrierDismissible: false,
                       builder: (context) => Center(
                         child: CircularProgressIndicator(
                           value: 20,
                           backgroundColor: kCardColor,
                           color: kButtonColor,
                         ),
                       ),
                     );
                     if (pov.localPasscode == _controller.text) {

                       Navigator.pushAndRemoveUntil(
                         context, MaterialPageRoute(builder: (_) => BottomBar()), (route) => false,);
                     }
                     else {
                       Navigator.pop(context);
                       FlushBarMessage.showFlushBar(
                           context: context,
                           message: 'Incorrect PassCode',
                         title: 'Ops',
                         icon: Icon(Icons.error_outline, color: kErrorIconColor, size: 30,),
                       );
                     }
                   }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 100),
                    side: BorderSide.none
                ),
                child: Text('Login Now', style:
                GoogleFonts.inter(color: textColor, fontWeight: FontWeight.w700, fontSize: 18)),
              ),
            ),
            CustomPinKeyboard(
              onKeyTap: (digit ) {
                if (_controller.text.length < 6) {
                  _controller.text += digit;
                }
                if (_controller.text.length == 6) {
                  setState(() {
                    buttonColor = Color(0xFF21D3ED);
                    textColor = Colors.black;
                  });
                }
              },
              onBackspace: () {
                if (_controller.text.isNotEmpty) {
                  _controller.text = _controller.text.substring(0, _controller.text.length - 1);
                  setState(() {
                    buttonColor = Color(0x3321DEED);
                    textColor = Colors.white60;
                  });
                }
              },
              onBiometric: () {
                _auth(pov.canAuthenticate());
              },
            )
          ],
        ),
      ),
    );
  }
}

