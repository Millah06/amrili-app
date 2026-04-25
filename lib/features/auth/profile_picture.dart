import 'dart:io';


import 'package:everywhere/features/auth/security_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constraints/constants.dart';
import '../../shared/utils/info_box.dart';


class ProfilePicture extends StatefulWidget {
  const ProfilePicture({super.key});

  @override
  State<ProfilePicture> createState() => _ProfilePictureState();
}

class _ProfilePictureState extends State<ProfilePicture> {
  Color iconColor = Colors.white54;
  bool enable = true;
  bool obscureText = true;
  bool obscureText2 = true;
  final _formKey = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _password1controller = TextEditingController();
  final TextEditingController _password2controller = TextEditingController();

  File? _imageFile;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
    _saveData();
  }

  Future<File> getImageFileFromAssets(String path) async {
    final byteData = await rootBundle.load(path);

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/default_profile.png');

    await file.writeAsBytes(byteData.buffer.asUint8List());
    return file;
  }

  Future<void> _pick() async {
    File file = await getImageFileFromAssets('images/profile.png');
    setState(() {
      _imageFile = file;
    });
    await _saveData();
    Navigator.push(context, MaterialPageRoute(builder: (context) => SecurityScreen()));
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('imagePath', _imageFile!.path  ?? '');
    // Navigator.pushAndRemoveUntil(
    //   context, MaterialPageRoute(builder: (_) => BottomBar()), (route) => false,);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F172A),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.only(top: 50),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 10, right: 10),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: IconButton(
                    onPressed: (){
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.arrow_back),
                    style: IconButton.styleFrom(
                        backgroundColor: Colors.white
                    ),
                  ),
                  title: Text('Go Back', style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                  )),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 15, top: 15, right: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Profile Picture Upload',
                      style: GoogleFonts.inter(
                          fontSize: 16, fontWeight: FontWeight.w900, color: kButtonColor),
                    ),

                    const SizedBox(height: 8),
                    InfoBox(
                        text:  'It is not necessary to upload the profile picture. '
                            'You can easily skip if you wish. But uploading gives you a more personalized experience'
                    ),

                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 50, left: 15, right: 15),
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color:  Colors.white,
                              width: 3
                          )
                      ),
                      child: ClipOval(
                        child: _imageFile != null ? Image.file(_imageFile!, fit: BoxFit.cover,) :
                        Icon(Icons.person, size: 130, color: kButtonColor,),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 120, left: 100),
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: kButtonColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(FontAwesomeIcons.plusCircle,
                            size: 20, color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 210),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: kButtonColor,
                                elevation: 4,
                                padding: EdgeInsets.symmetric(vertical: 15, horizontal: 12)
                              ),
                              onPressed: _pickImage,
                              child: Text('Upload profile picture',
                                  style: TextStyle(color: Colors.black,
                                      fontWeight: FontWeight.w700, fontSize: 16)
                              )),
                          SizedBox(height: 35,),
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  elevation: 4,
                                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 12),
                                  side: BorderSide(
                                      color: kButtonColor
                                  )
                              ),
                              onPressed: _pick,
                              child: Text(_imageFile == null ? 'No, thanks' : 'Proceed',
                                  style: TextStyle(color: Colors.white,
                                      fontWeight: FontWeight.w700, fontSize: 16)
                              )),
                        ],
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
