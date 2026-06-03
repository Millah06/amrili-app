import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../components/bootom_bar.dart';

class CommunityScreen extends StatelessWidget {
  // Replace with your actual links
  final String telegramLink = "https://t.me/nexpay_community";
  final String whatsappCommunityLink = "https://chat.whatsapp.com/Cqlmcy2TOJp6wuyRkLy18v?mode=ac_t";
  final String whatsappChannelLink = "https://whatsapp.com/channel/0029VbBIliP5a23vbHm4bw03";

  final bool ? isLogInOut;

  const CommunityScreen({super.key, this.isLogInOut});

  // Future<void> _openLink(String url) async {
  //   final Uri uri = Uri.parse(url);
  //   if (await canLaunchUrl(uri)) {
  //     await launchUrl(uri, mode: LaunchMode.externalApplication);
  //   }
  // }

  Future<void> _openLink(String groupLink) async {
    final Uri url = Uri.parse(groupLink);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF0D9488), Color(0xFF0F172A), Color(0xFF0D9488) ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SingleChildScrollView(
          clipBehavior: Clip.none,
          padding: EdgeInsets.zero,
          child: SafeArea(
            child: Column(
              children: [
                Container(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: 15, top: 5),
                    child: GestureDetector(
                      onTap: () {
                        isLogInOut ?? false ?  Navigator.pushAndRemoveUntil(
                          context, MaterialPageRoute(builder: (_) => BottomBar()), (route) => false,)
                            : Navigator.pop(context);
                      },
                      child: Icon(Icons.cancel, size: 30,),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Text(
                      "Join Our Community 🚀",
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Get updates, promos & support.\nChoose WhatsApp or Telegram — or both!",
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),

                    // Telegram Card
                    _buildCommunityCard(
                      context,
                      title: "Join us on Telegram",
                      subtitle: "Join our global channel & group",
                      color: Colors.blue,
                      icon: FontAwesomeIcons.message, // paper-plane vibe
                      onTap: () => _openLink(telegramLink),
                    ),

                    const SizedBox(height: 20),
                    // WhatsApp Card
                    _buildCommunityCard(
                      context,
                      title: "Join our WhatsApp Community",
                      subtitle: "Connect, chat & grow together",
                      color: Colors.green,
                      icon: FontAwesomeIcons.whatsapp,
                      onTap: () => _openLink(whatsappCommunityLink),
                    ),

                    const SizedBox(height: 20),
                    // WhatsApp Card
                    _buildCommunityCard(
                      context,
                      title: "Join our WhatsApp Channel",
                      subtitle: "Stay updated with official news",
                      color: Colors.green,
                      icon: FontAwesomeIcons.whatsapp,
                      onTap: () => _openLink(whatsappChannelLink),
                    ),

                    SizedBox(height: 70,),

                    // Why Join bullets
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        children: const [
                          _Bullet(text: "🔔 Exclusive promos"),
                          _Bullet(text: "💬 Direct community support"),
                          _Bullet(text: "🎁 Benefit from our giveaway"),
                        ],
                      ),
                    ),

                    isLogInOut ?? false ? SizedBox(height: 40) : SizedBox(height: 60,),

                    // Skip Button
                    if (isLogInOut ?? false)
                      TextButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context, MaterialPageRoute(builder: (_) => BottomBar()), (route) => false,);
                        },
                        child: const Text(
                          "Skip for now",
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCommunityCard(
      BuildContext context, {
        required String title,
        required String subtitle,
        required Color color,
        required FaIconData icon,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withOpacity(0.15),
              child: FaIcon(icon, size: 25, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style:
                      const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: GoogleFonts.raleway(color: Colors.grey[600])),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 18, color: color),
          ],
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';
//
// class CommunityScreen extends StatelessWidget {
//   const CommunityScreen({Key? key}) : super(key: key);
//
//   // Replace with your real invite links
//   final String whatsappChannel =
//       "https://whatsapp.com/channel/XXXXXXXXXXXXXX";
//   final String whatsappCommunity =
//       "https://chat.whatsapp.com/XXXXXXXXXXXXXX";
//   final String telegramChannel =
//       "https://t.me/nexpay_community";
//
//   Future<void> _launchUrl(String url) async {
//     final Uri uri = Uri.parse(url);
//     if (await canLaunchUrl(uri)) {
//       await launchUrl(uri, mode: LaunchMode.externalApplication);
//     } else {
//       throw 'Could not launch $url';
//     }
//   }
//
//   Widget buildCard({
//     required String title,
//     required String subtitle,
//     required String imagePath,
//     required List<Color> gradient,
//     required String url,
//   }) {
//     return GestureDetector(
//       onTap: () => _launchUrl(url),
//       child: Container(
//         margin: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
//         padding: const EdgeInsets.all(25),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(24),
//           gradient: LinearGradient(
//             colors: gradient,
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//           boxShadow: [
//             BoxShadow(
//               color: gradient.first.withOpacity(0.4),
//               blurRadius: 20,
//               spreadRadius: 2,
//               offset: const Offset(0, 8),
//             ),
//           ],
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Image.asset(
//               imagePath,
//               height: 80,
//               width: 80,
//             ),
//             const SizedBox(height: 20),
//             Text(
//               title,
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 22,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               subtitle,
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 color: Colors.white.withOpacity(0.9),
//                 fontSize: 14,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF0F172A),
//       appBar: AppBar(
//         title: const Text("Join Our Community"),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: ListView(
//               children: [
//                 buildCard(
//                   title: "WhatsApp Channel",
//                   subtitle: "Stay updated with official news",
//                   imagePath: "assets/images/whatsapp.png",
//                   gradient: [Colors.green.shade600, Colors.green.shade400],
//                   url: whatsappChannel,
//                 ),
//                 buildCard(
//                   title: "WhatsApp Community",
//                   subtitle: "Connect, chat & grow together",
//                   imagePath: "assets/images/whatsapp.png",
//                   gradient: [Colors.teal.shade600, Colors.teal.shade400],
//                   url: whatsappCommunity,
//                 ),
//                 buildCard(
//                   title: "Telegram",
//                   subtitle: "Join our global channel & group",
//                   imagePath: "assets/images/telegram.png",
//                   gradient: [Colors.blue.shade600, Colors.blue.shade400],
//                   url: telegramChannel,
//                 ),
//               ],
//             ),
//           ),
//           // Bottom actions
//           Padding(
//             padding: const EdgeInsets.all(20.0),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: OutlinedButton(
//                     style: OutlinedButton.styleFrom(
//                       foregroundColor: Colors.white,
//                       side: const BorderSide(color: Colors.white70),
//                       padding: const EdgeInsets.symmetric(vertical: 14),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(14),
//                       ),
//                     ),
//                     onPressed: () {
//                       Navigator.pop(context); // close or continue
//                     },
//                     child: const Text("Skip for Now"),
//                   ),
//                 ),
//                 const SizedBox(width: 15),
//                 Expanded(
//                   child: ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.blueAccent,
//                       padding: const EdgeInsets.symmetric(vertical: 14),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(14),
//                       ),
//                     ),
//                     onPressed: () {
//                       Navigator.pop(context); // or navigate to home
//                     },
//                     child: const Text(
//                       "Continue",
//                       style: TextStyle(color: Colors.white),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }


