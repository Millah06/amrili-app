import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:everywhere/components/formatters.dart';
import 'package:everywhere/components/text_field.dart';
import 'package:everywhere/constraints/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../screens/ai_messages.dart';

class CustomizationScreen extends StatefulWidget {

  final String category;
  final String templateColor;
  final String amount;
  final String productType; // Airtime or Data
  final String phoneNumber;
  final String sender;
  final String recipient;
  final String templatePath;

  static String id = 'edit';

  const CustomizationScreen({
    super.key,
    required this.category,
    required this.amount,
    required this.productType,
    required this.phoneNumber,
    this.templateColor = "#F5F5F5",
    required this.templatePath, required this.sender, required this.recipient,
  });

  @override
  State<CustomizationScreen> createState() => _CustomizationScreenState();
}

class _CustomizationScreenState extends State<CustomizationScreen> with TickerProviderStateMixin {


  final GlobalKey _previewKey = GlobalKey();
  List<Color> _bgColor =  [Color(0xFFFBCFE8), Color(0xFFF87171)];
  List<Color> _footer = [Color(0xFF312E81), Color(0xFF1E293B)];
  Color _textColor = Color(0xFF1E293B);
  Color _selectedFooterColor = Colors.white;
  // String _selectedFont = 'Dancing Script';
  String _selectedFont = 'Pacifico';

  int _selectedIndex = 0;

  bool _isReadOnly = true;
  final FocusNode focusNode = FocusNode();

  final List<String> _fonts = [
    'Pacifico',
    'Dancing Script',
    'Roboto',
    'Poppins',
    'Montserrat',
  ];

  final List<List<Color>> bgData = [
    [Colors.black, Colors.white54],
    [Colors.red, Colors.green],
    [Colors.yellow, Colors.indigo],
    [Colors.purple, Colors.orange],
    [Colors.blue, Colors.white54],
    [Colors.pink, Colors.white54],
    [Colors.blueGrey, Colors.black]
  ];
  final TextEditingController _controller = TextEditingController();

