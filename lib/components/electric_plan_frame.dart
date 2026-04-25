import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constraints/constants.dart';

class ElectricPlanFrame extends StatelessWidget {

  const ElectricPlanFrame({super.key, required this.amount,
     required this.onTap, this.cashBack, required this.isTap});

  final double amount;
  final Function() onTap;
  final String? cashBack;
  final bool isTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 70,
            decoration: BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(5), 
              border: isTap ? Border.all(
                  color: kIconColor
              ) : Border(),
                boxShadow: [BoxShadow(color: Color(0xFF177E85).withOpacity(0.4),
                    blurRadius: 4, spreadRadius: 1, offset: Offset(0, 2))],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(kNaira, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10),),
                    Text(kFormatter.format(amount), style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w900,),)
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('pay', style: GoogleFonts.poppins(fontSize: 8,
                        fontWeight: FontWeight.w900, color: Colors.white54),),
                    SizedBox(width: 5,),
                    Text(kNaira, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.pink),),
                    Text(kFormatter.format(amount - double.parse(cashBack!)),
                      style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.pink),)
                  ],
                ),
              ],
            )
          ),
          SizedBox(height: 2,),
          if (isTap)
          Positioned(
            right: 1,
              child: Icon(Icons.check_circle, size: 15, color: kIconColor,)
          )
        ],
      ),
    );
  }
}
