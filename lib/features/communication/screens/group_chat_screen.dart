import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../constraints/formatters.dart';
import '../../../providers/user_provider.dart';
import '../services/message_service.dart';
import '../theme/chat_theme.dart';
import '../widgets/message_bubble.dart';
import 'group_info_screen.dart';

/// Group conversation. Shares the message bubble + date-separator look with the
/// p2p screen, but renders sender names above received messages and fans out
/// unread counts to all members on send.
class GroupChatScreen extends StatefulWidget {
  final String roomId;
  /// When set, the back button calls this instead of Navigator.maybePop.
  /// Used by the wide-screen split-pane layout in chat_screen.dart.
  final VoidCallback? onBack;

  const GroupChatScreen({super.key, required this.roomId, this.onBack});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final _controller = TextEditingController();
  final _messageService = MessageService();
  String _text = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.watch<UserProvider>().user?.userId ?? '';
    final roomRef =
        FirebaseFirestore.instance.collection('chat_room').doc(widget.roomId);

    return Scaffold(
      backgroundColor: ChatTheme.scaffold,
      body: StreamBuilder<DocumentSnapshot>(
        stream: roomRef.snapshots(),
        builder: (context, roomSnap) {
          final room = roomSnap.data?.data() as Map<String, dynamic>? ?? {};
          final participants =
              (room['participants'] as List?)?.cast<String>() ?? const [];
          final participantInfo =
              (room['participantInfo'] as Map?)?.cast<String, dynamic>() ?? {};
          final groupName = room['groupName'] ?? 'Group';

          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(context, groupName, participants.length),
              _GroupMessages(
                roomId: widget.roomId,
                myId: myId,
                participantInfo: participantInfo,
              ),
              _inputBar(myId, participants),
            ],
          );
        },
      ),
    );
  }

  Widget _header(BuildContext context, String name, int memberCount) {
    return Container(
      decoration: const BoxDecoration(color: ChatTheme.brand),
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 6,
          bottom: 10,
          left: 2,
          right: 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: widget.onBack ?? () => Navigator.maybePop(context),
          ),
          Expanded(
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => GroupInfoScreen(roomId: widget.roomId)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: Color(0xFF0D6E7A)),
                    child:
                        const Icon(Icons.group, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.raleway(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18)),
                        Text('$memberCount members · tap for info',
                            style: GoogleFonts.inter(
                                color: Colors.white70, fontSize: 11.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: Colors.white),
            tooltip: 'Group info',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => GroupInfoScreen(roomId: widget.roomId)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputBar(String myId, List<String> participants) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius:
            BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        left: 10,
        right: 10,
        top: 8,
        bottom: 10 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: ChatTheme.inputField,
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _controller,
                onChanged: (v) => setState(() => _text = v),
                style: const TextStyle(color: Colors.white, fontSize: 16),
                cursorColor: ChatTheme.brandBright,
                minLines: 1,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Message',
                  hintStyle: TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                  isCollapsed: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () async {
              final text = _text.trim();
              if (text.isEmpty) return;
              _controller.clear();
              setState(() => _text = '');
              await _messageService.sendGroupMessage(
                roomId: widget.roomId,
                senderId: myId,
                text: text,
                participantIds: participants,
              );
            },
            child: Container(
              width: 46,
              height: 46,
              decoration:
                  const BoxDecoration(shape: BoxShape.circle, color: ChatTheme.brand),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupMessages extends StatelessWidget {
  const _GroupMessages({
    required this.roomId,
    required this.myId,
    required this.participantInfo,
  });

  final String roomId;
  final String myId;
  final Map<String, dynamic> participantInfo;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: MessageService().messageStream(roomId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Expanded(
              child: Center(child: CircularProgressIndicator()));
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Expanded(
            child: Center(
              child: Text('No messages yet',
                  style: TextStyle(color: Colors.white54)),
            ),
          );
        }
        return Expanded(
          child: ListView.builder(
            reverse: true,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final m = docs[i].data() as Map<String, dynamic>;
              final senderId = m['senderId'] ?? '';
              final isMe = senderId == myId;
              final senderName =
                  (participantInfo[senderId]?['name'] as String?) ?? 'Unknown';
              return Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(left: 14, top: 4),
                      child: Text(senderName,
                          style: TextStyle(
                              color: ChatTheme.brandBright,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600)),
                    ),
                  MessageBubble(
                    "",
                    messageId: docs[i].id,
                    text: m['text'],
                    isMe: isMe,
                    time: m['createdAt'] is Timestamp
                        ? Formatters().formatTimeInMessages(m['createdAt'])
                        : '',
                    status: m['status'] ?? 'sent',
                    roomId: roomId,
                    type: m['type'] ?? 'text',
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
