import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chat_model.dart';
import '../providers/chat_provider.dart';
import '../services/chat_room_service.dart';
import '../theme/chat_theme.dart';
import '../widgets/chat_avatar.dart';
import 'message_screen.dart';

/// Inbox of incoming message requests (pending chats someone else started).
/// Accept → moves to normal inbox · Decline → deletes · Block → blocks sender.
class MessageRequestsScreen extends StatelessWidget {
  const MessageRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatsProvider>();
    final requests = provider.requests;

    return Scaffold(
      backgroundColor: ChatTheme.scaffold,
      appBar: AppBar(
        backgroundColor: ChatTheme.surface,
        elevation: 0,
        title: const Text('Message requests',
            style: TextStyle(color: Colors.white, fontSize: 18)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: requests.isEmpty
          ? const Center(
              child: Text('No pending requests',
                  style: TextStyle(color: Colors.white54)),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: requests.length,
              separatorBuilder: (_, __) => Divider(
                indent: 16,
                endIndent: 16,
                color: Colors.white.withValues(alpha: 0.05),
                height: 1,
              ),
              itemBuilder: (_, i) => _RequestTile(chat: requests[i]),
            ),
    );
  }
}

class _RequestTile extends StatefulWidget {
  const _RequestTile({required this.chat});
  final ChatModel chat;

  @override
  State<_RequestTile> createState() => _RequestTileState();
}

class _RequestTileState extends State<_RequestTile> {
  bool _busy = false;

  Future<void> _respond(String action) async {
    setState(() => _busy = true);
    final ok = await ChatRoomService()
        .respondToRequest(roomId: widget.chat.id, action: action);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Action failed. Try again.')),
      );
      return;
    }
    if (action == 'accept') {
      // Open the conversation now that it's accepted.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => Peer2PeerChat(
            roomId: widget.chat.id,
            otherUserName: widget.chat.name,
            otherUid: widget.chat.otherUserId,
            otherAvatarUrl: widget.chat.avatarUrl,
          ),
        ),
      );
    }
    // For decline/block the Firestore stream will drop it from `requests`.
  }

  @override
  Widget build(BuildContext context) {
    final chat = widget.chat;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ChatAvatar(name: chat.name, avatarUrl: chat.avatarUrl, size: 46),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(chat.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      chat.lastMessage?.isNotEmpty == true
                          ? chat.lastMessage!
                          : 'wants to chat with you',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_busy)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _respond('accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ChatTheme.brand,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Accept',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _respond('decline'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Delete',
                        style: TextStyle(color: Colors.white70)),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Block',
                  onPressed: () => _respond('block'),
                  icon: const Icon(Icons.block, color: Color(0xFFF87171)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
