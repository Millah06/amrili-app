
import 'package:everywhere/constraints/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class PinEntryScreen extends StatefulWidget {
  final Function(String) onCompleted;
  final VoidCallback onForgotPin;
  final VoidCallback onBiometricPressed;

  const PinEntryScreen({
    super.key,
    required this.onCompleted,
    required this.onForgotPin,
    required this.onBiometricPressed,
  });

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
  String pin = '';
  int? currentIndex;

  void _handleTap(String digit) {
    if (pin.length < 4) {
      setState(() {
        pin += digit;
        currentIndex = pin.length - 1;
      });
      if (pin.length == 4) {
        Future.delayed(const Duration(milliseconds: 150), () {
          widget.onCompleted(pin);
        });
      }
    }
  }

  void _handleBackspace() {
    if (pin.isNotEmpty) {
      setState(() {
        pin = pin.substring(0, pin.length - 1);
        currentIndex = pin.length - 1;
      });
    }
  }

  Widget _buildPinDots() {

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        bool filled = index < pin.length;
        bool isSelected = currentIndex == index;
        return Container(
          height: 42,
          padding: EdgeInsets.all(5),
          margin: EdgeInsets.only(left: 4, right: 4),
          decoration: BoxDecoration(
            border: Border.all(
              width: 1.5,
              color: isSelected ? Color(0xFF21D3ED) : filled ? Colors.white : Colors.white54,
            ),
            borderRadius: BorderRadius.circular(10)
          ),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // color: filled ? Colors.white : Colors.grey[700],
              color: isSelected ? Color(0xFF21D3ED) : filled ? Colors.white : Color(0xFF0F172A),
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(height: 0),
          Text(
            "Enter 4-digit PIN",
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          const SizedBox(height: 5),
          _buildPinDots(),
          const SizedBox(height: 5),
          GestureDetector(
            onTap: widget.onForgotPin,
            child: Text(
              "Forgot PIN?",
              style: GoogleFonts.inter(
                fontSize: 14,
                color: kButtonColor,
                fontWeight: FontWeight.w900,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          CustomPinKeyboard(
            onKeyTap: _handleTap,
            onBackspace: _handleBackspace,
            onBiometric: widget.onBiometricPressed,
          ),
          const SizedBox(height: 0),
        ],
      ),
    );
  }
}

class CustomPinKeyboard extends StatelessWidget {
  final Function(String) onKeyTap;
  final VoidCallback onBackspace;
  final VoidCallback onBiometric;

  const CustomPinKeyboard({
    super.key,
    required this.onKeyTap,
    required this.onBackspace,
    required this.onBiometric,
  });

  @override
  Widget build(BuildContext context) {
    List<List<String>> keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['face', '0', '←'],
    ];

    return Container(
      width: double.infinity,
      color:  Colors.black38,
      padding: EdgeInsets.only(left: 5, right: 5, bottom: 5),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image(image: AssetImage('images/eraser.png'), height: 18,
                  fit: BoxFit.cover, width: 18,),
                SizedBox(width: 10,),
                Text('NexPay Secure Numeric Keyboard', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900),),
              ],
            ),
          ),
          Divider(indent: 50, endIndent: 50, color: Colors.white54, thickness: 0.5,),
          Column(
              children: keys.map((row) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: row.map((key) {
                    bool isZero = key == '0';
                    bool isBackspace = key == '←';
                    bool isBiometric = key == 'face';

                    return Expanded(
                      flex: isZero ? 2 : 1,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            if (isBackspace) {
                              onBackspace();
                            } else if (isBiometric) {
                              onBiometric();
                            } else {
                              onKeyTap(key);
                            }
                          },
                          child: Container(
                            height: 45,
                            decoration: BoxDecoration(
                              color: kCardColor,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black38,
                                  blurRadius: 4,
                                  offset: Offset(2, 2),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: isBackspace
                                ? const Icon(Icons.backspace_outlined, color: Colors.white)
                                : isBiometric
                                ? const Icon(Icons.fingerprint, color: Colors.white)
                                : Text(
                              key,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                  fontFamily: 'DejaVu Sans'
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              }).toList(),
          ),
        ],
      ),
    );
  }
}