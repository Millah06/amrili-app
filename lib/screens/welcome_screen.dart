
//
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:google_fonts/google_fonts.dart';
//
// import '../constraints/constants.dart';
// import '../features/auth/login_screen.dart';
// import '../features/auth/signup_screen.dart';
//
//
// class WelcomeScreen extends StatelessWidget {
//
//   static String id = 'welcome';
//   const WelcomeScreen({super.key});
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Color(0xFF0F172A),
//       body: Container(
//         padding: EdgeInsets.only(top: 100, left: 0, right: 0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Text('Welcome to', style: kTopAppbars.copyWith(
//                     fontFamily:  'DejaVu Sans', fontSize: 30)),
//                 Image(image: AssetImage('images/eraser.png'), height: 120,
//                   fit: BoxFit.cover, width: 120,),
//                 SizedBox(height: 30,),
//                 Padding(
//                   padding: const EdgeInsets.only(left: 15, right: 15),
//                   child: Text('The safest, most reliable and '
//                       'trusted VTU service platform, used by resellers, agents'
//                       ' and digital bosses.'
//                       '\n\nPower your hustle with data, airtime, electricity, '
//                       'exams, and more - all in one super powerful app.',
//                     style: GoogleFonts.inter(fontWeight: FontWeight.w900), textAlign: TextAlign.center,),
//                 )
//               ],
//             ),
//             Flexible(
//               child: BottomSheet(
//                 showDragHandle: true,
//                 backgroundColor: Color(0xFF1E293B),
//                 onClosing: () {
//                   Navigator.push(context, MaterialPageRoute(builder: (context)
//                   => LoginScreen())); },
//                 builder: (BuildContext context) {
//                   return FractionallySizedBox(
//                     widthFactor: 1,
//                     heightFactor: 0.8,
//                     child: Center(
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                         children: [
//                           Text('Let\'s get started like a PRO 🦾',
//                             style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 17),),
//                           ElevatedButton(
//                             onPressed: () {
//                             Navigator.push(context, MaterialPageRoute(builder: (context)
//                             => LoginScreen()));
//                             },
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Color(0xFF21D3ED),
//                               padding: EdgeInsets.symmetric(vertical: 15, horizontal: 100)
//                             ),
//                             child: Text('Login', style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 18)),
//                           ),
//                           ElevatedButton(
//                             onPressed: () {
//                               Navigator.push(context, MaterialPageRoute(builder: (context)
//                               => SignUpScreen()));
//                             },
//                             style: ElevatedButton.styleFrom(
//                                 backgroundColor: Colors.transparent,
//                                 elevation: 4,
//                                 padding: EdgeInsets.symmetric(vertical: 15, horizontal: 80),
//                                 side: BorderSide(
//                                     color: kButtonColor
//                                 )
//                             ),
//                             child: Text('New user',
//                               style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),),
//                           )
//                         ],
//                       ),
//                     ),
//                   );
//                   },
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../components/bottom_bar.dart';
import '../../constraints/constants.dart';
import '../../core/auth/auth_provider.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/auth/widgets/social_auth_buttons.dart';

class WelcomeScreen extends StatelessWidget {
  static String id = 'welcome';
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // Background accent glow
          Positioned(
            top: -80,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    kButtonColor.withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top branding
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [kButtonColor, kButtonColor.withOpacity(0.6)],
                          ),
                        ),
                        child: Image.asset('images/eraser.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) =>
                            const Icon(Icons.bolt_rounded,
                                size: 20, color: Colors.white)),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Amril',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),

                // Hero section
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'The super app\nfor everyone.',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Connect with people, power your payments,\n'
                              'shop smarter — all in one place.',
                          style: GoogleFonts.inter(
                            color: Colors.white54,
                            fontSize: 14.5,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Feature chips
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: const [
                            _FeatureChip(label: 'Social Feed', icon: Icons.dynamic_feed_rounded),
                            _FeatureChip(label: 'Wallet', icon: Icons.account_balance_wallet_rounded),
                            _FeatureChip(label: 'Marketplace', icon: Icons.storefront_rounded),
                            _FeatureChip(label: 'Messaging', icon: Icons.chat_bubble_rounded),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Auth panel
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E293B),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  padding: EdgeInsets.fromLTRB(
                      24, 28, 24, MediaQuery.of(context).padding.bottom + 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Get started',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Social auth buttons
                      SocialAuthButtons(padding: EdgeInsets.zero),

                      const SizedBox(height: 16),
                      // Divider
                      Row(children: [
                        const Expanded(child: Divider(color: Colors.white12)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text('or',
                              style: GoogleFonts.inter(
                                  color: Colors.white38, fontSize: 13)),
                        ),
                        const Expanded(child: Divider(color: Colors.white12)),
                      ]),
                      const SizedBox(height: 16),

                      // Email login
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.push(context,
                              MaterialPageRoute(
                                  builder: (_) => const LoginScreen())),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kButtonColor,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text('Continue with Email',
                              style: GoogleFonts.inter(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // New user
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.push(context,
                              MaterialPageRoute(
                                  builder: (_) => const SignUpScreen())),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            side: BorderSide(
                                color: kButtonColor.withOpacity(0.5)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text('Create an account',
                              style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Guest mode
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            context.read<AuthProvider>().continueAsGuest();
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => const BottomBar()),
                                  (r) => false,
                            );
                          },
                          child: Text.rich(
                            TextSpan(
                              text: 'Browse as ',
                              style: GoogleFonts.inter(
                                  color: Colors.white38, fontSize: 13),
                              children: [
                                TextSpan(
                                  text: 'Guest',
                                  style: GoogleFonts.inter(
                                    color: Colors.white60,
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Colors.white30,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ),
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _FeatureChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: kButtonColor, size: 14),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
