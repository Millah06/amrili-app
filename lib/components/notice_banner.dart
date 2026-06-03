import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:marquee/marquee.dart';

class NoticeBanner extends StatelessWidget {
  final String noticeMessage;
  final VoidCallback? onClose;
  final bool ? isGift;

  const NoticeBanner({
    super.key,
    required this.noticeMessage,
    this.onClose,
    this.isGift,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 25,
      decoration: BoxDecoration(
        color: Colors.pink,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          // Marquee expands to fill available space
          Expanded(
            child: Marquee(
              text:
              isGift  ?? false ? noticeMessage : '$noticeMessage service is currently unavailable. Please try again later.',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 9,
              ),
              scrollAxis: Axis.horizontal,
              crossAxisAlignment: CrossAxisAlignment.center,
              blankSpace: 50.0,
              velocity: 40.0,
              pauseAfterRound: const Duration(seconds: 1),
              startPadding: 10.0,
            ),
          ),
          // Cancel button at the end
          GestureDetector(
            // padding: EdgeInsets.zero,
            // constraints: const BoxConstraints(),
            onTap: onClose,
            // padding: EdgeInsets.zero,
            // constraints: const BoxConstraints(),
            child: Padding(
              padding: const EdgeInsets.only(right: 4.0, left: 4),
              child: Icon(Icons.cancel_rounded, color: Colors.black, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

