
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:everywhere/constraints/constants.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pull_to_reveal_flutter/pull_to_reveal_flutter.dart';

import '../features/bottom_navigation/chats/chat_screen.dart';
import '../features/bottom_navigation/profile/profile_screen.dart';
import '../features/bottom_navigation/services_screen.dart';
import '../features/bottom_navigation/socialFeature/feed_screen.dart';
import '../features/bottom_navigation/wallet/wallet_screen.dart';
import '../shared/widgets/pull_to_reveal.dart';


class BottomBar extends StatefulWidget {
  const BottomBar({super.key});

  @override
  State<BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> {

  final PageController _pageController = PageController();
  final PullToRevealController _pullToRevealController = PullToRevealController();

  int selectedIndex = 0;
  final List<Widget> screens = [
    const FeedScreen(),
    const Messages(),
    const HomeScreen(),
    const WalletScreen(),
    const  ProfileScreen()
  ];

  void _onPageChange(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  void _onItemTapped(int indexSelected) {
    _pageController.jumpToPage(indexSelected);
  }

  Color selectedColor = Color(0xFF6F7E90);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:  PageView(
        controller: _pageController,
        onPageChanged: _onPageChange,
        children: screens,
      ),
      bottomNavigationBar: _bottomNavigationBar(),
    );
  }

  CurvedNavigationBar _bottomNavigationBar () {
    return CurvedNavigationBar(
        color: Color(0xFF334155),

        backgroundColor: Color(0xFF0F172A),
        animationCurve: Curves.decelerate,
        height: 60,
        index: selectedIndex,
        // currentIndex: selectedIndex,
        // // selectedItemColor: Color(0xFFF45F1A) ,
        // selectedItemColor: Colors.white,
        // unselectedItemColor: Color(0xFF6F7E90) ,
        // selectedLabelStyle: TextStyle(color: Colors.white),
        // selectedIconTheme: IconThemeData(size: 25),
        onTap: _onItemTapped,
        items:
        [
          Container(
            margin: EdgeInsets.only(bottom: selectedIndex == 0 ? 0 : 15),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(FontAwesomeIcons.compass,
                    size: selectedIndex == 0 ? 15 : 20,
                    color: selectedIndex == 0 ? Color(0xFF21D3ED) :
                    Colors.white38,),
                  SizedBox(height: 3.5,),
                  Text('Explore', style: GoogleFonts.inter(fontSize: 9,
                      fontWeight: FontWeight.w900, color: selectedIndex == 0 ? Colors.white : Colors.white60),)
                ],
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(bottom: selectedIndex == 1 ? 0 : 14),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(FontAwesomeIcons.message,
                    size: selectedIndex == 1 ? 15 : 20, color: selectedIndex == 1 ? Color(0xFF21D3ED) :
                      Colors.white38),
                  SizedBox(height: 3.5,),
                  Text('Messages',
                  style: GoogleFonts.inter(fontSize: 9,
                      fontWeight: FontWeight.w900, color: selectedIndex == 1 ? Colors.white : Colors.white60)),
                ],
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(bottom: selectedIndex == 2 ? 0 : 15),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(FontAwesomeIcons.layerGroup,
                      size: selectedIndex == 2 ? 15 : 20, color: selectedIndex == 2 ? Color(0xFF21D3ED) :
                      Colors.white38),
                  SizedBox(height: 3.5,),
                  Text('Services',
                    style: GoogleFonts.inter(fontSize: 9,
                        fontWeight: FontWeight.w900,  color: selectedIndex == 2 ? Colors.white : Colors.white60),)
                ],
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(bottom: selectedIndex == 3 ? 0 : 15),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(FontAwesomeIcons.wallet,
                    size: selectedIndex == 3 ? 15 : 20, color: selectedIndex == 3 ? Color(0xFF21D3ED) :
                    Colors.white38,),
                  SizedBox(height: 3.5,),
                  Text('Wallet',
                    style: GoogleFonts.inter(fontSize: 9,
                        fontWeight: FontWeight.w900,  color: selectedIndex == 3 ? Colors.white : Colors.white60),)
                ],
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(bottom: selectedIndex == 4 ? 0 : 15),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(FontAwesomeIcons.circleUser,
                    size: selectedIndex == 4 ? 15 : 20, color: selectedIndex == 4 ? Color(0xFF21D3ED) :
                      Colors.white38),
                  SizedBox(height: 3.5,),
                  Text('Profile', style: GoogleFonts.inter(fontSize: 9,
                      fontWeight: FontWeight.w900,  color: selectedIndex == 4 ? Colors.white : Colors.white60),)
                ],
              ),
            ),
          ),
        ]
    );
  }
}