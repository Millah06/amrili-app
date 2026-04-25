import 'package:everywhere/components/notice_banner.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../components/cached_image.dart';
import '../../components/edit2.dart';

import 'package:carousel_slider/carousel_slider.dart';

class TemplateSelectionScreen extends StatelessWidget {

  final String productName;
  final String amount;
  final String sender;
  final String recipient;
  final String phoneNumber;


  // final List<String> featuredTemplates = [
  //   'images/appreciation/photo1.jpeg',
  //   'images/birthday/photo2.jpeg',
  //   'images/christmas/photo3.jpeg',
  //   'images/eid/photo4.jpeg',
  //   'images/friendship/photo5.jpeg',
  //   'images/graduation/photo6.jpeg',
  //   'images/love/photo7.jpeg',
  //   'images/new year/photo2.jpeg',
  //   'images/valentine/photo4.jpeg',
  // ];

  final String baseURL = 'https://github.com/Millah06/my_app_images/blob/'
      'eed5f1c1a69cae5e18d2222c13736988c7ee0633/appreciation/photo1.jpeg';

  // final Map<String, List<String>> categories = {
  //   'Birthday 🎂': [
  //     'images/birthday/photo1.jpeg',
  //     'images/birthday/photo2.jpeg',
  //     'images/birthday/photo3.jpeg',
  //     'images/birthday/photo4.jpeg',
  //     'images/birthday/photo5.jpeg',
  //     'images/birthday/photo6.jpeg',
  //     'images/birthday/photo7.jpeg',
  //     'images/birthday/photo8.jpeg',
  //   ],
  //   'Romantic/ Love 💝': [
  //     'images/love/photo1.jpeg',
  //     'images/love/photo2.jpeg',
  //     'images/love/photo3.jpeg',
  //     'images/love/photo4.jpeg',
  //     'images/love/photo5.jpeg',
  //     'images/love/photo6.jpeg',
  //     'images/love/photo7.jpeg',
  //   ],
  //   'Eid 🕌': [
  //     'images/eid/photo1.jpeg',
  //     'images/eid/photo2.jpeg',
  //     'images/eid/photo3.jpeg',
  //     'images/eid/photo4.jpeg',
  //     'images/eid/photo5.jpeg',
  //     'images/eid/photo6.jpeg',
  //     'images/eid/photo7.jpeg',
  //     'images/eid/photo8.jpeg',
  //     'images/eid/photo9.jpeg',
  //     'images/eid/photo10.jpeg',
  //     'images/eid/photo11.jpeg',
  //     'images/eid/photo12.jpeg',
  //     'images/eid/photo13.jpeg',
  //     'images/eid/photo14.jpeg',
  //
  //   ],
  //   'Christmas 🎄': [
  //     'images/christmas/photo1.jpeg',
  //     'images/christmas/photo2.jpeg',
  //     'images/christmas/photo3.jpeg',
  //     'images/christmas/photo4.jpeg',
  //     'images/christmas/photo5.jpeg',
  //     'images/christmas/photo6.jpeg',
  //     'images/christmas/photo7.jpeg',
  //   ],
  //   'New Year 🗽': [
  //     'images/new year/photo1.jpeg',
  //     'images/new year/photo2.jpeg',
  //     'images/new year/photo3.jpeg',
  //     'images/new year/photo4.jpeg',
  //   ],
  //   'Friendship 🤝': [
  //     'images/friendship/photo1.jpeg',
  //     'images/friendship/photo2.jpeg',
  //     'images/friendship/photo3.jpeg',
  //     'images/friendship/photo4.jpeg',
  //     'images/friendship/photo5.jpeg',
  //     'images/friendship/photo6.jpeg',
  //     'images/friendship/photo7.jpeg',
  //     'images/friendship/photo8.jpeg',
  //     'images/friendship/photo9.jpeg',
  //     'images/friendship/photo10.jpeg',
  //     'images/friendship/photo11.jpeg',
  //     'images/friendship/photo12.jpeg',
  //     'images/friendship/photo13.jpeg',
  //     'images/friendship/photo14.jpeg',
  //     'images/friendship/photo15.jpeg',
  //   ],
  //   'Appreciation 🙏': [
  //     'images/appreciation/photo1.jpeg',
  //     'images/appreciation/photo2.jpeg',
  //     'images/appreciation/photo3.jpeg',
  //     'images/appreciation/photo4.jpeg',
  //     'images/appreciation/photo5.jpeg',
  //     'images/appreciation/photo6.jpeg',
  //     'images/appreciation/photo7.jpeg',
  //     'images/appreciation/photo8.jpeg',
  //     'images/appreciation/photo9.jpeg',
  //     'images/appreciation/photo10.jpeg',
  //     'images/appreciation/photo11.jpeg',
  //     'images/appreciation/photo12.jpeg',
  //     'images/appreciation/photo13.jpeg',
  //   ],
  //   'Valentine 💝': [
  //     'images/valentine/photo1.jpeg',
  //     'images/valentine/photo2.jpeg',
  //     'images/valentine/photo3.jpeg',
  //     'images/valentine/photo4.jpeg',
  //     'images/valentine/photo5.jpeg',
  //     'images/valentine/photo6.jpeg',
  //     'images/valentine/photo7.jpeg',
  //     'images/valentine/photo8.jpeg',
  //   ],
  //   'Graduation 🎓': [
  //     'images/graduation/photo1.jpeg',
  //     'images/graduation/photo2.jpeg',
  //     'images/graduation/photo3.jpeg',
  //     'images/graduation/photo4.jpeg',
  //     'images/graduation/photo5.jpeg',
  //     'images/graduation/photo6.jpeg',
  //     'images/graduation/photo7.jpeg',
  //     'images/graduation/photo8.jpeg',
  //   ],
  //   'Get Well Soon ❤️‍🩹': [
  //     'images/ai.png',
  //     'images/eraser.png',
  //     'images/ai.png',
  //     'images/eraser.png',
  //     'images/profile.png',
  //     'images/wallet.jpg',
  //     'images/profile.png',
  //     'images/wallet.jpg',
  //   ],
  // };

