import 'package:cached_network_image/cached_network_image.dart';
import 'package:everywhere/constraints/constants.dart';
import 'package:flutter/material.dart';

import '../../../communication/models/chat_model.dart';



class ChatCard extends StatelessWidget {
  final ChatModel chat;
  final VoidCallback? onTap;
  final VoidCallback? onPin;
  final VoidCallback? onArchive;
  final VoidCallback? onViewProfile;
  final VoidCallback? onViewPicture;

  const ChatCard({
    super.key,
    required this.chat,
    this.onTap,
    this.onPin,
    this.onArchive,
    this.onViewProfile,
    this.onViewPicture,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(chat.id),
      background: _buildPinBackground(),
      secondaryBackground: _buildArchiveBackground(),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onPin?.call();
          return false;
        } else {
          onArchive?.call();
          return false;
        }
      },
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [

              /// AVATAR
              _buildAvatar(context),

              const SizedBox(width: 12),

              /// CHAT CONTENT
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    /// NAME ROW
                    Row(
                      children: [

                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  chat.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),

                              //Official chats
                              if (chat.isOfficial)
                                const Padding(
                                  padding: EdgeInsets.only(left: 4),
                                  child: Icon(
                                    Icons.verified,
                                    size: 16,
                                    color: Colors.blue,
                                  ),
                                ),

                              //Pinned chats
                              if (chat.isPinned)
                                const Padding(
                                  padding: EdgeInsets.only(left: 4),
                                  child: Icon(
                                    Icons.push_pin,
                                    size: 14,
                                    color: Colors.orange,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        Text(
                          _formatTime(chat.lastMessageAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: chat.unreadCount > 0
                                ? kButtonColor
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    /// LAST MESSAGE
                    Row(
                      children: [
                        _buildMessageStatus(),
                        const SizedBox(width: 4),

                        Expanded(
                          child: Text(
                            _lastMessagePreview(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color: chat.unreadCount > 0
                                  ? Colors.white
                                  : Colors.white70,
                              fontWeight: chat.unreadCount > 0
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),

                        if (chat.unreadCount > 0)
                          _buildUnreadBadge(),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAvatarDialog(context),
      child: Stack(
        children: [

          /// Avatar
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1E293B), // theme-friendly dark
            ),
            child: ClipOval(
              child: chat.avatarUrl != null
                  ? CachedNetworkImage(
                imageUrl: chat.avatarUrl!,
                fit: BoxFit.cover,
                width: 52,
                height: 52,
                placeholder: (_, __) => const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF38BDF8),
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) =>
                    _buildAvatarFallback(),
              )
                  : _buildAvatarFallback(),
            ),
          ),

          /// Online indicator
          if (chat.isOnline)
            Positioned(
              bottom: 2,
              right: 2,
              child: Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF0F172A),
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback() {
    final name = chat.name.trim();

    String initials = "";

    final parts = name.split(" ");

    if (parts.length > 1) {
      initials =
          "${parts.first[0]}${parts.last[0]}".toUpperCase();
    } else if (name.isNotEmpty) {
      initials = name[0].toUpperCase();
    }

    return Container(
      color: const Color(0xFF1E293B),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Color(0xFF38BDF8),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  /// LAST MESSAGE INTELLIGENCE
  String _lastMessagePreview() {

    if (chat.isTyping) {
      return "typing...";
    }

    switch (chat.lastMessageType) {
      case MessageType.text:
        return chat.lastMessage ?? "No messages yet";

      case MessageType.image:
        return "📷 Photo";

      case MessageType.video:
        return "🎥 Video";

      case MessageType.voice:
        return "🎤 Voice message";

      case MessageType.file:
        return "📎 File";

      case MessageType.gif:
        return "GIF";

      case MessageType.system:
        return chat.lastMessage ?? "System update";
    }
  }

  ///MESSAGE STATUS
  Widget _buildMessageStatus() {
    switch (chat.messageStatus) {
      case MessageStatus.sending:
        return const Icon(Icons.schedule, size: 14, color: Colors.grey);

      case MessageStatus.sent:
        return const Icon(Icons.check, size: 16, color: Colors.grey);

      case MessageStatus.delivered:
        return const Icon(Icons.done_all, size: 16, color: Colors.grey);

      case MessageStatus.read:
        return const Icon(Icons.done_all, size: 16, color: Colors.blue);

      default:
        return const SizedBox();
    }
  }

  /// TIME FORMAT
  String _formatTime(DateTime? time) {
    if (time == null) return "";

    final now = DateTime.now();
    final difference = now.difference(time);

    // Same day
    if (now.day == time.day &&
        now.month == time.month &&
        now.year == time.year) {
      final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
      final minute = time.minute.toString().padLeft(2, '0');
      final period = time.hour >= 12 ? "PM" : "AM";
      return "$hour:$minute $period";
    }

    // Yesterday
    final yesterday = now.subtract(const Duration(days: 1));
    if (yesterday.day == time.day &&
        yesterday.month == time.month &&
        yesterday.year == time.year) {
      return "Yesterday";
    }

    // Within 7 days → weekday
    if (difference.inDays < 7) {
      const days = [
        "Mon",
        "Tue",
        "Wed",
        "Thu",
        "Fri",
        "Sat",
        "Sun"
      ];
      return days[time.weekday - 1];
    }

    // Older
    return "${time.day}/${time.month}/${time.year}";
  }

  Widget _buildUnreadBadge() {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: kButtonColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        chat.unreadCount.toString(),
        style: const TextStyle(
          fontSize: 11,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPinBackground() {
    return Container(
      color: Colors.orange,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 20),
      child: const Icon(Icons.push_pin, color: Colors.white),
    );
  }

  Widget _buildArchiveBackground() {
    return Container(
      color: Colors.blueGrey,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: const Icon(Icons.archive, color: Colors.white),
    );
  }

  void _showAvatarDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          title: Text(chat.name, style: TextStyle(color: Colors.white),),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text("View Picture", style: TextStyle(color: Colors.white),),
                onTap: onViewPicture,
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text("View Profile", style: TextStyle(color: Colors.white),),
                onTap: onViewProfile,
              ),
            ],
          ),
        );
      },
    );
  }
}