  final List<Map<String, dynamic>> colorSet = [
    // 1. Luxury Purple → Magenta | Footer: Deep Indigo → Hot Pink
    {
      "background": [Color(0xFFFBCFE8), Color(0xFFF87171)],
      "textColor": Color(0xFF1E293B),
      "footer": [Color(0xFF312E81), Color(0xFF1E293B)],
      "footerTextColor": Colors.white,
    },
    // 2. Aqua Blue → Teal | Footer: Bold Pink → Deep Purple
    {
      "background": [Color(0xFF06B6D4), Color(0xFF10B981)],
      "textColor": Colors.white,
      "footer": [Color(0xFFEC4899), Color(0xFF6D28D9)],
      "footerTextColor": Colors.white,
    },
    // 3. Sunset Orange → Peach | Footer: Navy → Warm Gold
    {
      "background": [Color(0xFFF97316), Color(0xFFFBBF24)],
      "textColor": Color(0xFF1F2937),
      "footer": [Color(0xFF1E3A8A), Color(0xFFEAB308)],
      "footerTextColor": Colors.white,
    },
    // 4. Royal Blue → Sky | Footer: Amber → Deep Brown
    {
      "background": [Color(0xFF2563EB), Color(0xFF3B82F6)],
      "textColor": Colors.white,
      "footer": [Color(0xFFFACC15), Color(0xFF78350F)],
      "footerTextColor": Color(0xFF1F2937),
    },
    // 5. Deep Pink → Rose | Footer: Emerald → Dark Teal
    {
      "background": [Color(0xFFBE185D), Color(0xFFDB2777)],
      "textColor": Colors.white,
      "footer": [Color(0xFF047857), Color(0xFF064E3B)],
      "footerTextColor": Colors.white,
    },
    // 6. Emerald Green → Mint | Footer: Coral → Deep Red
    {
      "background": [Color(0xFF065F46), Color(0xFF10B981)],
      "textColor": Colors.white,
      "footer": [Color(0xFFFB7185), Color(0xFF991B1B)],
      "footerTextColor": Colors.white,
    },
    // 7. Vibrant Cyan → Electric Blue | Footer: Magenta → Indigo
    {
      "background": [Color(0xFF0891B2), Color(0xFF0EA5E9)],
      "textColor": Colors.white,
      "footer": [Color(0xFFD946EF), Color(0xFF4C1D95)],
      "footerTextColor": Colors.white,
    },
    // 8. Soft Lavender → Pink | Footer: Navy → Golden Yellow
    {
      "background": [Color(0xFF818CF8), Color(0xFFF0ABFC)],
      "textColor": Color(0xFF1F2937),
      "footer": [Color(0xFF1E3A8A), Color(0xFFF59E0B)],
      "footerTextColor": Colors.white,
    },
    // 9. Golden Yellow → Orange | Footer: Indigo → Burgundy
    {
      "background": [Color(0xFFF59E0B), Color(0xFFF97316)],
      "textColor": Colors.white,
      "footer": [Color(0xFF4338CA), Color(0xFF7F1D1D)],
      "footerTextColor": Colors.white,
    },
    // 10. Fresh Lime → Bright Green | Footer: Hot Pink → Violet
    {
      "background": [Color(0xFFA3E635), Color(0xFF65A30D)],
      "textColor": Color(0xFF111827),
      "footer": [Color(0xFFF472B6), Color(0xFF9333EA)],
      "footerTextColor": Colors.white,
    },
    // 11. Crimson Red → Burgundy | Footer: Cool Gray → Dark Slate
    {
      "background": [Color(0xFF991B1B), Color(0xFF7F1D1D)],
      "textColor": Colors.white,
      "footer": [Color(0xFF4B5563), Color(0xFF111827)],
      "footerTextColor": Colors.white,
    },
    // 12. Ocean Blue → Aqua Mint | Footer: Orange → Amber
    {
      "background": [Color(0xFF0EA5E9), Color(0xFF14B8A6)],
      "textColor": Colors.white,
      "footer": [Color(0xFFF97316), Color(0xFFD97706)],
      "footerTextColor": Colors.white,
    },
    // 13. Peach → Soft Coral | Footer: Indigo → Dark Navy
    {
      "background": [Color(0xFF6D28D9), Color(0xFFD946EF)],
      "textColor": Colors.white,
      "footer": [Color(0xFF312E81), Color(0xFFE11D48)],
      "footerTextColor": Colors.white,
    },
    // 14. Midnight Blue → Deep Purple | Footer: Gold → Orange
    {
      "background": [Color(0xFF1E3A8A), Color(0xFF4C1D95)],
      "textColor": Colors.white,
      "footer": [Color(0xFFEAB308), Color(0xFFF97316)],
      "footerTextColor": Color(0xFF1F2937),
    },

    // 1. Elegant Purple → Blue
    {
      "background": [Color(0xFF6D28D9), Color(0xFF3B82F6)],
      "textColor": Colors.white,
      "footer": [Color(0xFF111827), Color(0xFF2563EB)], // Dark + Brand balance
      "footerTextColor": Colors.white,
    },

    // 2. Deep Navy → Teal
    {
      "background": [Color(0xFF0F2027), Color(0xFF2C5364)],
      "textColor": Colors.white,
      "footer": [Color(0xFF38B2AC), Color(0xFF134E4A)],
      "footerTextColor": Colors.white,
    },

    // 3. Sunset Vibe
    {
      "background": [Color(0xFFee9ca7), Color(0xFFffdde1)],
      "textColor": Color(0xFF1E293B),
      "footer": [Color(0xFF374151), Color(0xFF111827)], // Contrast for icon
      "footerTextColor": Colors.white,
    },

    // 4. Pink → Red Luxury
    {
      "background": [Color(0xFFFF416C), Color(0xFFFF4B2B)],
      "textColor": Colors.white,
      "footer": [Color(0xFF7F1D1D), Color(0xFFB91C1C)],
      "footerTextColor": Colors.white,
    },

    // 5. Emerald Green
    {
      "background": [Color(0xFF11998e), Color(0xFF38ef7d)],
      "textColor": Colors.white,
      "footer": [Color(0xFF064E3B), Color(0xFF10B981)],
      "footerTextColor": Colors.white,
    },

    // 6. Golden Sunrise
    {
      "background": [Color(0xFFFFD194), Color(0xFFD1913C)],
      "textColor": Color(0xFF1F2937),
      "footer": [Color(0xFF78350F), Color(0xFFF59E0B)],
      "footerTextColor": Colors.white,
    },

    // 7. Peach Coral
    {
      "background": [Color(0xFFFBCFE8), Color(0xFFF87171)],
      "textColor": Color(0xFF1E293B),
      "footer": [Color(0xFF1E3A8A), Color(0xFF1D4ED8)],
      "footerTextColor": Colors.white,
    },

    // 8. Dark Lava
    {
      "background": [Color(0xFF232526), Color(0xFF414345)],
      "textColor": Colors.white,
      "footer": [Color(0xFF0F172A), Color(0xFF334155)],
      "footerTextColor": Colors.white,
    },

    // 9. Ocean Breeze
    {
      "background": [Color(0xFF2BC0E4), Color(0xFFEAECC6)],
      "textColor": Color(0xFF1E293B),
      "footer": [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
      "footerTextColor": Colors.white,
    },

    // 10. Royal Gold → Deep Blue
    {
      "background": [Color(0xFFF7971E), Color(0xFFFFD200)],
      "textColor": Color(0xFF111827),
      "footer": [Color(0xFF1E3A8A), Color(0xFF1D4ED8)],
      "footerTextColor": Colors.white,
    },

    // 11. Frosted Mint
    {
      "background": [Color(0xFFc2e59c), Color(0xFF64b3f4)],
      "textColor": Color(0xFF1F2937),
      "footer": [Color(0xFF065F46), Color(0xFF059669)],
      "footerTextColor": Colors.white,
    },

    // 12. Crimson Night
    {
      "background": [Color(0xFF780206), Color(0xFF061161)],
      "textColor": Colors.white,
      "footer": [Color(0xFF4C1D95), Color(0xFF9333EA)],
      "footerTextColor": Colors.white,
    },

    // 13. Rose Quartz
    {
      "background": [Color(0xFFeecda3), Color(0xFFef629f)],
      "textColor": Color(0xFF1E293B),
      "footer": [Color(0xFF9D174D), Color(0xFFBE185D)],
      "footerTextColor": Colors.white,
    },

    // 14. Sapphire Dream
    {
      "background": [Color(0xFF0f0c29), Color(0xFF302b63)],
      "textColor": Colors.white,
      "footer": [Color(0xFF1E3A8A), Color(0xFF2563EB)],
      "footerTextColor": Colors.white,
    },
  ];



  void _suggestMessage() {
    final suggestions = aiSuggestions[widget.category];
    if (suggestions != null && suggestions.isNotEmpty) {
      setState(() {
        _controller.text = (suggestions..shuffle()).first;
      });
    }
  }

  Future<void> _generateAndShareImage() async {
    try {
      RenderRepaintBoundary boundary =
      _previewKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      ui.Image image = await boundary.toImage(pixelRatio: 3.0); // High quality
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Save to temporary directory
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/gift_card.png';
      File imgFile = File(filePath);
      await imgFile.writeAsBytes(pngBytes);

      // // Share the image
      // await Share.shareFiles([filePath], text: "Here’s your surprise gift! ❤️");

      await SharePlus.instance.share(
        ShareParams(
            files:  [XFile(filePath)],
            title: 'NexPay Airtime Gift Export',
            text: 'Here’s your surprise gift! ❤️\n\nPowered by NexPay — where '
                'thousands create and share '
                'moments like this every day.\n\nGet yours → ${AppLinkHandler.appLink} ',

        ),
      );

    } catch (e) {
      print("Error generating image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Something went wrong. Try again!')),
      );
    }
  }

  final _c = TextEditingController();
  bool _hitCap = false;

  @override
  void initState() {
    _suggestMessage();
    // TODO: implement initState
    super.initState();
  }

  bool expanded = false;

  @override
  Widget build(BuildContext context) {

    String phoneNumber = widget.phoneNumber;
    String replace = phoneNumber.substring(11);
    String formattedPhone = phoneNumber.replaceAll(replace, '****');
    // final String templatePath = ModalRoute.of(context)!.settings.arguments;
    return Scaffold(
      // backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Customize Gift Card'),
        // backgroundColor: Colors.black,
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: RepaintBoundary(
              key: _previewKey,
              child: Container(
                margin: EdgeInsetsGeometry.only(left: 10,
                    right: 10, top: 0, bottom: 6),
                padding: EdgeInsetsGeometry.only(left: 20,
                    right: 20, top: 10, bottom: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.orange,
                  image: DecorationImage(fit: BoxFit.cover,
                      image: NetworkImage(widget.templatePath)),
                ),
                child: TextFieldTapRegion(
                  onTapOutside: (event) {
                    FocusScope.of(context).unfocus();
                  },
                  onTapInside: (event) {
                    FocusScope.of(context).unfocus();
                  },
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)
                    ),
                    child: Container(
                      width: 350,
                      // height: 450,
                      constraints: BoxConstraints(maxHeight: 450),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                          gradient: LinearGradient(colors:
                          _bgColor)
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: 10),
                          Column(
                            children: [
                              Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF0F172A),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(5.0),
                                    child: Icon(Icons.gpp_good, size: 20, color: kIconColor,),
                                  )
                              ),
                              Container(
                                decoration: BoxDecoration(
                                    color: Color(0xFF0F172A),
                                    borderRadius: BorderRadius.circular(8)
                                ),
                                child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    child: Text('Verified',
                                      style: GoogleFonts.raleway(
                                          fontWeight: FontWeight.bold, fontSize: 6),)),
                              )
                            ],
                          ),
                          SizedBox(height: 10),
                          Text("To: ${widget.recipient.toUpperCase()}",
                              style: GoogleFonts.poppins(fontSize: 14, color: _textColor)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            // crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(kFormatter.format(int.parse(widget.amount)),
                                  style: GoogleFonts.poppins(
                                      fontSize: 30, fontWeight: FontWeight.bold, color: _textColor)),
                              SizedBox(width: 3,),
                              Text("NGN",
                                  style: GoogleFonts.poppins(
                                      fontSize: 16, fontWeight: FontWeight.bold, color: _textColor)),
                            ],
                          ),
                          Text(widget.productType,
                              style: GoogleFonts.poppins(
                                  fontSize: 18, fontWeight: FontWeight.w500, color: _textColor)),
                          // Padding(
                          //   padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                          //   child: Text(
                          //     _message,
                          //     textAlign: TextAlign.center,
                          //     style: GoogleFonts.getFont(_selectedFont,
                          //         fontSize: 16, fontWeight: FontWeight.bold, color: _textColor),
                          //   ),
                          // ),
                          // SizedBox(
                          //   height: 120,
                          //   child: GestureDetector(
                          //     onTap: () {
                          //       if (_isReadOnly) {
                          //         setState(() {
                          //           _isReadOnly = false;
                          //         });
                          //         FocusScope.of(context).requestFocus(focusNode);
                          //       }
                          //     },
                          //     child: Padding(
                          //       padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 0),
                          //       child: TextField(
                          //         controller: _controller,
                          //         autofocus: true,
                          //         textAlign: TextAlign.center,
                          //         keyboardType: TextInputType.multiline,
                          //         maxLines: null,
                          //         readOnly: false,
                          //         focusNode: focusNode,
                          //         cursorColor: Colors.white,
                          //         showCursor: true,
                          //         style: GoogleFonts.getFont(_selectedFont,
                          //                   fontSize: _selectedFont == 'Dancing Script' ? 12: 10, fontWeight: FontWeight.bold, color: _textColor),
                          //         decoration: InputDecoration(
                          //           border: InputBorder.none,
                          //           focusedBorder: InputBorder.none,
                          //
                          //         ),
                          //       ),
                          //     ),
                          //   ),
                          // ),
                          GestureDetector(
                            onTap: () {
                              if (_isReadOnly) {
                                setState(() {
                                  _isReadOnly = false;
                                });
                                FocusScope.of(context).requestFocus(focusNode);
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10),
                              child: HeightCappedTextField(
                                cursorColor: Colors.white,
                                controller: _controller,
                                maxHeightPx: 100, // your max pixel height
                                style: GoogleFonts.getFont(_selectedFont,
                                    fontSize: _selectedFont == 'Dancing Script' ? 14: 12, fontWeight: FontWeight.bold, color: _textColor),
                                decoration: InputDecoration(
                                  hintText: 'Share what’s on your mind…',
                                  border: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                                ),
                                onLimitReached: () {
                                  if (!_hitCap) {
                                    setState(() => _hitCap = true);
                                    // optional toast/snackbar
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('You’ve reached the maximum space')),
                                    );
                                    // reset the flag a bit later so we can show again if needed
                                    Future.delayed(const Duration(seconds: 1), () {
                                      if (mounted) setState(() => _hitCap = false);
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                          // Optional tiny helper text instead of snackbar
                          if (_hitCap)
                            const Padding(
                              padding: EdgeInsets.only(top: 0),
                              child: Text(
                                'You’ve reached the maximum space',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          Text("Phone:$formattedPhone",
                              style: GoogleFonts.robotoMono(fontSize: 18, color: _textColor)),
                          SizedBox(height: 10,),
                          Text("From: ${widget.sender.toUpperCase()}",
                              style: GoogleFonts.poppins(fontSize: 14, color: _textColor)),
                          SizedBox(height: 10,),
                          CustomPaint(
                            size: Size(300, 80),
                            painter: FooterPainter(
                              // begin: _beginAnimation.value,
                              // end: _endAnimation.value,
                              footerBG: _footer,
                            ),
                            child: Center(
                              child: Container(
                                width: 350,
                                height: 80,
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset("images/gift.png", height: 30),
                                    SizedBox(width: 8),
                                    Text("Made with NexPay",
                                        style: GoogleFonts.poppins(
                                            fontSize: 14, color: _selectedFooterColor, fontWeight: FontWeight.bold)
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Controls
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text("Backgrounds", style: GoogleFonts.inter(
                        fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                    Transform.scale(
                      scale: 0.86,
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: _suggestMessage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kButtonColor,
                        ),
                        child: Row(
                          children: [
                            Text("Suggest Message", style: TextStyle(color: Color(0xFF111827)),),
                            SizedBox(width: 5,),
                            FaIcon(FontAwesomeIcons.diceD6, color: Colors.black,)
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                SizedBox(
                  height: 50,
                  child:  GridView.builder(
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 20
                    ),
                    itemBuilder: (BuildContext context, int index) {
                      List<Color> currentBGColor = colorSet[index]['background'];
                      Color currentTextColor = colorSet[index]['textColor'];
                      Color currentFooterTextColor = colorSet[index]['footerTextColor'];
                      List<Color> footerBGColor = colorSet[index]['footer'];
                      bool isSelected = _selectedIndex == index;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedIndex = index;
                            // isSelected != isSelected;
                            _bgColor = currentBGColor;
                            _textColor = currentTextColor;
                            _footer = footerBGColor;
                            _selectedFooterColor = currentFooterTextColor;
                          });
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white54,
                              border: isSelected ? Border.all(
                                  color: Colors.white54
                              ) : Border(),
                              gradient: LinearGradient(
                                  colors: currentBGColor
                              )
                          ),
                          child: Center(
                            child: isSelected? Icon(Icons.check) : Container(),
                          ),
                        ),
                      );
                    },
                    itemCount: 7,
                  ),
                ),

                // Expand button with gradient + shadow
                Stack(
                  alignment: Alignment.center,
                  children: [
                    expanded
                        ? SizedBox.shrink() : Container(
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0F172A),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black54,
                            blurRadius: 12,
                            spreadRadius: -4,
                            offset: Offset(0, -4),
                          ),
                        ],
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Color(0xFF0F172A),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => expanded = !expanded),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(
                          begin: 0,
                          end: expanded ? 0.5 : 0, // 0.5 turn = 180°
                        ),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        builder: (context, value, child) {
                          return Transform.rotate(
                            angle: value * 3.1416, // convert turns → radians
                            child: Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.white70,
                              size: 28,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                // sliding drawer for second 14 colours
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: expanded
                      ? SizedBox(
                    height: 160,
                    child: GridView.builder(
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 20
                      ),
                      itemBuilder: (BuildContext context, int fakeIndex) {
                        final index = 7 + fakeIndex;
                        List<Color> currentBGColor = colorSet[index]['background'];
                        Color currentTextColor = colorSet[index]['textColor'];
                        Color currentFooterTextColor = colorSet[index]['footerTextColor'];
                        List<Color> footerBGColor = colorSet[index]['footer'];
                        bool isSelected = _selectedIndex == index;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedIndex = index;
                              // isSelected != isSelected;
                              _bgColor = currentBGColor;
                              _textColor = currentTextColor;
                              _footer = footerBGColor;
                              _selectedFooterColor = currentFooterTextColor;
                            });
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white54,
                                border: isSelected ? Border.all(
                                    color: Colors.white54
                                ) : Border(),
                                gradient: LinearGradient(
                                    colors: currentBGColor
                                )
                            ),
                            child: Center(
                              child: isSelected? Icon(Icons.check) : Container(),
                            ),
                          ),
                        );
                      },
                      itemCount: 21,
                    ),
                  )
                      : const SizedBox.shrink(),
                ),

                SizedBox(height: 10),
                CupertinoPicker(
                  itemExtent: 32,
                  magnification: 1.2,
                  useMagnifier: true,
                  onSelectedItemChanged: (value) {
                      setState(() => _selectedFont = _fonts[value]);
                      },
                  children:  _fonts
                        .map((f) => Text(f, style: GoogleFonts.getFont(f, color: Colors.white, ),),)
                        .toList(),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _generateAndShareImage,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: kButtonColor
                  ),
                  child: Text("Generate & Share", style: TextStyle(color: Color(0xFF111827)),),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// class FooterPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()..color = kButtonColor;
//     final path = Path()
//       ..lineTo(0, size.height - 30)
//       ..quadraticBezierTo(size.width / 2, size.height, size.width, size.height - 30)
//       ..lineTo(size.width, 0)
//       ..close();
//     canvas.drawPath(path, paint);
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }

class FooterPainter extends CustomPainter {
  // final Alignment begin;
  // final Alignment end;
  final List<Color> footerBG;

  FooterPainter({required this.footerBG});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final Gradient gradient = LinearGradient(
      colors:  footerBG,
      // begin: begin,
      // end: end,
    );

    final paint = Paint()..shader = gradient.createShader(rect);
    final path = Path()
      ..lineTo(0, size.height - 30)
      ..quadraticBezierTo(size.width / 2, size.height, size.width, size.height - 30)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant FooterPainter oldDelegate) => true;
}