import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// =======================
/// COLORS
/// =======================

/// Scaffold background
const Color scaffoldBgColor = Color(0xFF0F172A);

/// Header / other user name
const Color chatHeaderNameColor = Color(0xFF177E85);

/// Message bubbles
const Color myMessageBubbleColor = Color(0xFF1F8A70);
const Color otherMessageBubbleColor = Color(0xFF1E293B);

/// Message text
const Color myMessageTextColor = Color(0xFFE5E7EB);
const Color otherMessageTextColor = Color(0xFFE2E8F0);

/// Timestamp text
const Color timeTextColor = Color(0xFFCBD5E1);

/// Date separator
const Color dateSeparatorBgColor = Color(0xFF1E293B);
const Color dateSeparatorTextColor = Color(0xFF94A3B8);

/// Message status indicators
const Color messageStatusGrey = Color(0xFF94A3B8);
const Color messageStatusReadBlue = Color(0xFF38BDF8);


/// =======================
/// FONT STYLES
/// =======================

/// Message text (inside bubble)
final TextStyle messageTextStyle = GoogleFonts.inter(
  fontSize: 15.5,
  fontWeight: FontWeight.w400,
  color: myMessageTextColor,
);

final TextStyle otherMessageTextStyle = GoogleFonts.inter(
  fontSize: 15.5,
  fontWeight: FontWeight.w400,
  color: otherMessageTextColor,
);

/// Timestamp (inside bubble)
final TextStyle timeTextStyle = GoogleFonts.inter(
  fontSize: 11,
  fontWeight: FontWeight.w500,
  color: timeTextColor,
);

/// Date separator text
final TextStyle dateSeparatorTextStyle = GoogleFonts.inter(
  fontSize: 12,
  fontWeight: FontWeight.w600,
  color: dateSeparatorTextColor,
);

/// Header / username
final TextStyle chatHeaderNameTextStyle = GoogleFonts.inter(
  fontSize: 17,
  fontWeight: FontWeight.w600,
  color: chatHeaderNameColor,
);


/// =======================
/// ICON SIZES
/// =======================

const double sendingIconSize = 14;
const double sentIconSize = 15;
const double deliveredIconSize = 16;
const double readIconSize = 16;


/// =======================
/// SPACING
/// =======================

const double bubbleVerticalMargin = 6;
const double bubbleHorizontalMargin = 10;

const EdgeInsets bubblePadding =
EdgeInsets.fromLTRB(12, 8, 8, 6);

const double spaceBetweenTextAndMeta = 4;


/// =======================
/// BORDER RADIUS
/// =======================

BorderRadius messageBubbleRadius({required bool isMe}) {
  return BorderRadius.only(
    topLeft: const Radius.circular(16),
    topRight: const Radius.circular(16),
    bottomLeft:
    isMe ? const Radius.circular(16) : const Radius.circular(4),
    bottomRight:
    isMe ? const Radius.circular(4) : const Radius.circular(16),
  );
}


const kInputTextStyle = TextStyle(
  fontSize: 17,
  color: Colors.white,
);

double kServiceIconSize = 20;

const kMessageTextFieldDecoration = InputDecoration(
  contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 5),
  hintText: 'Type your message here...',
  border: InputBorder.none,
  focusedBorder: InputBorder.none,

);
const kApiKey = '1926bce2b6b4767b41cf389853a8357d';

const kSecretKey = "SK_650dac64b78bc29e104f372fa7f4b3477fbdccd7f82";
const kPublicKey = "PK_887a0b5432b0d4c1f8ffa7ab65f8737df4255f1b861";

const kTopAppbars = TextStyle(
  color: Colors.white,
  fontWeight: FontWeight.w900,
  fontSize: 17,
  letterSpacing: 1.2
);

const kButtonColor = Color(0xFF21D3ED);


const kMoneyStyle = TextStyle(
  color: Colors.white,
  fontSize: 14,
  fontWeight: FontWeight.w900,
);

TextStyle kTitle = GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 8);

const kCardColor = Color(0xFF1E293B);

const kWarning = Color(0xFFF45F1A);

const kWalletStyle = TextStyle(
  color: Colors.white70,
  fontSize: 14,
  fontWeight: FontWeight.w700,
);
const kNaira = '₦';

TextStyle kAlertTitle = GoogleFonts.raleway(fontSize: 14,
    fontWeight: FontWeight.w700, color: Colors.white);

TextStyle kAlertContent = GoogleFonts.raleway(fontSize: 12,
    fontWeight: FontWeight.w400);

const kErrorBackground = Color(0xFF1E293B);

const kErrorIconColor = Colors.redAccent;

TextStyle kAccountHeaderStyle = GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: Colors.white
);

TextStyle kSetting = GoogleFonts.inter(
    fontWeight: FontWeight.w600,
    fontSize: 15,
    color: Colors.white54
);

const kIconColor = Color(0xFF21D3ED);

TextStyle kConfirmationKey = GoogleFonts.inter(
    fontWeight: FontWeight.w700,
    fontSize: 13,
    color: Colors.white70
);

TextStyle kConfirmationValue = GoogleFonts.inter(
    fontWeight: FontWeight.w700,
    fontSize: 14,
    color: Colors.white
);

const kAiHeading = TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 18,
    color: Colors.white
);

const kUsernameStyle = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.w900,
    fontSize: 20
);


final kWelcomeStyle = GoogleFonts.roboto(
  // color: Colors.grey[600],
  color: Color(0xFF0F172A),
  fontSize: 13,
  fontWeight: FontWeight.w600,
);

const kMessageContainerDecoration = BoxDecoration(
  // border: Border(
  //   top: BorderSide(color: Colors.lightBlueAccent, width: 2.0),
  // ),
);

TextStyle kExpenseStyle = GoogleFonts.inter(
  color: Colors.white,
  fontSize: 20,
  fontWeight: FontWeight.w700,
);

final kFormatter = NumberFormat('#,##0.00');
final kFormatterNo = NumberFormat('#,##0');

const kSendButtonTextStyle = TextStyle(
  color: Colors.lightBlueAccent,
  fontWeight: FontWeight.bold,
  fontSize: 18.0,
);