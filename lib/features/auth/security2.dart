
import 'dart:io';
import 'package:everywhere/providers/user_provider.dart';
import 'package:everywhere/services/api_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constraints/constants.dart';
import '../../constraints/vendor_theme.dart';
import '../../screens/community_screen.dart';
import '../../services/brain.dart';
import '../../shared/utils/info_box.dart';


class Security2Screen extends StatefulWidget {

  static String id = 'security2';
  const Security2Screen({super.key});


  @override
  State<Security2Screen> createState() => _Security2ScreenState();
}

class _Security2ScreenState extends State<Security2Screen> {

  Color iconColor = Colors.white54;
  bool enable = true;
  bool obscureText1 = true;
  bool obscureText2 = true;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passcodeController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();

  File? _imageFile;

  Future<File> getImageFileFromAssets(String path) async {
    final byteData = await rootBundle.load(path);

    final appDir = await getApplicationDocumentsDirectory();
    final file = File('${appDir.path}/profile.png');

    await file.writeAsBytes(byteData.buffer.asUint8List());
    return file;
  }

  void _pick() async {
    File file = await getImageFileFromAssets('images/profile.png');
    _imageFile = file;

  }
  @override
  void initState() {
    // TODO: implement initState
    _pick();

    super.initState();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('loginPassCode', _passcodeController.text);
    await prefs.setString('transactionPIN', _pinController.text);
    await prefs.setString('imagePath', _imageFile!.path ?? '');
    await prefs.setBool('isSetupDone', true);
    // Navigator.pushAndRemoveUntil(
    //   context, MaterialPageRoute(builder: (_) => BottomBar()), (route) => false,);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _passcodeController.dispose();
    _pinController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Container(
          padding: EdgeInsets.only(top: 50,),
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
                  padding: const EdgeInsets.only(left: 15, top: 20, right: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Credential Confirmation',
                        style: GoogleFonts.inter(
                            fontSize: 16, fontWeight: FontWeight.w900, color: kButtonColor),
                      ),
                      const SizedBox(height: 8),
                      InfoBox(
                          text: 'For security reasons, you are required '
                              'to confirm these, don\'t worry if you forgot them, '
                              'just set new ones',
                        icon: const Icon(Icons.vpn_key_outlined, color: VendorTheme.warning, size: 18),
                        color: VendorTheme.warning,
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
                                  controller: _passcodeController,
                                  keyboardType: TextInputType.number,
                                  cursorColor: Colors.white,
                                  obscureText: obscureText1,
                                  style: kInputTextStyle,
                                  maxLength: 6,
                                  decoration: InputDecoration(
                                    filled: true,
                                    prefixIcon: Icon(Icons.security),
                                    labelText: '6-digit-login Passcode',
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
                                  controller: _pinController,
                                  keyboardType: TextInputType.number,
                                  cursorColor: Colors.white,
                                  obscureText: obscureText2,
                                  style: kInputTextStyle,
                                  maxLength: 4,
                                  decoration: InputDecoration(
                                    filled: true,
                                    prefixIcon: Icon(Icons.pin),
                                    labelText: '4-digit transaction PIN',
                                    suffixIcon: IconButton(
                                        onPressed: () {
                                          setState(() {
                                            obscureText2 = !obscureText2;
                                          });
                                        },
                                        icon: Icon(obscureText2 ? FontAwesomeIcons.eyeSlash :
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
                                  await UserProvider(api: ApiService()).loadUser();

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
                                style: GoogleFonts.inter(color: Colors.black,
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

