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
      background: _buildSwipeBackground(
        alignment: Alignment.centerLeft,
        color: const Color(0xFFF97316),
        icon: Icons.push_pin_rounded,
        padding: const EdgeInsets.only(left: 24),
      ),
      secondaryBackground: _buildSwipeBackground(
        alignment: Alignment.centerRight,
        color: const Color(0xFF475569),
        icon: Icons.archive_rounded,
        padding: const EdgeInsets.only(right: 24),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onPin?.call();
        } else {
          onArchive?.call();
        }
        return false;
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: Colors.white.withOpacity(0.04),
          highlightColor: Colors.white.withOpacity(0.03),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _buildAvatar(context),
                const SizedBox(width: 12),
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Name + badges
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      chat.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: chat.unreadCount > 0
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (chat.isOfficial)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(Icons.verified_rounded, size: 14, color: Color(0xFF38BDF8)),
                    ),
                  if (chat.isPinned)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(Icons.push_pin_rounded, size: 13, color: Colors.orange.withOpacity(0.8)),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Time
            Text(
              _formatTime(chat.lastMessageAt),
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: chat.unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                color: chat.unreadCount > 0
                    ? const Color(0xFF2DD4BF)
                    : Colors.white30,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            _buildMessageStatus(),
            if (chat.messageStatus != null) const SizedBox(width: 4),
            Expanded(
              child: chat.isTyping
                  ? _buildTypingIndicator()
                  : Text(
                _lastMessagePreview(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: chat.unreadCount > 0
                      ? Colors.white70
                      : Colors.white30,
                  fontWeight: chat.unreadCount > 0
                      ? FontWeight.w500
                      : FontWeight.normal,
                ),
              ),
            ),
            if (chat.unreadCount > 0) ...[
              const SizedBox(width: 8),
              _buildUnreadBadge(),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      children: [
        const _TypingDots(),
        const SizedBox(width: 6),
        Text(
          'typing',
          style: TextStyle(
            fontSize: 13,
            color: const Color(0xFF2DD4BF).withOpacity(0.8),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAvatarDialog(context),
      child: Stack(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF1E293B),
            ),
            child: ClipOval(
              child: chat.avatarUrl != null
                  ? CachedNetworkImage(
                imageUrl: chat.avatarUrl!,
                fit: BoxFit.cover,
                width: 50,
                height: 50,
                placeholder: (_, __) => _buildAvatarFallback(),
                errorWidget: (_, __, ___) => _buildAvatarFallback(),
              )
                  : _buildAvatarFallback(),
            ),
          ),
          if (chat.isOnline)
            Positioned(
              bottom: 1,
              right: 1,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF111827), width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback() {
    final parts = chat.name.trim().split(' ');
    final initials = parts.length > 1
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : chat.name.isNotEmpty
        ? chat.name[0].toUpperCase()
        : '?';

    // Deterministic color from name
    final colors = [
      const Color(0xFF0D6E7A),
      const Color(0xFF7C3AED),
      const Color(0xFF0369A1),
      const Color(0xFF065F46),
      const Color(0xFF9D174D),
      const Color(0xFF92400E),
    ];
    final color = colors[chat.name.codeUnits.fold(0, (a, b) => a + b) % colors.length];

    return Container(
      color: color.withOpacity(0.6),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageStatus() {
    switch (chat.messageStatus) {
      case MessageStatus.sending:
        return const Icon(Icons.schedule_rounded, size: 13, color: Colors.white24);
      case MessageStatus.sent:
        return const Icon(Icons.check_rounded, size: 15, color: Colors.white30);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all_rounded, size: 15, color: Colors.white30);
      case MessageStatus.read:
        return const Icon(Icons.done_all_rounded, size: 15, color: Color(0xFF38BDF8));
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildUnreadBadge() {
    final count = chat.unreadCount;
    return Container(
      constraints: const BoxConstraints(minWidth: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF177E85),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: const TextStyle(
          fontSize: 11,
          color: Colors.white,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSwipeBackground({
    required Alignment alignment,
    required Color color,
    required IconData icon,
    required EdgeInsetsGeometry padding,
  }) {
    return Container(
      color: color,
      alignment: alignment,
      padding: padding,
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }

  String _lastMessagePreview() {
    switch (chat.lastMessageType) {
      case MessageType.text:   return chat.lastMessage ?? 'No messages yet';
      case MessageType.image:  return '📷  Photo';
      case MessageType.video:  return '🎥  Video';
      case MessageType.voice:  return '🎤  Voice message';
      case MessageType.file:   return '📎  File';
      case MessageType.gif:    return 'GIF';
      case MessageType.system: return chat.lastMessage ?? 'System update';
    }
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final diff = now.difference(time);

    if (now.day == time.day && now.month == time.month && now.year == time.year) {
      final h = time.hour % 12 == 0 ? 12 : time.hour % 12;
      final m = time.minute.toString().padLeft(2, '0');
      return '$h:$m ${time.hour >= 12 ? 'PM' : 'AM'}';
    }

    final yesterday = now.subtract(const Duration(days: 1));
    if (yesterday.day == time.day && yesterday.month == time.month && yesterday.year == time.year) {
      return 'Yesterday';
    }

    if (diff.inDays < 7) {
      return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][time.weekday - 1];
    }

    return '${time.day}/${time.month}/${time.year}';
  }

  void _showAvatarDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Text(
                  chat.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Divider(color: Colors.white10),
              _dialogOption(icon: Icons.image_outlined, label: 'View Picture', onTap: onViewPicture),
              _dialogOption(icon: Icons.person_outline_rounded, label: 'View Profile', onTap: onViewProfile),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dialogOption({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF2DD4BF), size: 20),
            const SizedBox(width: 14),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// Animated typing dots
class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = (_ctrl.value - i * 0.15).clamp(0.0, 1.0);
            final scale = 0.6 + 0.4 * (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.only(right: 3),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2DD4BF),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}