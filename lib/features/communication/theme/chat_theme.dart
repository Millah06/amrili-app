import 'package:flutter/material.dart';

/// Central design tokens for the chat feature.
///
/// Phase 2: a single source of truth for the polished dark + teal look so the
/// chat list, conversation and input bar stay visually consistent. Keep new
/// chat UI referencing these instead of scattering hex codes.
class ChatTheme {
  ChatTheme._();

  // ── Surfaces ────────────────────────────────────────────────
  static const Color scaffold = Color(0xFF0F172A); // app background (navy)
  static const Color surface = Color(0xFF1E293B); // cards / app bar / received bubble
  static const Color surfaceHigh = Color(0xFF111827); // sheets / deepest layer
  static const Color inputField = Color(0xFF1E293B);

  // ── Brand / accents ─────────────────────────────────────────
  static const Color brand = Color(0xFF177E85); // primary teal (badges, accents)
  static const Color brandBright = Color(0xFF21D3ED); // bright cyan (CTAs)
  static const Color sentBubble = Color(0xFF1F8A70); // my message bubble (teal-green)
  static const Color receivedBubble = Color(0xFF1E293B);
  static const Color online = Color(0xFF22C55E);
  static const Color readTick = Color(0xFF38BDF8);

  // ── Text ────────────────────────────────────────────────────
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color textMuted = Colors.white38;
  static const Color textFaint = Colors.white24;

  // ── Geometry ────────────────────────────────────────────────
  static const double bubbleRadius = 20; // Telegram-style fully-rounded
  static const double sheetRadius = 28;
  static const double avatarSize = 50;

  static const EdgeInsets bubblePadding =
      EdgeInsets.symmetric(horizontal: 14, vertical: 9);
  static const EdgeInsets screenHPad = EdgeInsets.symmetric(horizontal: 16);

  // ── Hairlines / dividers ────────────────────────────────────
  static Color get hairline => Colors.white.withValues(alpha: 0.06);

  // ── Reusable decorations ────────────────────────────────────
  static BoxDecoration bubbleDecoration({required bool isMe}) => BoxDecoration(
        color: isMe ? sentBubble : receivedBubble,
        borderRadius: BorderRadius.circular(bubbleRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      );
}
