import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../constraints/constants.dart';

class ServiceFrame extends StatelessWidget {

  const ServiceFrame({super.key,
    required this.title, required this.icon, required this.onTap, required this.isNew,
    this.titleFont, this.backgroundColor, this.iconColor});

  final String title;
  final FaIconData icon;
  final Function() onTap;
  final bool isNew;
  final double? titleFont;
  final Color? backgroundColor;
  final Color? iconColor;


  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.all(10),
      child:isNew ? Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: onTap,
                child: Card(
                  color:backgroundColor ?? Color(0xFF177E85),
                  elevation: 2,
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: backgroundColor ??Color(0xFF177E85),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: FaIcon(icon,
                      color: iconColor ?? Colors.white, size: kServiceIconSize),
                  ),
                ),
              ),
              SizedBox(height: 7,),
              Text(title,
                style: kTitle.copyWith(color: Colors.white70,
                    fontFamily: 'DejaVu Sans', fontSize: 7), textAlign: TextAlign.center,)
            ],
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              alignment: Alignment.topRight,
              padding: EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                  color: Colors.pink,
                  borderRadius: BorderRadius.circular(5)
              ),
              child: Text('NEW', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),),
            ),
          ),
        ],
      ) : Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: onTap,
            child: Card(
              color: backgroundColor ?? Color(0xFF177E85),
              elevation: 0,
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: backgroundColor ??Color(0xFF177E85),
                  borderRadius: BorderRadius.circular(16),

                ),
                child:  FaIcon(icon,
                    color: iconColor ?? Colors.white,),
              ),
            ),
          ),
          SizedBox(height: 7,),
          Text(title,
            style: kTitle.copyWith(color: Colors.white70, fontFamily: 'DejaVu Sans', fontSize: titleFont ?? 7), textAlign: TextAlign.center,)
        ],
      ),
    );
  }
}
