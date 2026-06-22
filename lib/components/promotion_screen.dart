import 'dart:async';
import 'package:everywhere/shared/widgets/net_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

// class PromoCarousel extends StatefulWidget {
//   final List<Map<String, String>> cards; // title, subtitle
//   final Function(int) onTap; // handle tap
//
//   const PromoCarousel({required this.cards, required this.onTap, Key? key}) : super(key: key);
//
//   @override
//   State<PromoCarousel> createState() => _PromoCarouselState();
// }
//
// class _PromoCarouselState extends State<PromoCarousel> {
//   final PageController _pageController = PageController(viewportFraction: 0.95);
//   int _currentIndex = 0;
//   Timer? _autoScrollTimer;
//
//   final List<List<Color>> gradients = [
//     [Color(0xFF6EE7B7), Color(0xFF3B82F6)],
//     [Color(0xFFFDE68A), Color(0xFFF59E0B)],
//     [Color(0xFF93C5FD), Color(0xFF6366F1)],
//     [Color(0xFFFDA4AF), Color(0xFFEC4899)],
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//     _startAutoScroll();
//   }
//
//   void _startAutoScroll() {
//     _autoScrollTimer = Timer.periodic(Duration(seconds: 4), (timer) {
//       if (_pageController.hasClients) {
//         int nextPage = (_currentIndex + 1) % widget.cards.length;
//         _pageController.animateToPage(nextPage,
//             duration: Duration(milliseconds: 500), curve: Curves.easeInOut);
//       }
//     });
//   }
//
//   @override
//   void dispose() {
//     _autoScrollTimer?.cancel();
//     _pageController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: [
//         SizedBox(
//           height: 120,
//           child: PageView.builder(
//             controller: _pageController,
//             itemCount: widget.cards.length,
//             onPageChanged: (index) {
//               setState(() => _currentIndex = index);
//             },
//             itemBuilder: (context, index) {
//               final gradient = gradients[index % gradients.length];
//               final card = widget.cards[index];
//
//               return GestureDetector(
//                 onTap: () => widget.onTap(index),
//                 child: Container(
//                   margin: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       colors: gradient,
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                     ),
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   padding: EdgeInsets.all(16),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Text(card['title']!,
//                           style: TextStyle(
//                               color: Colors.white,
//                               fontSize: 14,
//                               fontWeight: FontWeight.bold)),
//                       SizedBox(height: 8),
//                       Text(card['subtitle']!,
//                           style: TextStyle(color: Colors.white70, fontSize: 14)),
//                       SizedBox(height: 8,),
//                       Center(
//                         child: SmoothPageIndicator(
//                           controller: _pageController,
//                           count: widget.cards.length,
//                           effect: ExpandingDotsEffect(
//                             dotColor: Colors.grey,
//                             activeDotColor: Colors.white,
//                             dotHeight: 6,
//                             dotWidth: 6,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//
//   }
// }


class PromoCarousel extends StatefulWidget {
  const PromoCarousel({super.key});

  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.95);
  int _currentIndex = 0;
  Timer? _autoScrollTimer;

  final List<List<Color>> gradients = [
    [Color(0xFF6EE7B7), Color(0xFF3B82F6)], // green-blue
    [Color(0xFFFDE68A), Color(0xFFF59E0B)], // yellow-orange
    [Color(0xFF93C5FD), Color(0xFF6366F1)], // light-blue-indigo
    [Color(0xFFFDA4AF), Color(0xFFEC4899)], // pink shades
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {

        final contextSize = _pageController.positions.isNotEmpty
                  ? _pageController.positions.first.viewportDimension
                  : 0.0;
        int nextPage =
            (_currentIndex + 1) %(_pageController.positions.first.maxScrollExtent
                ~/ contextSize + 1);
        _pageController.animateToPage(nextPage,
            duration: Duration(milliseconds: 500), curve: Curves.easeInOut);
      }
    });
  }

  // void _startAutoScroll() {
  //   _autoScrollTimer = Timer.periodic(Duration(seconds: 4), (timer) {
  //     if (_pageController.hasClients) {
  //       // Auto-scroll only if we have more than 1 page
  //       final contextSize = _pageController.positions.isNotEmpty
  //           ? _pageController.positions.first.viewportDimension
  //           : 0.0;
  //       if (contextSize > 0) {
  //         _pageController.animateToPage(
  //           (_currentIndex + 1) % (_pageController.positions.first.maxScrollExtent ~/ contextSize + 1),
  //           duration: Duration(milliseconds: 500),
  //           curve: Curves.easeInOut,
  //         );
  //       }
  //     }
  //   });
  // }

  // void _startAutoScroll() {
  //   _autoScrollTimer = Timer.periodic(Duration(seconds: 4), (timer) {
  //     if (!mounted || !_pageController.hasClients) return;
  //
  //     // ✅ Only auto-scroll if more than 1 page
  //     final totalPages = _pageController.positions.first.maxScrollExtent /
  //         _pageController.position.viewportDimension +
  //         1;
  //
  //     if (totalPages > 1) {
  //       int nextPage = (_currentIndex + 1) % totalPages.toInt();
  //       _pageController.animateToPage(
  //         nextPage,
  //         duration: Duration(milliseconds: 500),
  //         curve: Curves.easeInOut,
  //       );
  //     }
  //     });
  // }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // Generate button color based on gradient
  Color getButtonColor(List<Color> gradient) {
    Color base = gradient.first;
    HSLColor hsl = HSLColor.fromColor(base);
    return hsl.withLightness((hsl.lightness + 0.3).clamp(0.0, 1.0)).toColor();
  }

  // Handle dynamic actions
  void handleAction(Map<String, dynamic> card) async {
    final actionType = card['actionType'];
    final actionValue = card['actionValue'];

    if (actionType == 'navigate') {
      Navigator.pushNamed(context, actionValue);
    } else if (actionType == 'web') {
      if (await canLaunchUrl(Uri.parse(actionValue))) {
        await launchUrl(Uri.parse(actionValue),
            mode: LaunchMode.externalApplication);
      }
    } else if (actionType == 'dialog') {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(card['title'],
                    style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Text(card['subtitle'],
                    style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                SizedBox(height: 20),
                Text(actionValue,
                    style: TextStyle(fontSize: 14, color: Colors.black87)),
                SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('promotion_banners')
            .snapshots(), // Real-time updates
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return SizedBox.shrink(); // Hide carousel if no data
          }
          final cards = snapshot.data!.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
          return SizedBox(
            height: 135,
            child: PageView.builder(
              controller: _pageController,
              itemCount: cards.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemBuilder: (context, index) {
                final card = cards[index];
                final gradient =
                gradients[card['gradientIndex'] % gradients.length];
                final buttonColor = getButtonColor(gradient);
                final imageUrl = card['imageUrl']; // optional

                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: gradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                        if (imageUrl != null) ...[
                          NetImage(url: imageUrl as String, fit: BoxFit.cover),
                          const ColoredBox(color: Color(0x4D000000)),
                        ],
                        Padding(
                          padding: const EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(card['title'],
                                      style: GoogleFonts.poppins(
                                          color: Color(0xFF1E293B),
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold)),
                                  GestureDetector(
                                    onTap: () {handleAction(card);},
                                    child: Card(
                                      color: Color(0xFF177E85),
                                      elevation: 4,
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                        decoration: BoxDecoration(
                                            color: buttonColor,
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [BoxShadow(color: Color(0xFF177E85).withOpacity(0.4),
                                                blurRadius: 8, spreadRadius: 1, offset: Offset(0, 4))]
                                        ),
                                        child: Text(
                                          card['buttonText'] ?? 'Explore',
                                          style: TextStyle(
                                              color: Colors.black, fontWeight: FontWeight.w900, fontSize: 10),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 2),
                              Text(card['subtitle'],
                                  style: GoogleFonts.poppins(
                                      color: Color(0xFF1E293B), fontSize: 10, fontWeight: FontWeight.bold)),
                              Spacer(),
                              Center(
                                child: SmoothPageIndicator(
                                  controller: _pageController,
                                  count: cards.length,
                                  effect: ExpandingDotsEffect(
                                    dotColor: Colors.grey,
                                    activeDotColor: Colors.white,
                                    dotHeight: 6,
                                    dotWidth: 6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
          },
        );
    }
}