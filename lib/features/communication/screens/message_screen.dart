import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:everywhere/shared/widgets/net_image.dart';
import 'package:everywhere/features/communication/widgets/message_bubble.dart';
import 'package:everywhere/features/communication/services/message_service.dart';
import 'package:everywhere/features/communication/services/chat_cache_service.dart';
import 'package:everywhere/features/communication/models/chat_message.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../constraints/constants.dart';
import '../../../constraints/formatters.dart';
import '../../../providers/user_provider.dart';
import '../theme/chat_theme.dart';
import '../widgets/chat_attach_panel.dart';
import '../widgets/gift_bubble.dart';
import '../widgets/gift_picker_sheet.dart';

/* deploying security rule

firebase deploy --only firestore:rules
 */

class Peer2PeerChat extends StatefulWidget {
  final String roomId;
  final String otherUid;
  final String otherUserName;
  final String? otherAvatarUrl;
  /// When set, the back button calls this instead of Navigator.maybePop.
  /// Used by the wide-screen split-pane layout in chat_screen.dart.
  final VoidCallback? onBack;

  const Peer2PeerChat({
    super.key,
    required this.otherUid,
    required this.roomId,
    required this.otherUserName,
    this.otherAvatarUrl,
    this.onBack,
  });


  @override
  State<Peer2PeerChat> createState() => _Peer2PeerChatState();
}

class _Peer2PeerChatState extends State<Peer2PeerChat> {
  final messageTextController = TextEditingController();


  String messageText = '';
  bool _showAttach = false;

  final FocusNode _focusNode =  FocusNode();

  final MessageService _messageService = MessageService();

  @override
  void dispose() {
    messageTextController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _comingSoon(String what) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$what coming soon'),
          duration: const Duration(seconds: 1)),
    );
  }

  void _toggleAttach() {
    FocusScope.of(context).unfocus();
    setState(() => _showAttach = !_showAttach);
  }

  @override
  Widget build(BuildContext context) {
    // Postgres user id — the single chat identity (must match backend's
    // participants/senderId which are Postgres ids, NOT the Firebase uid).
    final myId = context.watch<UserProvider>().user?.userId ?? '';
    return Scaffold(
      backgroundColor: ChatTheme.scaffold,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            decoration: const BoxDecoration(
              color: ChatTheme.brand,
              boxShadow: [
                BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
              ],
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 6,
              bottom: 10,
              left: 2,
              right: 6,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 24),
                  onPressed: widget.onBack ?? () => Navigator.maybePop(context),
                ),
                _HeaderAvatar(
                    name: widget.otherUserName,
                    avatarUrl: widget.otherAvatarUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.otherUserName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.raleway(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      ),
                      Text(
                        'tap for contact info',
                        style: GoogleFonts.inter(
                            color: Colors.white70, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                  color: ChatTheme.surface,
                  onSelected: (v) {
                    // Phase 4 will wire these actions.
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('"$v" coming soon'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'View contact',
                      child: Text('View contact',
                          style: TextStyle(color: Colors.white)),
                    ),
                    PopupMenuItem(
                      value: 'Search',
                      child:
                          Text('Search', style: TextStyle(color: Colors.white)),
                    ),
                    PopupMenuItem(
                      value: 'Mute',
                      child:
                          Text('Mute', style: TextStyle(color: Colors.white)),
                    ),
                    PopupMenuItem(
                      value: 'Block',
                      child: Text('Block',
                          style: TextStyle(color: Color(0xFFF87171))),
                    ),
                  ],
                ),
              ],
            ),
          ),

          MessagesStream(otherUserId: widget.otherUid,
            roomId: widget.roomId, currentUserId: myId,),
          Container(
            decoration: BoxDecoration(
              color:  Color(0xFF1E293B),
              borderRadius: BorderRadius.only(
                  topRight: Radius.circular(32),
                topLeft: Radius.circular(32)
              ),
            ),
            padding: EdgeInsets.only(
              left: 10,
              right: 10,
              top: 5,
              bottom: 10 + MediaQuery.of(context).padding.bottom,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                // Attach (+) — toggles the inline attachment tray below the bar.
                IconButton(
                  icon: Icon(
                      _showAttach
                          ? Icons.close_rounded
                          : Icons.add_circle_outline_rounded,
                      color: Colors.white70,
                      size: 26),
                  onPressed: _toggleAttach,
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      FocusScope.of(context).requestFocus(_focusNode);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: ChatTheme.inputField,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextFormField(
                        controller: messageTextController,
                        focusNode: _focusNode,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (value) => setState(() => messageText = value),
                        decoration: const InputDecoration(
                          hintText: 'Message',
                          hintStyle: TextStyle(color: Colors.white38),
                          border: InputBorder.none,
                          isCollapsed: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                          focusedBorder: InputBorder.none,
                        ),
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        cursorColor: ChatTheme.brandBright,
                        maxLines: 5,
                        minLines: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _SendButton(
                  visible: messageText.trim().isNotEmpty,
                  onTap: () async {
                    final text = messageText.trim();
                    if (text.isEmpty) return;
                    messageTextController.clear();
                    setState(() => messageText = '');
                    await _messageService.sendTextMessage(
                      roomId: widget.roomId,
                      senderId: myId,
                      text: text,
                      receiverId: widget.otherUid,
                    );
                  },
                ),
              ],
            ),
          ),
          // Inline attachment tray — sits BELOW the input bar (input above it).
          if (_showAttach)
            ChatAttachPanel(
              onSelected: () => setState(() => _showAttach = false),
              onGift: () => GiftPickerSheet.show(
                context,
                roomId: widget.roomId,
                senderId: myId,
                receiverId: widget.otherUid,
              ),
              onRedPacket: () => _comingSoon('Red Pocket'),
              onPhoto: () => _comingSoon('Gallery'),
              onCamera: () => _comingSoon('Camera'),
              onAirtime: () => _comingSoon('Airtime'),
              onMoney: () => _comingSoon('Send Money'),
            ),
        ],
      ),
    );
  }
}

