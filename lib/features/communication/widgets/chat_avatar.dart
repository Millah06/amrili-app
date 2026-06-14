import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Reusable circular avatar: network photo when available, otherwise
/// deterministic initials. Shared by the chat list, conversation header and
/// message-requests screen.
class ChatAvatar extends StatelessWidget {
  const ChatAvatar({
    super.key,
    required this.name,
    this.avatarUrl,
    this.size = 48,
  });

  final String name;
  final String? avatarUrl;
  final double size;

  static const _palette = [
    Color(0xFF0D6E7A),
    Color(0xFF7C3AED),
    Color(0xFF0369A1),
    Color(0xFF065F46),
    Color(0xFF9D174D),
    Color(0xFF92400E),
  ];

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    final initials = parts.isEmpty
        ? '?'
        : parts.length > 1
            ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
            : parts.first[0].toUpperCase();
    final color =
        _palette[name.codeUnits.fold(0, (a, b) => a + b) % _palette.length];

    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.85),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.36,
        ),
      ),
    );

    final url = avatarUrl;
    if (url == null || url.isEmpty) return fallback;

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, __) => fallback,
        errorWidget: (_, __, ___) => fallback,
      ),
    );
  }
}
