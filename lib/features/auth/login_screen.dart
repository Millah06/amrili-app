
import 'dart:io';
import 'package:another_flushbar/flushbar.dart';
import 'package:everywhere/features/auth/signup_screen.dart';
import 'package:everywhere/features/auth/widgets/auth_ui_helpers.dart';
import 'package:everywhere/features/auth/widgets/social_auth_buttons.dart';
import 'package:everywhere/shared/utils/flush_bar_message.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../components/bootom_bar.dart';
import '../../components/transacrtion_pin.dart';
import '../../constraints/constants.dart';
import '../../core/auth/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/brain.dart';
import '../../services/session_service.dart';
import '../marketPlace/widgets/shared_widgets.dart';
import 'package:provider/provider.dart';

// class LoginScreen extends StatefulWidget {
//
//   static String id = 'login';
//   const LoginScreen({super.key});
//
//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }
//
// class _LoginScreenState extends State<LoginScreen> {
//   Color iconColor = Colors.white54;
//   bool enable = true;
//   bool obscureText = true;
//   bool obscureText2 = true;
//   final _formKey = GlobalKey<FormState>();
//   final _formKey2 = GlobalKey<FormState>();
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _password1controller = TextEditingController();
//   final TextEditingController _password2controller = TextEditingController();
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
//   // In your authentication screen
//   Future<void> _sendPasswordResetEmail(BuildContext context, String email) async {
//     try {
//       // Show loading
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (context) => Center(child: CircularProgressIndicator()),
//       );
//
//
//       await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
//
//       // Close loading
//       Navigator.pop(context);
//
//       // Show success
//
//       FlushBarMessage.showFlushBar(
//         context: context,
//         message:  'Password reset link sent to $email',
//         title: 'Email Sent'
//       );
//
//
//
//
//     } on FirebaseAuthException catch (e) {
//       Navigator.pop(context); // Close loading
//
//       String message;
//       switch (e.code) {
//         case 'user-not-found':
//           message = 'No account found with this email';
//           break;
//         case 'invalid-email':
//           message = 'Invalid email address';
//           break;
//         default:
//           message = 'Error sending reset email: ${e.message}';
//       }
//
//       Flushbar(
//         title: 'Error',
//         message: message,
//         duration: Duration(seconds: 5),
//         backgroundColor: Colors.red,
//       ).show(context);
//     } catch (e) {
//       Navigator.pop(context);
//       Flushbar(
//         title: 'Error',
//         message: 'An unexpected error occurred',
//         duration: Duration(seconds: 5),
//         backgroundColor: Colors.red,
//       ).show(context);
//     }
//   }
//
//   void _showForgotPasswordDialog(BuildContext context) {
//     final emailController = TextEditingController();
//
//     showModalBottomSheet(
//         context: context,
//         isScrollControlled: true,
//         builder: (context) => FractionallySizedBox(
//           heightFactor: 0.9,
//           child: Padding(
//             padding: const EdgeInsets.all(12),
//             child: Column(
//               children: [
//                 Text('Reset Password',
//                   style: GoogleFonts.raleway(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),),
//                 SizedBox(height: 20,),
//                 VTextField(
//                   controller: _emailController,
//                   label: 'Email',
//                   hint: 'john@gmail.com',
//                   prefixIcon: Icon(Icons.email, size: 20,),
//                   keyboardType: TextInputType.emailAddress,
//                   onChange: (value) {
//                     if (value.isEmpty) {
//                       _formKey2.currentState!.reset();
//                     }
//
//                   },
//                   onTap: () {
//                     setState(() {
//                       iconColor = kButtonColor;
//                     });
//                   },
//
//                 ),
//                 SizedBox(height: 20,),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     ElevatedButton(
//                         style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.transparent,
//                             elevation: 4,
//                             padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
//                             side: BorderSide(
//                                 color: kButtonColor
//                             )
//                         ),
//                         onPressed: () {
//                           Navigator.pop(context);
//                         },
//                         child: Text('Cancel', style: TextStyle(color: Colors.white),)
//                     ),
//                     ElevatedButton(
//                         style: ElevatedButton.styleFrom(
//                             backgroundColor: kButtonColor,
//                             elevation: 4,
//                             padding: EdgeInsets.symmetric(vertical: 15, horizontal: 50)
//                         ),
//                         onPressed: () async {
//                           if (emailController.text.isEmpty || !emailController.text.contains('@')) {
//                             Flushbar(
//                               title: 'Invalid Email',
//                               message: 'Please enter a valid email address',
//                               duration: Duration(seconds: 3),
//                               backgroundColor: Colors.red,
//                             ).show(context);
//                             return;
//                           }
//
//                           await _sendPasswordResetEmail(
//                               context,
//                               emailController.text
//                           );
//                         },
//                         child: Text('Send Reset Link', style: GoogleFonts.inter(
//                             color: Colors.black, fontWeight: FontWeight.bold),)
//                     ),
//                   ],
//                 )
//               ],
//             ),
//           ),
//         )
//     );
//   }
//
//
//   @override
//   void dispose() {
//     // TODO: implement dispose
//     _emailController.dispose();
//     _password2controller.dispose();
//     _password1controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Form(
//       key: _formKey,
//       child: Scaffold(
//         backgroundColor: Color(0xFF0F172A),
//         body: Container(
//           padding: EdgeInsets.only(top: 50, left: 0, right: 0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Padding(
//                 padding: const EdgeInsets.only(left: 10, right: 15),
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
//                 padding: const EdgeInsets.only(left: 15, top: 20),
//                 child: Text('Login to your account',
//                   style: GoogleFonts.inter(
//                       fontSize: 17, fontWeight: FontWeight.w900, color: kButtonColor),
//                 ),
//               ),
//               Expanded(
//                 child: SingleChildScrollView(
//                   child: Column(
//                     children: [
//
//                       Container(
//                         padding: EdgeInsets.only(top: 20, left: 15, right: 15),
//                         child: Center(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.end,
//                             children: [
//                               Text(
//                                 'Continue with',
//                                 style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
//                               ),
//                               const SizedBox(height: 12),
//                               SocialAuthButtons(padding: EdgeInsets.zero),
//                               const SizedBox(height: 24),
//                               Row(children: [
//                                 const Expanded(child: Divider(color: Colors.white12)),
//                                 Padding(
//                                   padding: const EdgeInsets.symmetric(horizontal: 14),
//                                   child: Text('or sign in with email',
//                                       style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
//                                 ),
//                                 const Expanded(child: Divider(color: Colors.white12)),
//                               ]),
//                               const SizedBox(height: 20),
//                               VTextField(
//                                 keyboardType: TextInputType.emailAddress,
//                                 prefixIcon: Icon(Icons.email, size: 20,),
//                                 label: 'Email',
//                                 hint: 'john@gmail.com',
//                                 controller: _emailController,
//                                 validator: (value) {
//                                   if (value == null || value.trim().isEmpty) {
//                                     return 'This field is required';
//                                   }
//                                   return null;
//                                 },
//
//                                 onTap: () {
//                                   setState(() {
//                                     iconColor = kButtonColor;
//                                   });
//                                 },
//                               ),
//                               SizedBox(height: 20,),
//                               TextFormField(
//                                 controller: _password1controller,
//                                 keyboardType: TextInputType.visiblePassword,
//                                 cursorColor: Colors.white,
//                                 obscureText: obscureText,
//                                 style: kInputTextStyle,
//                                 decoration: InputDecoration(
//                                   prefixIcon: Icon(Icons.lock),
//                                   labelText: 'Password',
//                                   filled: true,
//                                   suffixIcon: IconButton(
//                                       onPressed: () {
//                                         setState(() {
//                                           obscureText = !obscureText;
//                                         });
//                                       },
//                                       icon: Icon(obscureText ? FontAwesomeIcons.eyeSlash :
//                                       FontAwesomeIcons.eye, size: 18,)
//                                   ),
//                                   hintStyle: TextStyle(color: Color(0x8AFFFFFF)),
//                                 ),
//                                 validator: (value) {
//                                   if (value == null || value.trim().isEmpty) {
//                                     return 'This field is required';
//                                   }
//                                   if (value.length < 6) {
//                                     return 'Password characters should be at least six';
//                                   }
//                                   return null;
//                                 },
//                                 onChanged: (value) {
//
//                                 },
//                                 onTap: () {
//                                   setState(() {
//                                     iconColor = kButtonColor;
//                                   });
//                                 },
//                               ),
//
//                               Padding(
//                                 padding: const EdgeInsets.only(top: 15),
//                                 child: GestureDetector(
//                                   onTap: () {
//                                     _showForgotPasswordDialog(context);
//                                   },
//                                   child: const Text(
//                                     "Forgot PassCode?",
//                                     textAlign: TextAlign.end,
//                                     style: TextStyle(
//                                       fontSize: 14,
//                                       color: kButtonColor,
//                                       fontWeight: FontWeight.w900,
//                                       decoration: TextDecoration.underline,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                       SizedBox(height: 20,),
//                       Center(
//                         child: ElevatedButton(
//                           onPressed: () async {
//                             if (_formKey.currentState!.validate()) {
//                               showDialog(
//                                 context: context,
//                                 barrierDismissible: false,
//                                 builder: (context) => const Center(
//                                   child: CircularProgressIndicator(color: kButtonColor),
//                                 ),
//                               );
//                               try {
//                                 final uid = await context.read<AuthProvider>().signIn(
//                                   email: _emailController.text.trim(),
//                                   password: _password1controller.text,
//                                 );
//                                 Provider.of<SessionProvider>(context, listen: false).login(uid);
//                                 Navigator.pop(context); // close loader
//                                 Navigator.pushReplacement(
//                                   context,
//                                   MaterialPageRoute(builder: (_) => const Security2Screen()),
//                                 );
//                               } catch (e) {
//                                 Navigator.pop(context);
//                                 FlushBarMessage.showFlushBar(
//                                   context: context,
//                                   message: e.toString().replaceAll('Exception:', '').trim(),
//                                   title: 'Login Failed',
//                                   icon: const Icon(Icons.error_outline, color: kErrorIconColor, size: 30),
//                                 );
//                               }
//                             }
//                           },
//                           style: ElevatedButton.styleFrom(
//                               backgroundColor: kButtonColor,
//                               padding: EdgeInsets.symmetric(vertical: 15, horizontal: 130)
//                           ),
//                           child: Text('Proceed',
//                               style: GoogleFonts.inter(color: Colors.black,
//                                   fontWeight: FontWeight.w700, fontSize: 18)
//                           ),
//                         ),
//                       ),
//
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