class MessagesStream extends StatelessWidget {
  const MessagesStream({
    super.key,
    required this.otherUserId,
    required this.roomId,
    required this.currentUserId,
  });

  final String otherUserId;
  final String roomId;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    // Cache-first: this is what paints offline / on first frame, and it keeps
    // messages the server has since expired/deleted readable on-device.
    final cached = ChatCacheService.instance.getMessages(roomId);

    return StreamBuilder(
      stream: MessageService().messageStream(roomId),
      builder: (context, snapshot) {
        List<ChatMessage> messages;

        if (snapshot.hasData) {
          final fresh = snapshot.data!.docs
              .map((d) => ChatMessage.fromDoc(d))
              .toList();
          // Merge live + cached in memory (newest-first), persist async.
          final byId = <String, ChatMessage>{};
          for (final m in cached) {
            byId[m.id] = m;
          }
          for (final m in fresh) {
            byId[m.id] = m;
          }
          messages = byId.values.toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          ChatCacheService.instance.mergeAndSaveMessages(roomId, fresh);

          // Delivery receipts: flip the other person's 'sent' → 'delivered'.
          final hasIncomingSent = fresh.any(
              (m) => otherUserId == m.senderId && m.status == 'sent');
          if (hasIncomingSent) {
            MessageService().markMessagesAsDelivered(
                roomId: roomId, currentUserId: currentUserId);
          }

          // I'm viewing this room → always mark read + clear my unread badge,
          // regardless of current message statuses. (The badge bug was that
          // this only ran when an incoming 'sent' message existed.)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            MessageService()
                .markMessagesAsRead(roomId: roomId, currentUserId: currentUserId);
          });
        } else {
          messages = cached;
        }

        if (messages.isEmpty) {
          return const Expanded(
            child: Center(
              child: Text(
                'Say hi and start the conversation 👋',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ),
          );
        }

        // Newest -> oldest with ListView(reverse: true) keeps the latest
        // message near the input. Date separator is appended after the last
        // message of each day.
        final List<Widget> items = [];
        for (int i = 0; i < messages.length; i++) {
          final m = messages[i];
          final dayKey =
              DateTime(m.createdAt.year, m.createdAt.month, m.createdAt.day);

          final time = Formatters()
              .formatTimeInMessages(Timestamp.fromDate(m.createdAt));

          if (m.type == 'gift') {
            items.add(
              GiftBubble(
                emoji: m.giftEmoji ?? '🎁',
                name: m.giftName ?? 'Gift',
                coins: m.coins ?? 0,
                isMe: m.senderId == currentUserId,
                time: time,
              ),
            );
          } else {
            items.add(
              MessageBubble(
                m.type == 'moneyTransfer' ? m.amount : "",
                messageId: m.id,
                text: m.text,
                isMe: m.senderId == currentUserId,
                time: time,
                status: m.status,
                roomId: roomId,
                type: m.type,
              ),
            );
          }

          DateTime? nextDayKey;
          if (i + 1 < messages.length) {
            final n = messages[i + 1].createdAt;
            nextDayKey = DateTime(n.year, n.month, n.day);
          }
          if (nextDayKey == null || nextDayKey != dayKey) {
            items.add(
              _DateSeparator(
                label: Formatters()
                    .formatDateSeparator(Timestamp.fromDate(m.createdAt)),
              ),
            );
          }
        }

        return Expanded(
          child: ListView(
            reverse: true,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            children: items,
          ),
        );
      },
    );
  }
}

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          const Expanded(
            child: Divider(
              color: dateSeparatorBgColor,
              thickness: 0.8,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: dateSeparatorBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              label,
              style: dateSeparatorTextStyle,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Divider(
              color: dateSeparatorBgColor,
              thickness: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

/// Circular avatar for the conversation header — shows the other user's photo
/// when available, otherwise deterministic initials.
/// (Previously the header mistakenly showed the *current* user's photo.)
class _HeaderAvatar extends StatelessWidget {
  const _HeaderAvatar({required this.name, this.avatarUrl});

  final String name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    final initials = parts.isEmpty
        ? '?'
        : parts.length > 1
            ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
            : parts.first[0].toUpperCase();

    const palette = [
      Color(0xFF0D6E7A),
      Color(0xFF7C3AED),
      Color(0xFF0369A1),
      Color(0xFF065F46),
      Color(0xFF9D174D),
      Color(0xFF92400E),
    ];
    final color =
        palette[name.codeUnits.fold(0, (a, b) => a + b) % palette.length];

    final fallback = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.85),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    );

    final url = avatarUrl;
    if (url == null || url.isEmpty) return fallback;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: NetImage(
        url: url,
        fit: BoxFit.cover,
        width: 40,
        height: 40,
        borderRadius: BorderRadius.circular(20),
        errorChild: fallback,
      ),
    );
  }
}

/// Send button that scales/fades in only when there's text to send.
class _SendButton extends StatelessWidget {
  const _SendButton({required this.visible, required this.onTap});

  final bool visible;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: visible ? 1 : 0,
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutBack,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 120),
        child: GestureDetector(
          onTap: visible ? () => onTap() : null,
          child: Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: ChatTheme.brand,
            ),
            child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}

