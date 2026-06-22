
import 'package:another_flushbar/flushbar.dart';

import 'package:everywhere/core/auth/auth_provider.dart';
import 'package:everywhere/features/auth/profile_picture.dart';
import 'package:everywhere/features/auth/security_step1_screen.dart';
import 'package:everywhere/features/auth/widgets/auth_ui_helpers.dart';
import 'package:everywhere/features/auth/widgets/social_auth_buttons.dart';


import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../constraints/constants.dart';
import '../../constraints/vendor_theme.dart';

import '../../providers/user_provider.dart';
import '../../services/session_service.dart';
import '../../shared/utils/flush_bar_message.dart';
import '../../shared/utils/info_box.dart';
import '../marketPlace/widgets/shared_widgets.dart';
import 'login_screen.dart';

// class SignUpScreen extends StatefulWidget {
//
//   static String id = 'signup';
//   const SignUpScreen({super.key});
//
//   @override
//   State<SignUpScreen> createState() => _SignUpScreenState();
// }
//
// class _SignUpScreenState extends State<SignUpScreen> {
//   Color iconColor = Colors.white54;
//   bool enable = true;
//   bool obscureText = true;
//   bool obscureText2 = true;
//   final _formKey = GlobalKey<FormState>();
//   final _formKey2 = GlobalKey<FormState>();
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _password1controller = TextEditingController();
//   final TextEditingController _password2controller = TextEditingController();
//   final TextEditingController _userNameController = TextEditingController();
//   final TextEditingController _phoneController = TextEditingController();
//   final TextEditingController _referral = TextEditingController();
//
//   // Helper functions to get user-friendly error messages
//   String _getErrorMessage(dynamic error) {
//     if (error.toString().contains('user-not-found')) {
//       return 'No user found with this email';
//     } else if (error.toString().contains('wrong-password')) {
//       return 'Incorrect password';
//     } else if (error.toString().contains('network-request-failed')) {
//       return 'Network error. Please check your connection';
//     } else {
//       return 'Login failed. Please try again';
//     }
//   }
//
//   @override
//   void dispose() {
//     // TODO: implement dispose
//     _emailController.dispose();
//     _password2controller.dispose();
//     _password1controller.dispose();
//     _userNameController.dispose();
//     _phoneController.dispose();
//     _referral.dispose();
//     super.dispose();
//   }
//   @override
//   Widget build(BuildContext context) {
//     return Form(
//       key: _formKey,
//       child: Scaffold(
//         backgroundColor: Color(0xFF0F172A),
//         body: Container(
//           padding: EdgeInsets.only(top: 50,),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Padding(
//                 padding: const EdgeInsets.only(left: 10, right: 10),
//                 child: ListTile(
//                   contentPadding: EdgeInsets.zero,
//                   leading: IconButton(
//                     onPressed: (){
//                       Navigator.pop(context);
//                     },
//                     icon: Icon(Icons.arrow_back),
//                     style: IconButton.styleFrom(
//                         backgroundColor: Colors.white
//                     ),
//                   ),
//                   title: Text('Go Back', style: GoogleFonts.inter(
//                     color: Colors.white,
//                     fontSize: 25,
//                     fontWeight: FontWeight.w700,
//                   )),
//                 ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.only(left: 15, top: 15, right: 15),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text('Initial Setup',
//                       style: GoogleFonts.inter(
//                           fontSize: 16, fontWeight: FontWeight.w900, color: kButtonColor),
//                     ),
//                     const SizedBox(height: 8),
//                     InfoBox(
//                       text: 'Make sure to used strong password with working '
//                           'email. A password with special characters like; "@", '
//                           '"!", "&", "#", "*" etc. It will enhance security to your account. '
//                     ),
//                   ],
//                 ),
//               ),
//               Expanded(
//                 child: SingleChildScrollView(
//                   child: Column(
//                     children: [
//                       Container(
//                         padding: EdgeInsets.only(top: 20, left: 15, right: 15),
//
//                         child: Center(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               VTextField(
//                                 controller: _userNameController,
//                                 label: 'Name',
//                                 hint: 'John Vonn',
//                                 prefixIcon: Icon(FontAwesomeIcons.userLarge, size: 20,),
//                                 onTap: () {
//                                   setState(() {
//                                     iconColor = kButtonColor;
//                                   });
//                                 },
//                                 validator: (value) {
//                                   if (value == null || value.trim().isEmpty) {
//                                     return 'This field is required';
//                                   }
//                                   if (!value.split('').contains(' ')) {
//                                     return 'Two Names are required';
//                                   }
//                                   return null;
//                                 },
//
//                               ),
//                               SizedBox(height: 20,),
//                               VTextField(
//                                   controller: _emailController,
//                                   label: 'Email',
//                                 hint: 'john@gmail.com',
//                                 prefixIcon: Icon(Icons.email, size: 20,),
//                                 keyboardType: TextInputType.emailAddress,
//                                 validator: (value) {
//                                   if (value == null || value.trim().isEmpty) {
//                                     return 'This field is required';
//                                   }
//                                   return null;
//                                 },
//                                 onChange: (value) {
//                                   if (value.isEmpty) {
//                                     _formKey2.currentState!.reset();
//                                   }
//                                 },
//                                 onTap: () {
//                                   setState(() {
//                                     iconColor = kButtonColor;
//                                   });
//                                 },
//
//                               ),
//                               SizedBox(height: 20,),
//                               VTextField(
//                                 controller: _phoneController,
//                                 keyboardType: TextInputType.phone,
//                                 label: 'Phone Number',
//                                 prefixIcon: Icon(FontAwesomeIcons.userLarge, size: 20,),
//                                 prefix: Text('+234 | ',
//                                   style: TextStyle(color: Colors.white, fontSize: 16,
//                                       fontWeight: FontWeight.w900),),
//                                 hint: '7021111111',
//                                 validator: (value) {
//                                   if (value == null || value.trim().isEmpty) {
//                                     return 'This field is required';
//                                   }
//                                   if (value.startsWith('0')) {
//                                     return 'Please remove the first zero';
//                                   }
//                                   return null;
//                                 },
//                                 onChange: (value) {
//                                   if (value.isEmpty) {
//                                     _formKey2.currentState!.reset();
//                                   }
//
//                                 },
//                                 onTap: () {
//                                   setState(() {
//                                     iconColor = kButtonColor;
//                                   });
//                                 },
//
//                               ),
//                               SizedBox(height: 20,),
//                               VTextField(
//                                   controller: _password1controller,
//                                   label: 'Password',
//                                 obscure: obscureText,
//                                 keyboardType: TextInputType.visiblePassword,
//                                 prefixIcon: Icon(Icons.lock),
//                                 validator: (value) {
//                                   if (value == null || value.trim().isEmpty) {
//                                     return 'This field is required';
//                                   }
//                                   if (value.length < 6) {
//                                     return 'Password characters should be at least six';
//                                   }
//                                   return null;
//                                 },
//                                 onChange: (value) {
//
//                                 },
//                                 onTap: () {
//                                   setState(() {
//                                     iconColor = kButtonColor;
//                                   });
//                                 },
//                                 suffixIcon: IconButton(
//                                     onPressed: () {
//                                       setState(() {
//                                         obscureText = !obscureText;
//                                       });
//                                     },
//                                     icon: Icon(obscureText ? FontAwesomeIcons.eyeSlash :
//                                     FontAwesomeIcons.eye, size: 18,)
//                                 ),
//                               ),
//                               SizedBox(height: 20,),
//                               VTextField(
//                                   controller: _password2controller,
//                                   label: 'Confirm Password',
//                                 keyboardType: TextInputType.visiblePassword,
//                                 obscure: obscureText2,
//                                 prefixIcon: Icon(Icons.lock),
//                                 suffixIcon: IconButton(
//                                     onPressed: () {
//
//                                       setState(() {
//                                         obscureText2 = !obscureText2;
//                                       });
//                                     },
//                                     icon: Icon(obscureText2 ? FontAwesomeIcons.eyeSlash :
//                                     FontAwesomeIcons.eye, size: 18,)
//                                 ),
//                                 validator: (value) {
//                                   if (value == null || value.trim().isEmpty) {
//                                     return 'This field is required';
//                                   }
//                                   if (_password1controller.text.characters != _password2controller.text.characters) {
//                                     return 'This password does not match the previous one';
//                                   }
//                                   return null;
//                                 },
//                                 onChange: (value) {
//
//                                 },
//                                 onTap: () {
//                                   setState(() {
//                                     iconColor = kButtonColor;
//                                   });
//                                 },
//                               ),
//
//                               SizedBox(height: 20,),
//                               Text(textAlign: TextAlign.right,
//                                 'Optional',  style: TextStyle(color: VendorTheme.textMuted),),
//                               const SizedBox(height: 10,),
//                               VTextField(
//                                 controller: _referral,
//                                 label: 'Referral Code',
//                               )
//                             ],
//                           ),
//                         ),
//                       ),
//                       SizedBox(height: 20,),
//                       Center(
//                         child: ElevatedButton(
//                           onPressed: () async {
//                             if (_formKey.currentState!.validate()) {
//                               // Show loading spinner
//                               showDialog(
//                                 context: context,
//                                 barrierDismissible: false,
//                                 builder: (context) => Center(
//                                   child: CircularProgressIndicator(
//                                     value: 20,
//                                     backgroundColor: kCardColor,
//                                     color: kButtonColor,
//                                   ),
//                                 ),
//                               );
//                               try {
//                                 final userUid = await
//                                 context.read<AuthProvider>().signUp(
//                                     name: _userNameController.text,
//                                     email: _emailController.text,
//                                     password: _password1controller.text,
//                                     phone: '+234${_phoneController.text.trim()}',
//                                     referralCode: _referral.text,
//                                 );
//
//                                 // Provider.of<SessionProvider>(context, listen: false).login(user!.uid);
//                                 Provider.of<SessionProvider>(context, listen: false).login(userUid);
//                                 // Close loading spinner
//                                 Navigator.pop(context);
//                                 // Show success message
//                                 Navigator.pushReplacement(
//                                   context,
//                                   MaterialPageRoute(builder: (context) => ProfilePicture()),
//                                 );
//
//                                 FlushBarMessage.showFlushBar(context: context,
//                                     message: 'Signed up successfully!',
//                                   title: 'Success',
//                                 );
//                               }
//                               catch (e) {
//                                 print(e.toString());
//                                 Navigator.pop(context);
//                                 FlushBarMessage.showFlushBar(context: context,
//                                   message: e.toString(),
//                                   title: 'Sign Up Failed',
//                                   icon: Icon(Icons.error_outline,
//                                     color: kErrorIconColor, size: 30,),
//                                 );
//                               }
//                             }
//                           },
//                           style: ElevatedButton.styleFrom(
//                               backgroundColor: kButtonColor,
//                               padding: EdgeInsets.symmetric(vertical: 15, horizontal: 130)
//                           ),
//                           child: Text('Proceed',
//                               style: TextStyle(color: Colors.black,
//                                   fontWeight: FontWeight.w700, fontSize: 18)
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }


