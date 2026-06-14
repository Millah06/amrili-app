import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../providers/user_provider.dart';
import '../../marketPlace/widgets/amril_qr_code.dart';
import '../theme/chat_theme.dart';

/// Personal chat QR: a "My Code" tab (your scannable code) + a "Scan" entry
/// that opens the existing camera scanner. Scanning someone's code routes to
/// the chat-user landing via amril.app/chat-user/:id (handled in the router).
class MyChatQrScreen extends StatelessWidget {
  const MyChatQrScreen({super.key});

  static String payloadFor(String userId) =>
      'https://amril.app/chat-user/$userId';

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final userId = user?.userId ?? '';
    final name = user?.name ?? 'My code';
    final userName = user?.userProfile.userName;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: ChatTheme.scaffold,
        appBar: AppBar(
          backgroundColor: ChatTheme.surface,
          elevation: 0,
          title: Text('My QR code',
              style: GoogleFonts.inter(color: Colors.white, fontSize: 18)),
          bottom: const TabBar(
            indicatorColor: ChatTheme.brandBright,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: 'My Code'),
              Tab(text: 'Scan'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ── My Code ──────────────────────────────────────────────
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (userId.isEmpty)
                      const Text('Sign in to get your code',
                          style: TextStyle(color: Colors.white54))
                    else
                      AmrilQRCode(
                        data: payloadFor(userId),
                        label: name,
                        caption: userName != null
                            ? '@$userName · Scan to chat'
                            : 'Scan to chat with me',
                        logoUrl: user?.userProfile.avatarUrl,
                      ),
                    const SizedBox(height: 20),
                    Text(
                      'Show this code to let someone start a chat with you.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          color: Colors.white38, fontSize: 12.5, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
            // ── Scan ─────────────────────────────────────────────────
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.qr_code_scanner_rounded,
                      size: 64, color: Colors.white24),
                  const SizedBox(height: 16),
                  Text('Scan a friend’s chat code',
                      style: GoogleFonts.inter(
                          color: Colors.white70, fontSize: 15)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/scan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ChatTheme.brand,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.camera_alt_outlined,
                        color: Colors.white),
                    label: const Text('Open scanner',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