class LoginScreen extends StatefulWidget {
  static String id = 'login';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _sendPasswordResetEmail(String email) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: kButtonColor),
        ),
      );
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      Navigator.pop(context);
      FlushBarMessage.showFlushBar(
        context: context,
        message: 'Password reset link sent to $email',
        title: 'Check your inbox',
      );
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);
      Flushbar(
        title: 'Error',
        message: e.code == 'user-not-found'
            ? 'No account found with this email'
            : e.message ?? 'Something went wrong',
        duration: const Duration(seconds: 4),
        backgroundColor: Colors.red.shade700,
        borderRadius: BorderRadius.circular(12),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        flushbarPosition: FlushbarPosition.TOP,
      ).show(context);
    }
  }

  void _showForgotPasswordSheet() {
    final emailCtrl = TextEditingController(text: _emailController.text);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          24, 20, 24,
          MediaQuery.of(context).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Reset password',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                )),
            const SizedBox(height: 6),
            Text("We'll send a reset link to your email.",
                style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 13.5,
                )),
            const SizedBox(height: 24),
            AuthTextField(
              controller: emailCtrl,
              label: 'Email address',
              hint: 'john@example.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      side: BorderSide(color: Colors.white.withOpacity(0.2)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Cancel',
                        style: GoogleFonts.inter(
                            color: Colors.white70, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () async {
                      final email = emailCtrl.text.trim();
                      if (email.isEmpty || !email.contains('@')) {
                        Flushbar(
                          message: 'Enter a valid email address.',
                          duration: const Duration(seconds: 3),
                          backgroundColor: Colors.red.shade700,
                          borderRadius: BorderRadius.circular(12),
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          flushbarPosition: FlushbarPosition.TOP,
                        ).show(context);
                        return;
                      }
                      Navigator.pop(context);
                      await _sendPasswordResetEmail(email);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kButtonColor,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Send link',
                        style: GoogleFonts.inter(
                            color: Colors.black, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 28),
                      // ─── Title ─────────────────────────────────────────────
                      Text('Welcome back.',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          )),
                      const SizedBox(height: 8),
                      Text('Sign in to your account',
                          style: GoogleFonts.inter(
                            color: Colors.white54,
                            fontSize: 14.5,
                          )),
                      const SizedBox(height: 32),

                      // ─── Social Auth (fastest path first) ─────────────────
                      SocialAuthButtons(padding: EdgeInsets.zero),
                      const SizedBox(height: 28),

                      // ─── Divider ──────────────────────────────────────────
                      OrDivider(label: 'or sign in with email'),
                      const SizedBox(height: 24),

                      // ─── Email field ──────────────────────────────────────
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

                      // ─── Password field ───────────────────────────────────
                      AuthTextField(
                        controller: _passwordController,
                        label: 'Password',
                        hint: '••••••••',
                        icon: Icons.lock_outline_rounded,
                        obscure: _obscurePassword,
                        suffixIcon: EyeToggle(
                          obscure: _obscurePassword,
                          onTap: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
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
                      const SizedBox(height: 14),

                      // ─── Forgot password ──────────────────────────────────
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () => showForgotPasswordFlow(context),
                          child: Text('Forgot password?',
                              style: GoogleFonts.inter(
                                color: kButtonColor,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              )),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ─── Sign In button ───────────────────────────────────
                      PrimaryButton(
                        label: 'Sign In',
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
                            await authProvider.signIn(
                              email: _emailController.text.trim(),
                              password: _passwordController.text,
                            );
                            if (!mounted) return;
                            Provider.of<SessionProvider>(context,
                                listen: false)
                                .login(uid);
                            Navigator.pop(context); // close loader
                            // Security2Screen removed — go directly to app
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('isSetupDone', true);
                            context.read<UserProvider>()
                                .seedFromAuth(authProvider.authUserData!);
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const BottomBar()),
                                  (r) => false,
                            );
                          } catch (e) {
                            if (!mounted) return;
                            Navigator.pop(context);
                            FlushBarMessage.showFlushBar(
                              context: context,
                              message: _friendlyError(e.toString()),
                              title: 'Sign In Failed',
                              icon: const Icon(Icons.error_outline,
                                  color: kErrorIconColor, size: 28),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 28),

                      // ─── Cross-link to Signup ─────────────────────────────
                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SignUpScreen()),
                          ),
                          child: Text.rich(
                            TextSpan(
                              text: "Don't have an account?  ",
                              style: GoogleFonts.inter(
                                  color: Colors.white54, fontSize: 13.5),
                              children: [
                                TextSpan(
                                  text: 'Create one',
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
            ],
          ),
        ),
      ),
    );
  }

  String _friendlyError(String raw) {
    print(raw);
    if (raw.contains('user-not-found')) return 'No account found with this email.';
    if (raw.contains('wrong-password') || raw.contains('invalid-credential')) {
      return 'Incorrect password. Please try again.';
    }
    if (raw.contains('network-request-failed')) {
      return 'Network error. Check your connection.';
    }
    if (raw.contains('too-many-requests')) {
      return 'Too many attempts. Please wait a moment.';
    }
    return 'Sign in failed. Please try again.';
  }
}