  // final Map<String, List<String>> categories = {
  //   'Birthday 🎂': [
  //     'https://raw.githubusercontent.com/Millah06/my_app_images/main/appreciation/photo1.jpeg',
  //     'https://raw.githubusercontent.com/Millah06/my_app_images/main/appreciation/photo1.jpeg',
  //     'https://raw.githubusercontent.com/Millah06/my_app_images/main/appreciation/photo1.jpeg',
  //     'https://raw.githubusercontent.com/Millah06/my_app_images/main/appreciation/photo1.jpeg',
  //
  //   ],
  //   'Romantic/ Love 💝': [
  //     'https://github.com/Millah06/my_app_images/blob/'
  //         'eed5f1c1a69cae5e18d2222c13736988c7ee0633/appreciation/photo1.jpeg',
  //     'https://github.com/Millah06/my_app_images/blob/'
  //         'eed5f1c1a69cae5e18d2222c13736988c7ee0633/appreciation/photo1.jpeg',
  //     'https://github.com/Millah06/my_app_images/blob/'
  //         'eed5f1c1a69cae5e18d2222c13736988c7ee0633/appreciation/photo1.jpeg',
  //     'https://github.com/Millah06/my_app_images/blob/'
  //         'eed5f1c1a69cae5e18d2222c13736988c7ee0633/appreciation/photo1.jpeg',
  //     'https://github.com/Millah06/my_app_images/blob/'
  //         'eed5f1c1a69cae5e18d2222c13736988c7ee0633/appreciation/photo1.jpeg'
  //   ],
  //   'Eid 🕌': [
  //     'https://github.com/Millah06/my_app_images/blob/'
  //         'eed5f1c1a69cae5e18d2222c13736988c7ee0633/appreciation/photo1.jpeg',
  //     'https://github.com/Millah06/my_app_images/blob/'
  //         'eed5f1c1a69cae5e18d2222c13736988c7ee0633/appreciation/photo1.jpeg',
  //     'https://github.com/Millah06/my_app_images/blob/'
  //         'eed5f1c1a69cae5e18d2222c13736988c7ee0633/appreciation/photo1.jpeg',
  //     'https://github.com/Millah06/my_app_images/blob/'
  //         'eed5f1c1a69cae5e18d2222c13736988c7ee0633/appreciation/photo1.jpeg',
  //     'https://github.com/Millah06/my_app_images/blob/'
  //         'eed5f1c1a69cae5e18d2222c13736988c7ee0633/appreciation/photo1.jpeg'
  //
  //   ],
  //   'Christmas 🎄': [
  //     'https://github.com/Millah06/my_app_images/blob/'
  //         'eed5f1c1a69cae5e18d2222c13736988c7ee0633/appreciation/photo1.jpeg',
  //     'https://github.com/Millah06/my_app_images/blob/'
  //         'eed5f1c1a69cae5e18d2222c13736988c7ee0633/appreciation/photo1.jpeg',
  //     'https://github.com/Millah06/my_app_images/blob/'
  //         'eed5f1c1a69cae5e18d2222c13736988c7ee0633/appreciation/photo1.jpeg',
  //     'https://github.com/Millah06/my_app_images/blob/'
  //         'eed5f1c1a69cae5e18d2222c13736988c7ee0633/appreciation/photo1.jpeg',
  //     'https://github.com/Millah06/my_app_images/blob/'
  //         'eed5f1c1a69cae5e18d2222c13736988c7ee0633/appreciation/photo1.jpeg'
  //   ],
  //   'New Year 🗽': [
  //
  //     'https://github.com/Millah06/my_app_images/blob/'
  //         'eed5f1c1a69cae5e18d2222c13736988c7ee0633/appreciation/photo1.jpeg',
  //     'https://github.com/Millah06/my_app_images/blob/'
  //         'eed5f1c1a69cae5e18d2222c13736988c7ee0633/appreciation/photo1.jpeg',
  //     'https://github.com/Millah06/my_app_images/blob/'
  //         'eed5f1c1a69cae5e18d2222c13736988c7ee0633/appreciation/photo1.jpeg',
  //     'https://github.com/Millah06/my_app_images/blob/'
  //         'eed5f1c1a69cae5e18d2222c13736988c7ee0633/appreciation/photo1.jpeg',
  //     'https://github.com/Millah06/my_app_images/blob/'
  //         'eed5f1c1a69cae5e18d2222c13736988c7ee0633/appreciation/photo1.jpeg'
  //   ],
  //   'Friendship 🤝': [
  //     'https://github.com/Millah06/my_app_images/blob/'
  //         'eed5f1c1a69cae5e18d2222c13736988c7ee0633/appreciation/photo1.jpeg',
  //     'https://github.com/Millah06/my_app_images/blob/'
  //         'eed5f1c1a69cae5e18d2222c13736988c7ee0633/appreciation/photo1.jpeg',
  //     'https://github.com/Millah06/my_app_images/blob/'
  //         'eed5f1c1a69cae5e18d2222c13736988c7ee0633/appreciation/photo1.jpeg',
  //     'https://github.com/Millah06/my_app_images/blob/'
  //         'eed5f1c1a69cae5e18d2222c13736988c7ee0633/appreciation/photo1.jpeg',
  //     'https://github.com/Millah06/my_app_images/blob/'
  //         'eed5f1c1a69cae5e18d2222c13736988c7ee0633/appreciation/photo1.jpeg'
  //   ],
  //   'Appreciation 🙏': [
  //     'https://github.com/Millah06/my_app_images/blob/'
  //         'eed5f1c1a69cae5e18d2222c13736988c7ee0633/appreciation/photo1.jpeg',
  //     'https://github.com/Millah06/my_app_images/blob/'
  //         'eed5f1c1a69cae5e18d2222c13736988c7ee0633/appreciation/photo1.jpeg',
  //     'https://github.com/Millah06/my_app_images/blob/'
  //         'eed5f1c1a69cae5e18d2222c13736988c7ee0633/appreciation/photo1.jpeg',
  //     'https://github.com/Millah06/my_app_images/blob/'
  //         'eed5f1c1a69cae5e18d2222c13736988c7ee0633/appreciation/photo1.jpeg',
  //     'https://github.com/Millah06/my_app_images/blob/'
  //         'eed5f1c1a69cae5e18d2222c13736988c7ee0633/appreciation/photo1.jpeg'
  //   ],
  //   'Valentine 💝': [
  //     'https://github.com/Millah06/my_app_images/blob/'
  //         'eed5f1c1a69cae5e18d2222c13736988c7ee0633/appreciation/photo1.jpeg',
  //     'https://github.com/Millah06/my_app_images/blob/'
  //         'eed5f1c1a69cae5e18d2222c13736988c7ee0633/appreciation/photo1.jpeg',
  //     'https://github.com/Millah06/my_app_images/blob/'
  //         'eed5f1c1a69cae5e18d2222c13736988c7ee0633/appreciation/photo1.jpeg',
  //     'https://github.com/Millah06/my_app_images/blob/'
  //         'eed5f1c1a69cae5e18d2222c13736988c7ee0633/appreciation/photo1.jpeg',
  //     'https://github.com/Millah06/my_app_images/blob/'
  //         'eed5f1c1a69cae5e18d2222c13736988c7ee0633/appreciation/photo1.jpeg'
  //   ],
  //   'Graduation 🎓': [
  //     'https://github.com/Millah06/my_app_images/blob/'
  //         'eed5f1c1a69cae5e18d2222c13736988c7ee0633/appreciation/photo1.jpeg',
  //     'https://github.com/Millah06/my_app_images/blob/'
  //         'eed5f1c1a69cae5e18d2222c13736988c7ee0633/appreciation/photo1.jpeg',
  //     'https://github.com/Millah06/my_app_images/blob/'
  //         'eed5f1c1a69cae5e18d2222c13736988c7ee0633/appreciation/photo1.jpeg',
  //     'https://github.com/Millah06/my_app_images/blob/'
  //         'eed5f1c1a69cae5e18d2222c13736988c7ee0633/appreciation/photo1.jpeg',
  //     'https://github.com/Millah06/my_app_images/blob/'
  //         'eed5f1c1a69cae5e18d2222c13736988c7ee0633/appreciation/photo1.jpeg'
  //   ],
  //   'Get Well Soon ❤️‍🩹': [
  //     'https://github.com/Millah06/my_app_images/blob/'
  //         'eed5f1c1a69cae5e18d2222c13736988c7ee0633/appreciation/photo1.jpeg',
  //     'https://github.com/Millah06/my_app_images/blob/'
  //         'eed5f1c1a69cae5e18d2222c13736988c7ee0633/appreciation/photo1.jpeg',
  //     'https://github.com/Millah06/my_app_images/blob/'
  //         'eed5f1c1a69cae5e18d2222c13736988c7ee0633/appreciation/photo1.jpeg',
  //     'https://github.com/Millah06/my_app_images/blob/'
  //         'eed5f1c1a69cae5e18d2222c13736988c7ee0633/appreciation/photo1.jpeg',
  //     'https://github.com/Millah06/my_app_images/blob/'
  //         'eed5f1c1a69cae5e18d2222c13736988c7ee0633/appreciation/photo1.jpeg'
  //   ],
  // };



