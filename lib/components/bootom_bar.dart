
import 'dart:async';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/auth/guest_helper.dart';
import '../features/bottom_navigation/chat_screen.dart';
import '../features/bottom_navigation/profile_screen.dart';
import '../features/bottom_navigation/services_screen.dart';
import '../features/bottom_navigation/feed_screen.dart';
import '../features/bottom_navigation/wallet_screen.dart';
import '../shared/widgets/auth_gate_bottom_sheet.dart';


class BottomBar extends StatefulWidget {

  final Function(bool isScrollingDown)? onScrollDirectionChanged;

  const BottomBar({super.key, this.onScrollDirectionChanged});

  @override
  State<BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> {

  late List<Widget> screens;

  Key _bottomNavKey = UniqueKey();

  final PageController _pageController = PageController();

  bool _isBottomBarVisible = true;

  void _hideBottomBar() {
    if (_isBottomBarVisible) {
      setState(() => _isBottomBarVisible = false);
    }
  }

  void _showBottomBar() {
    if (!_isBottomBarVisible) {
      setState(() => _isBottomBarVisible = true);
    }
  }


  int selectedIndex = 0;
  int lastAllowedIndex = 0;


  void _onPageChange(int index) {

    if (index > 2  && GuestHelper.isGuest) {

      // instantly move back
      _pageController.jumpToPage(lastAllowedIndex);

      // reset selected tab
      setState(() {
        selectedIndex = lastAllowedIndex;
        _bottomNavKey = UniqueKey();
      });

      AuthGateBottomSheet.show(
        context,
        reason: 'access ${buildReason(index)}',
      );

      return;
    }

    setState(() {
      selectedIndex = index;
      lastAllowedIndex = index;
      if (!_isBottomBarVisible) {
        _isBottomBarVisible = true;
      }
    });
  }

  String buildReason(int index) {
    switch (index) {
      case 1:
       return 'messages';

      case 2:
         return 'services';

      case 3:
        return 'wallet';

      case 4:
        return 'profile';

      default:
        return 'marketplace';
    }
  }

  void _onItemTapped(int indexSelected) {

    if (indexSelected > 2  && GuestHelper.isGuest) {

      // rebuild navbar back to original state
      setState(() {
        selectedIndex = lastAllowedIndex;
        _bottomNavKey = UniqueKey();
      });

      AuthGateBottomSheet.show(
        context,
        reason: 'access ${buildReason(indexSelected)}',
      );

      return;
    }

    setState(() {
      selectedIndex = indexSelected;
      lastAllowedIndex = indexSelected;
    });

    _pageController.jumpToPage(indexSelected);
  }


  Color selectedColor = Color(0xFF6F7E90);

  @override
  void initState() {
    super.initState();

    screens = [
      FeedScreen(
        onScrollDirectionChanged: _onScrollChange
      ),
      const Messages(),
      const HomeScreen(),
      const WalletScreen(),
      const ProfileScreen(),
    ];
  }

  Timer? _scrollDebounce;

  void _onScrollChange(bool isScrollingDown) {
    _scrollDebounce?.cancel();
    _scrollDebounce = Timer(const Duration(milliseconds: 100), () {
      if (isScrollingDown) {
        _hideBottomBar();
      } else {
        _showBottomBar();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:  PageView(
        controller: _pageController,
        onPageChanged: _onPageChange,
        physics: const BouncingScrollPhysics(),
        children: screens,
      ),
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: _isBottomBarVisible ? 60 : 0,
        child: Wrap(
          children: [
            if (_isBottomBarVisible) _bottomNavigationBar(),
          ],
        ),
      ),
    );
  }

  CurvedNavigationBar _bottomNavigationBar () {
    return CurvedNavigationBar(
        color: Color(0xFF334155),
        key: _bottomNavKey,
        backgroundColor: Color(0xFF0F172A),
        animationCurve: Curves.decelerate,
        height: 60,
        index: selectedIndex,
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
                  FaIcon(FontAwesomeIcons.compass,
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
                  FaIcon(FontAwesomeIcons.message,
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
                  FaIcon(FontAwesomeIcons.layerGroup,
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
                  FaIcon(FontAwesomeIcons.wallet,
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
                  FaIcon(FontAwesomeIcons.circleUser,
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