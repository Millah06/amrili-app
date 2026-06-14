import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/guest_helper.dart';
import '../../../providers/user_provider.dart';
import '../services/chat_room_service.dart';
import '../theme/chat_theme.dart';
import 'message_screen.dart';

/// Landing shown after scanning a personal chat QR (amril.app/chat-user/:id).
/// Resolves the user, shows a confirm card, then opens/creates the room.
class ChatUserLandingPage extends StatefulWidget {
  const ChatUserLandingPage({super.key, required this.userId});

  final String userId;

  @override
  State<ChatUserLandingPage> createState() => _ChatUserLandingPageState();
}

class _ChatUserLandingPageState extends State<ChatUserLandingPage> {
  Map<String, dynamic>? _user;
  bool _loading = true;
  bool _opening = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = await ChatRoomService().findUserById(widget.userId);
    if (!mounted) return;
    setState(() {
      _user = user;
      _loading = false;
      _error = user == null ? 'User not found' : null;
    });
  }

  Future<void> _startChat() async {
    final myId = context.read<UserProvider>().user?.userId;
    if (myId != null && myId == widget.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("That's your own code 🙂")),
      );
      return;
    }
    setState(() => _opening = true);
    try {
      final roomId =
          await ChatRoomService().createOrGetChatRoom(otherId: widget.userId, initiatedVia: 'qr');
      if (!mounted) return;
      // Replace landing with the conversation.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => Peer2PeerChat(
            roomId: roomId,
            otherUid: widget.userId,
            otherUserName: _user?['name'] ?? 'Chat',
            otherAvatarUrl: _user?['avatarUrl'],
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _opening = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not start chat. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChatTheme.scaffold,
      appBar: AppBar(
        backgroundColor: ChatTheme.surface,
        elevation: 0,
        title: Text('Start chat',
            style: GoogleFonts.inter(color: Colors.white, fontSize: 18)),
      ),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : _error != null
                ? _ErrorView(message: _error!, onBack: () => context.pop())
                : _buildCard(),
      ),
    );
  }

  Widget _buildCard() {
    final name = _user?['name'] ?? 'Unknown';
    final userName = _user?['userName'];
    final avatarUrl = _user?['avatarUrl'] as String?;
    final verified = _user?['verified'] == true;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ChatTheme.surface,
              border: Border.all(color: Colors.white24, width: 2),
            ),
            child: ClipOval(
              child: (avatarUrl != null && avatarUrl.isNotEmpty)
                  ? CachedNetworkImage(
                      imageUrl: avatarUrl, fit: BoxFit.cover)
                  : Icon(Icons.person, size: 48, color: Colors.white38),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(name,
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
              ),
              if (verified)
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Icon(Icons.verified_rounded,
                      size: 18, color: Color(0xFF38BDF8)),
                ),
            ],
          ),
          if (userName != null) ...[
            const SizedBox(height: 4),
            Text('@$userName',
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
          ],
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _opening
                  ? null
                  : () => GuestHelper.guardAction(context,
                      action: _startChat, reason: 'chat with people'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ChatTheme.brand,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: _opening
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.chat_bubble_outline_rounded,
                      color: Colors.white),
              label: Text(_opening ? 'Opening…' : 'Message',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onBack});
  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.person_off_outlined, size: 56, color: Colors.white38),
        const SizedBox(height: 14),
        Text(message,
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 15)),
        const SizedBox(height: 18),
        TextButton(onPressed: onBack, child: const Text('Go back')),
      ],
    );
  }
}
