
import 'dart:io';

import 'package:another_flushbar/flushbar.dart';
import 'package:everywhere/features/auth/security2.dart';
import 'package:everywhere/shared/utils/flush_bar_message.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../components/bootom_bar.dart';
import '../../constraints/constants.dart';
import '../../services/auth_service.dart';
import '../../services/session_service.dart';
import '../marketPlace/widgets/shared_widgets.dart';

class LoginScreen extends StatefulWidget {

  static String id = 'login';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  Color iconColor = Colors.white54;
  bool enable = true;
  bool obscureText = true;
  bool obscureText2 = true;
  final _formKey = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _password1controller = TextEditingController();
  final TextEditingController _password2controller = TextEditingController();

  // Helper functions to get user-friendly error messages
  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('user-not-found')) {
      return 'No user found with this email';
    } else if (error.toString().contains('wrong-password')) {
      return 'Incorrect password';
    } else if (error.toString().contains('network-request-failed')) {
      return 'Network error. Please check your connection';
    } else {
      return 'Login failed. Please try again';
    }
  }

  // In your authentication screen
  Future<void> _sendPasswordResetEmail(BuildContext context, String email) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );


      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      // Close loading
      Navigator.pop(context);

      // Show success

      FlushBarMessage.showFlushBar(
        context: context,
        message:  'Password reset link sent to $email',
        title: 'Email Sent'
      );




    } on FirebaseAuthException catch (e) {
      Navigator.pop(context); // Close loading

      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No account found with this email';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        default:
          message = 'Error sending reset email: ${e.message}';
      }

      Flushbar(
        title: 'Error',
        message: message,
        duration: Duration(seconds: 5),
        backgroundColor: Colors.red,
      ).show(context);
    } catch (e) {
      Navigator.pop(context);
      Flushbar(
        title: 'Error',
        message: 'An unexpected error occurred',
        duration: Duration(seconds: 5),
        backgroundColor: Colors.red,
      ).show(context);
    }
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final emailController = TextEditingController();

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => FractionallySizedBox(
          heightFactor: 0.9,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text('Reset Password',
                  style: GoogleFonts.raleway(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),),
                SizedBox(height: 20,),
                VTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'john@gmail.com',
                  prefixIcon: Icon(Icons.email, size: 20,),
                  keyboardType: TextInputType.emailAddress,
                  onChange: (value) {
                    if (value.isEmpty) {
                      _formKey2.currentState!.reset();
                    }

                  },
                  onTap: () {
                    setState(() {
                      iconColor = kButtonColor;
                    });
                  },

                ),
                SizedBox(height: 20,),
                Row(
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
                        child: Text('Cancel', style: TextStyle(color: Colors.white),)
                    ),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: kButtonColor,
                            elevation: 4,
                            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 50)
                        ),
                        onPressed: () async {
                          if (emailController.text.isEmpty || !emailController.text.contains('@')) {
                            Flushbar(
                              title: 'Invalid Email',
                              message: 'Please enter a valid email address',
                              duration: Duration(seconds: 3),
                              backgroundColor: Colors.red,
                            ).show(context);
                            return;
                          }

                          await _sendPasswordResetEmail(
                              context,
                              emailController.text
                          );
                        },
                        child: Text('Send Reset Link', style: GoogleFonts.inter(
                            color: Colors.black, fontWeight: FontWeight.bold),)
                    ),
                  ],
                )
              ],
            ),
          ),
        )
    );
  }


  @override
  void dispose() {
    // TODO: implement dispose
    _emailController.dispose();
    _password2controller.dispose();
    _password1controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Container(
          padding: EdgeInsets.only(top: 50, left: 0, right: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 10, right: 15),
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
                padding: const EdgeInsets.only(left: 15, top: 20),
                child: Text('Login to your account',
                  style: GoogleFonts.inter(
                      fontSize: 17, fontWeight: FontWeight.w900, color: kButtonColor),
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
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              VTextField(
                                keyboardType: TextInputType.emailAddress,
                                prefixIcon: Icon(Icons.email, size: 20,),
                                label: 'Email',
                                hint: 'john@gmail.com',
                                controller: _emailController,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'This field is required';
                                  }
                                  return null;
                                },

                                onTap: () {
                                  setState(() {
                                    iconColor = kButtonColor;
                                  });
                                },
                              ),
                              SizedBox(height: 20,),
                              TextFormField(
                                controller: _password1controller,
                                keyboardType: TextInputType.visiblePassword,
                                cursorColor: Colors.white,
                                obscureText: obscureText,
                                style: kInputTextStyle,
                                decoration: InputDecoration(
                                  prefixIcon: Icon(Icons.lock),
                                  labelText: 'Password',
                                  filled: true,
                                  suffixIcon: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          obscureText = !obscureText;
                                        });
                                      },
                                      icon: Icon(obscureText ? FontAwesomeIcons.eyeSlash :
                                      FontAwesomeIcons.eye, size: 18,)
                                  ),
                                  hintStyle: TextStyle(color: Color(0x8AFFFFFF)),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'This field is required';
                                  }
                                  if (value.length < 6) {
                                    return 'Password characters should be at least six';
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

                              Padding(
                                padding: const EdgeInsets.only(top: 15),
                                child: GestureDetector(
                                  onTap: () {
                                    _showForgotPasswordDialog(context);
                                  },
                                  child: const Text(
                                    "Forgot PassCode?",
                                    textAlign: TextAlign.end,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: kButtonColor,
                                      fontWeight: FontWeight.w900,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20,),
                      // Center(
                      //   child: ElevatedButton(
                      //     onPressed: () async {
                      //       // if (!_formKey.currentState!.validate()) {
                      //       //   Navigator.pop(context);
                      //       //   Navigator.push(context, MaterialPageRoute(builder: (context)
                      //       //   => BottomBar()));
                      //       // }
                      //       await Authentication().userSignIn(
                      //           _emailController.text,
                      //           _password1controller.text
                      //       );
                      //       Navigator.pop(context);
                      //       Navigator.push(context, MaterialPageRoute(builder: (context)
                      //       => Security2Screen()));
                      //     },
                      //     style: ElevatedButton.styleFrom(
                      //         backgroundColor: kButtonColor,
                      //         padding: EdgeInsets.symmetric(vertical: 15, horizontal: 130)
                      //     ),
                      //     child: Text('Proceed',
                      //         style: TextStyle(color: Colors.white,
                      //             fontWeight: FontWeight.w700, fontSize: 18)
                      //     ),
                      //   ),
                      // ),
                      Center(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              // Show loading spinner
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
                              try {
                                // Attempt login
                                final user = await Authentication(context: context).userSignIn(
                                  _emailController.text,
                                  _password1controller.text,
                                );
                                print('this is my uid ${user!.uid}');
                                Provider.of<SessionProvider>(context, listen: false).login(user!.uid);
                                // Close loading spinner
                                Navigator.pop(context);
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) =>
                                      Security2Screen()),
                                );
                                Flushbar(
                                  title: 'Success',
                                  message: 'Logged in successfully!',
                                  borderRadius: BorderRadius.circular(12),
                                  duration: Duration(seconds: 1),
                                  icon: Icon(Icons.check_circle, color: Colors.green,),
                                  backgroundColor: kErrorBackground,
                                  margin: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                                  flushbarPosition: FlushbarPosition.TOP,
                                ).show(context);

                              } on FirebaseAuthException catch (e) {
                                // Close loading spinner
                                Navigator.pop(context);
                                // Show error message
                                Flushbar(
                                  title: 'Login Failed',
                                  message: e.message,
                                  borderRadius: BorderRadius.circular(12),
                                  backgroundColor: Color(0xFF1E293B),
                                  flushbarPosition: FlushbarPosition.TOP,
                                  icon: Icon(Icons.error_outline,
                                    color: kErrorIconColor, size: 30,),
                                  duration: Duration(seconds: 3),
                                  margin: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                                ).show(context);
                              }
                            }

                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: kButtonColor,
                              padding: EdgeInsets.symmetric(vertical: 15, horizontal: 130)
                          ),
                          child: Text('Proceed',
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
    );
  }
}



