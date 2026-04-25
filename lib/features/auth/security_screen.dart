
import 'package:everywhere/services/brain.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../components/bootom_bar.dart';
import '../../constraints/constants.dart';
import '../../screens/community_screen.dart';
import '../../shared/utils/info_box.dart';


class SecurityScreen extends StatefulWidget {

  static String id = 'security';
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  Color iconColor = Colors.white54;
  bool enable = true;
  bool obscureText1 = true;
  bool obscureText2 = true;
  bool obscureText3 = true;
  bool obscureText4 = true;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passcode1controller = TextEditingController();
  final TextEditingController _passcode2controller = TextEditingController();
  final TextEditingController _pin1controller = TextEditingController();
  final TextEditingController _pin2controller = TextEditingController();

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('loginPassCode', _passcode1controller.text);
    await prefs.setString('transactionPIN', _pin1controller.text);
    await prefs.setBool('isSetupDone', true);
    // Navigator.pushAndRemoveUntil(
    //   context, MaterialPageRoute(builder: (_) => BottomBar()), (route) => false,);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _passcode1controller.dispose();
    _passcode2controller.dispose();
    _pin1controller.dispose();
    _pin2controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Container(
          padding: EdgeInsets.only(top: 50),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10, right: 10),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: IconButton(
                      onPressed: (){
                        Navigator.pop(context);
                      },
                      icon: Icon(Icons.arrow_back),
                      style: IconButton.styleFrom(
                          backgroundColor: Colors.white
                      ),
                    ),
                    title: Text('Go Back', style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                    )),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 15, top: 15, right: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Security Setup',
                        style: GoogleFonts.inter(
                            fontSize: 16, fontWeight: FontWeight.w900, color: kButtonColor),
                      ),
                      const SizedBox(height: 8),
                      InfoBox(
                          text:  'To enhance security, PassCode will always be required'
                              ' to enter your app, and PIN will be used to confirm '
                              'payment. So try inputting something that can easily be remembered'
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.only(top: 20, left: 15, right: 15),
                          child: Center(
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _passcode1controller,
                                  keyboardType: TextInputType.number,
                                  cursorColor: Colors.white,
                                  obscureText: obscureText1,
                                  style: kInputTextStyle,
                                  maxLength: 6,
                                  decoration: InputDecoration(
                                    filled: true,
                                    prefixIcon: Icon(Icons.security),
                                    labelText: 'Set 6-digit-login Passcode',
                                    suffixIcon: IconButton(
                                        onPressed: () {
                                          setState(() {
                                            obscureText1 = !obscureText1;
                                          });
                                        },
                                        icon: Icon(obscureText1 ? FontAwesomeIcons.eyeSlash :
                                        FontAwesomeIcons.eye, size: 18,)
                                    ),
                                    hintStyle: TextStyle(color: Color(0x8AFFFFFF)),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'This field is required';
                                    }
                                    if (value.length != 6) {
                                      return 'Passcode characters should be six';
                                    }
                                    return null;
                                  },
                                  onChanged: (value) {

                                  },
                                  onTap: () {
                                    setState(() {
                                      iconColor = kButtonColor;
                                    });
                                  },
                                ),
                                SizedBox(height: 20,),
                                TextFormField(
                                  controller: _passcode2controller,
                                  // decoration: kInputStyle,
                                  keyboardType: TextInputType.number,
                                  cursorColor: Colors.white,
                                  obscureText: obscureText2,
                                  style: kInputTextStyle,
                                  maxLength: 6,
                                  decoration: InputDecoration(
                                    filled: true,
                                    prefixIcon: Icon(Icons.security),
                                    labelText: 'Confirm the 6-digit-login passcode',
                                    hintStyle: TextStyle(color: Color(0x8AFFFFFF)),
                                    suffixIcon: IconButton(
                                        onPressed: () {

                                          setState(() {
                                            obscureText2 = !obscureText2;
                                          });
                                        },
                                        icon: Icon(obscureText2 ? FontAwesomeIcons.eyeSlash :
                                        FontAwesomeIcons.eye, size: 18,)
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'This field is required';
                                    }
                                    if (value.length != 6) {
                                      return 'Passcode characters should be six';
                                    }
                                    if (_passcode1controller.text.characters != _passcode2controller.text.characters) {
                                      return 'This password does not match the previous one';
                                    }
                                    return null;
                                  },
                                  onChanged: (value) {

                                  },
                                  onTap: () {
                                    setState(() {
                                      iconColor = kButtonColor;
                                    });
                                  },
                                ),
                                SizedBox(height: 20,),
                                TextFormField(
                                  controller: _pin1controller,
                                  keyboardType: TextInputType.number,
                                  cursorColor: Colors.white,
                                  obscureText: obscureText3,
                                  style: kInputTextStyle,
                                  maxLength: 4,
                                  decoration: InputDecoration(
                                    filled: true,
                                    prefixIcon: Icon(Icons.pin),
                                    labelText: 'Set 4-digit transaction PIN',
                                    suffixIcon: IconButton(
                                        onPressed: () {
                                          setState(() {
                                            obscureText3 = !obscureText3;
                                          });
                                        },
                                        icon: Icon(obscureText3 ? FontAwesomeIcons.eyeSlash :
                                        FontAwesomeIcons.eye, size: 18,)
                                    ),
                                    hintStyle: TextStyle(color: Color(0x8AFFFFFF)),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'This field is required';
                                    }
                                    if (value.length != 4) {
                                      return 'PIN characters should be four';
                                    }
                                    return null;
                                  },
                                  onChanged: (value) {

                                  },
                                  onTap: () {
                                    setState(() {
                                      iconColor = kButtonColor;
                                    });
                                  },
                                ),
                                SizedBox(height: 20,),
                                TextFormField(
                                  controller: _pin2controller,
                                  // decoration: kInputStyle,
                                  keyboardType: TextInputType.number,
                                  cursorColor: Colors.white,
                                  obscureText: obscureText4,
                                  style: kInputTextStyle,
                                  maxLength: 4,
                                  decoration: InputDecoration(
                                    filled: true,
                                    prefixIcon: Icon(Icons.pin),
                                    labelText: 'Confirm the 4-digit transaction PIN',
                                    hintStyle: TextStyle(color: Color(0x8AFFFFFF)),
                                    suffixIcon: IconButton(
                                        onPressed: () {

                                          setState(() {
                                            obscureText4 = !obscureText4;
                                          });
                                        },
                                        icon: Icon(obscureText4 ? FontAwesomeIcons.eyeSlash :
                                        FontAwesomeIcons.eye, size: 18,)
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'This field is required';
                                    }
                                    if (value.length != 4) {
                                      return 'PIN characters should be six';
                                    }
                                    if (_pin1controller.text.characters != _pin2controller.text.characters) {
                                      return 'This PIN does not match the previous one';
                                    }
                                    return null;
                                  },
                                  onChanged: (value) {

                                  },
                                  onTap: () {
                                    setState(() {
                                      iconColor = kButtonColor;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 20,),
                        Center(
                          child: ElevatedButton(
                            onPressed: () async {
                              FocusScope.of(context).unfocus();
                              if (_formKey.currentState!.validate()) {

                                showModalBottomSheet(
                                  context: context,
                                  isDismissible: false,
                                  enableDrag: false,
                                  backgroundColor: Colors.black54,
                                  builder: (_) => const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Center(
                                        child: CircularProgressIndicator(
                                          value: 20,
                                          backgroundColor: kCardColor,
                                          color: kButtonColor,
                                        ),
                                      ),
                                      Text('Setting up your account..')
                                    ],
                                  ),
                                );
                                try {

                                  await _saveData();

                                  await Brain().getData();

                                  if (context.mounted) {
                                    Navigator.pop(context); // Remove loading dialog
                                  }

                                  // 4. Navigate away
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(builder: (_) => const CommunityScreen(isLogInOut: true,)),
                                        (route) => false,
                                  );
                                } catch (e) {
                                  // On error, close the sheet too
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Something went wrong: $e")),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: kButtonColor,
                                padding: EdgeInsets.symmetric(vertical: 15, horizontal: 130)
                            ),
                            child: Text('FINISH',
                                style: TextStyle(color: Colors.black,
                                    fontWeight: FontWeight.w700, fontSize: 18)
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