  const TemplateSelectionScreen({
    super.key,
    required this.amount,
    required this.sender,
    required this.recipient, required this.productName, required this.phoneNumber,
  });



  @override
  Widget build(BuildContext context) {

    bool userCancelNotice = false;

    List<String> generateImageUrls(String category, int count) {
      return List.generate(count, (index) {
        final i = index + 1;
        return 'https://raw.githubusercontent.com/Millah06/my_app_images/main/$category/photo$i.jpeg';
      });
    }

    final Map<String, List<String>> categories = {
      'Birthday 🎂': generateImageUrls('birthday', 8),
      'Romantic/ Love 💝': generateImageUrls('love', 7),
      'Eid 🕌': generateImageUrls('eid', 14),
      'Christmas 🎄': generateImageUrls('christmas', 7),
      'New Year 🗽': generateImageUrls('new year', 4),
      'Friendship 🤝': generateImageUrls('friendship', 15),
      'Appreciation 🙏': generateImageUrls('appreciation', 13),
      'Valentine 💝': generateImageUrls('valentine', 8),
      'Graduation 🎓': generateImageUrls('graduation', 8),
      'Get Well Soon ❤️‍🩹': generateImageUrls('getwell', 10),
    };
    List<String> featuredTemplates = generateImageUrls('feature', 9);

    return DefaultTabController(
        length: categories.keys.length,
        child: Scaffold(
            // backgroundColor: Colors.white,
            appBar: AppBar(
              title: Text('Choose Frame'),
              // backgroundColor: Colors.black,
              bottom: TabBar(
                tabAlignment: TabAlignment.start,
                isScrollable: true,
                dividerHeight: 0,
                labelColor: Colors.white,
                labelStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w900),
                labelPadding: EdgeInsets.only(right: 30, bottom: 0, left: 10),
                indicatorColor: Color(0xFF21D3ED),
                indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(width: 2, color:  Color(0xFF21D3ED)),
                  insets: EdgeInsets.symmetric(horizontal: 0),
                ),
                tabs: categories.keys.map((e) => Tab(text: e)).toList(),
              ),
              backgroundColor: Color(0xFF0F172A),
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsetsGeometry.only(top: 10),
                  child: NoticeBanner(
                      noticeMessage: 'Note! Once you close this screen, you will be unable to send your gift',
                    isGift: true,
                    onClose: () {

                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    "Featured Styles",
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                CarouselSlider(
                  options: CarouselOptions(
                    height: 160,
                    autoPlay: true,
                    enlargeCenterPage: true,
                    autoPlayInterval: Duration(seconds: 2)
                  ),
                  items: featuredTemplates.map((imgPath) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) =>
                            CustomizationScreen(
                              category: 'Romantic', amount: amount,
                              productType: productName,
                              phoneNumber: phoneNumber, templatePath: imgPath,
                              sender: sender,
                              recipient: sender,
                            )));
                      },
                      child: SizedBox(
                        width: 300,
                        // child: Image.asset(imgPath, fit: BoxFit.cover, width: 300),
                        child: networkTemplate(imgPath),
                      ),
                    );
                  }).toList(),
                ),

                SizedBox(height: 10),

                // TabBarView for categories
                Expanded(
                  child: TabBarView(
                    children: categories.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                          ),
                          itemCount: entry.value.length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) =>
                                    CustomizationScreen(
                                        category: entry.key, amount: amount,
                                      productType: productName,
                                      phoneNumber: phoneNumber,
                                      templatePath: entry.value[index],
                                      sender: sender,
                                      recipient: recipient,
                                    )));
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[900],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: networkTemplate(
                                  entry.value[index],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            ),
        );
    }
}