class SignUpScreen extends StatefulWidget {
  static String id = 'signup';
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _password1Controller = TextEditingController();
  final _password2Controller = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _password1Controller.dispose();
    _password2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ─── Header ──────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    BButton(onTap: () => Navigator.pop(context)),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 28),
                      // ─── Title ─────────────────────────────────────────────
                      Text('Create account.',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          )),
                      const SizedBox(height: 8),
                      Text('Join Amril — free forever.',
                          style: GoogleFonts.inter(
                            color: Colors.white54,
                            fontSize: 14.5,
                          )),
                      const SizedBox(height: 32),

                      // ─── Social Auth ──────────────────────────────────────
                      SocialAuthButtons(padding: EdgeInsets.zero),
                      const SizedBox(height: 28),

                      // ─── Divider ──────────────────────────────────────────
                      OrDivider(label: 'or sign up with email'),
                      const SizedBox(height: 24),

                      // ─── Name ─────────────────────────────────────────────
                      AuthTextField(
                        controller: _nameController,
                        label: 'Full name',
                        hint: 'John Doe',
                        icon: Icons.person_outline_rounded,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Full name is required';
                          }
                          if (!v.trim().contains(' ')) {
                            return 'Please enter your first and last name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // ─── Email ────────────────────────────────────────────
                      AuthTextField(
                        controller: _emailController,
                        label: 'Email address',
                        hint: 'john@example.com',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Email is required';
                          }
                          if (!v.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // ─── Password ─────────────────────────────────────────
                      AuthTextField(
                        controller: _password1Controller,
                        label: 'Password',
                        hint: '••••••••',
                        icon: Icons.lock_outline_rounded,
                        obscure: _obscurePassword,
                        suffixIcon: EyeToggle(
                          obscure: _obscurePassword,
                          onTap: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Password is required';
                          }
                          if (v.length < 6) {
                            return 'At least 6 characters required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // ─── Confirm Password ─────────────────────────────────
                      AuthTextField(
                        controller: _password2Controller,
                        label: 'Confirm password',
                        hint: '••••••••',
                        icon: Icons.lock_outline_rounded,
                        obscure: _obscureConfirm,
                        suffixIcon: EyeToggle(
                          obscure: _obscureConfirm,
                          onTap: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (v != _password1Controller.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      // ─── Create Account button ────────────────────────────
                      PrimaryButton(
                        label: 'Create Account',
                        onTap: () async {
                          FocusScope.of(context).unfocus();
                          if (!_formKey.currentState!.validate()) return;

                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => const Center(
                              child: CircularProgressIndicator(
                                  color: kButtonColor),
                            ),
                          );
                          try {
                            final authProvider = context.read<AuthProvider>();
                            final uid =
                            await authProvider.signUp(
                              name: _nameController.text.trim(),
                              email: _emailController.text.trim(),
                              password: _password1Controller.text,
                            );
                            if (!mounted) return;
                            Provider.of<SessionProvider>(context,
                                listen: false)
                                .login(uid);
                            Navigator.pop(context);
                            context.read<UserProvider>()
                                .seedFromAuth(authProvider.authUserData!);// close loader
                            FlushBarMessage.showFlushBar(
                              context: context,
                              message: "You're almost in! Let's complete your profile.",
                              title: 'Account created',
                            );
                            // Phone + referral collected in Step 1
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                  const SecurityStep1Screen()),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            Navigator.pop(context);
                            FlushBarMessage.showFlushBar(
                              context: context,
                              message: e.toString(),
                              title: 'Sign Up Failed',
                              icon: const Icon(Icons.error_outline,
                                  color: kErrorIconColor, size: 28),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 28),

                      // ─── Cross-link to Login ───────────────────────────────
                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen()),
                          ),
                          child: Text.rich(
                            TextSpan(
                              text: 'Already have an account?  ',
                              style: GoogleFonts.inter(
                                  color: Colors.white54, fontSize: 13.5),
                              children: [
                                TextSpan(
                                  text: 'Sign in',
                                  style: GoogleFonts.inter(
                                    color: kButtonColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                  ),
                  ),
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