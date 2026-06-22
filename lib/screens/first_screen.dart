import 'dart:io';

import 'package:another_flushbar/flushbar.dart';
import 'package:everywhere/components/bottom_bar.dart';
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

import '../shared/utils/flush_bar_message.dart';
import '../features/auth/passcode_login.dart';
import '../models/notification_model.dart';
import '../services/brain.dart';
import '../services/session_service.dart';


class FirstScreen extends StatefulWidget {

  static String id = 'First';
  const FirstScreen({super.key});

  @override
  State<FirstScreen> createState() => _FirstScreenState();
}

class _FirstScreenState extends State<FirstScreen> {

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetch();
  }

  Future<void> fetch() async {
    final brain = Provider.of<Brain>(context, listen: false);
    await brain.getData();

  }

  void _auth(Future<bool> canAuth) async {
    final LocalAuthentication auth = LocalAuthentication();
    if (await canAuth) {
      bool result = await auth.authenticate(
          localizedReason: 'Use Fingerprint to login',
          options: const AuthenticationOptions(biometricOnly: true)
      );
      result ?  Navigator.pushAndRemoveUntil(
        context, MaterialPageRoute(builder: (_) => BottomBar()), (route) => false,) :
      FlushBarMessage.showFlushBar(
        context: context,
        message: 'Your device does\'nt support this method, use passcode instead.',
        title: 'Ops',
        icon: Icon(Icons.error_outline,
          color: kErrorIconColor, size: 30,),
      );
    }
    else if (await canAuth == false) {
      FlushBarMessage.showFlushBar(
        context: context,
        message: 'Your device does\'nt support this method, use passcode instead.',
        title: 'Ops',
        icon: Icon(Icons.error_outline,
          color: kErrorIconColor, size: 30,),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pov = Provider.of<Brain>(context);
    return Scaffold(
      body: Container(
        padding: EdgeInsets.only(top: 50, bottom: 20, left: 15, right: 15),
        height: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color:  Colors.white54,
                          width: 1
                      ),
                    image: DecorationImage(image: AssetImage('images/eraser.png'), fit: BoxFit.contain)
                  ),
                ),
                SizedBox(height: 30,),
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color:  Colors.white,
                          width: 3
                      )
                  ),
                  child: ClipOval(
                    child: pov.isLoading ? CircularProgressIndicator() :
                    Image.file(File(pov.imagePath.toString()), fit: BoxFit.cover,)
                  ),
                ),
                SizedBox(height: 20,),
                Text('username', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 15,),),
                SizedBox(height: 30,),
                Icon(Icons.fingerprint, size: 70,),
                SizedBox(height: 30,),
                TextButton(onPressed:  () {_auth(pov.canAuthenticate());},
                    child: Text('Click to log in with Fingerprint',
                      style: GoogleFonts.inter(color: kButtonColor, fontWeight: FontWeight.w600),)),
                Center(
                  child: ElevatedButton(
                    onPressed: () {_auth(pov.canAuthenticate());},
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF21D3ED),
                        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 70)
                    ),
                    child: Text('Verify Fingerprint', style:
                    GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 18)),
                  ),
                ),
              ],
            ),
            Column(
              children: [
                Column(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(
                                builder: (context) => PasscodeScreen()));
                          },
                          child: Text('Login with Password',
                            style: GoogleFonts.inter(color: kButtonColor, fontSize: 15, fontWeight: FontWeight.w900),),
                        ),
                        SizedBox(height: 25,),
                        GestureDetector(
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
                                    fontSize: 13, fontWeight: FontWeight.w400),),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 5,),
                    Divider(indent: 50, endIndent: 50,),
                    Text('POWERED BY SKYNEST INNOVATIONS', style: GoogleFonts.robotoMono(),),
                  ],
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
