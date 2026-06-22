import 'package:flutter/material.dart';

import '../theme/chat_theme.dart';

/// A celebratory bubble for a gift message: large emoji, name, coin amount.
class GiftBubble extends StatelessWidget {
  const GiftBubble({
    super.key,
    required this.emoji,
    required this.name,
    required this.coins,
    required this.isMe,
    required this.time,
  });

  final String emoji;
  final String name;
  final int coins;
  final bool isMe;
  final String time;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        constraints: const BoxConstraints(maxWidth: 220),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isMe
                ? [const Color(0xFFF59E0B), const Color(0xFFEA8A00)]
                : [const Color(0xFF7C3AED), const Color(0xFF5B21B6)],
          ),
          borderRadius: BorderRadius.circular(ChatTheme.bubbleRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 44)),
            const SizedBox(height: 6),
            Text(
              isMe ? 'You sent a $name' : 'Sent you a $name',
              textAlign: TextAlign.center,
              style: text.bodyMedium
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on_rounded,
                    size: 14, color: Colors.white),
                const SizedBox(width: 4),
                Text('$coins coins',
                    style: text.labelSmall?.copyWith(color: Colors.white)),
              ],
            ),
            const SizedBox(height: 4),
            Text(time,
                style: text.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.7), fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
