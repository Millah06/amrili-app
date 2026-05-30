// // import 'dart:io';
// //
// //
// // import 'package:everywhere/features/auth/security_screen.dart';
// // import 'package:flutter/material.dart';
// // import 'package:flutter/services.dart';
// // import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// // import 'package:google_fonts/google_fonts.dart';
// // import 'package:image_picker/image_picker.dart';
// // import 'package:path_provider/path_provider.dart';
// // import 'package:shared_preferences/shared_preferences.dart';
// //
// // import '../../constraints/constants.dart';
// // import '../../screens/community_screen.dart';
// // import '../../shared/utils/info_box.dart';
// //
// //
// // class ProfilePicture extends StatefulWidget {
// //   const ProfilePicture({super.key});
// //
// //   @override
// //   State<ProfilePicture> createState() => _ProfilePictureState();
// // }
// //
// // class _ProfilePictureState extends State<ProfilePicture> {
// //   File? _imageFile;
// //
// //   Future<void> _pickImage() async {
// //     final picker = ImagePicker();
// //     final pickedFile = await picker.pickImage(source: ImageSource.gallery);
// //     if (pickedFile != null) {
// //       setState(() {
// //         _imageFile = File(pickedFile.path);
// //       });
// //     }
// //     _saveData();
// //   }
// //
// //   Future<File> getImageFileFromAssets(String path) async {
// //     final byteData = await rootBundle.load(path);
// //
// //     final tempDir = await getTemporaryDirectory();
// //     final file = File('${tempDir.path}/default_profile.png');
// //
// //     await file.writeAsBytes(byteData.buffer.asUint8List());
// //     return file;
// //   }
// //
// //   // In _pick() — replace Navigator.push to SecurityScreen with:
// //   Future<void> _pick() async {
// //     File file = await getImageFileFromAssets('images/profile.png');
// //     setState(() => _imageFile = file);
// //     await _saveData();
// //     Navigator.pushAndRemoveUntil(
// //       context,
// //       MaterialPageRoute(
// //         builder: (_) => const CommunityScreen(isLogInOut: true),
// //       ),
// //           (route) => false,
// //     );
// //   }
// //
// //   Future<void> _saveData() async {
// //     final prefs = await SharedPreferences.getInstance();
// //     await prefs.setString('imagePath', _imageFile!.path  ?? '');
// //     // Navigator.pushAndRemoveUntil(
// //     //   context, MaterialPageRoute(builder: (_) => BottomBar()), (route) => false,);
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: Color(0xFF0F172A),
// //       body: SingleChildScrollView(
// //         child: Container(
// //           padding: EdgeInsets.only(top: 50),
// //           child: Column(
// //             crossAxisAlignment: CrossAxisAlignment.start,
// //             children: [
// //               Padding(
// //                 padding: const EdgeInsets.only(left: 10, right: 10),
// //                 child: ListTile(
// //                   contentPadding: EdgeInsets.zero,
// //                   leading: IconButton(
// //                     onPressed: (){
// //                       Navigator.pop(context);
// //                     },
// //                     icon: Icon(Icons.arrow_back),
// //                     style: IconButton.styleFrom(
// //                         backgroundColor: Colors.white
// //                     ),
// //                   ),
// //                   title: Text('Go Back', style: GoogleFonts.inter(
// //                     color: Colors.white,
// //                     fontSize: 25,
// //                     fontWeight: FontWeight.w700,
// //                   )),
// //                 ),
// //               ),
// //               Padding(
// //                 padding: const EdgeInsets.only(left: 15, top: 15, right: 15),
// //                 child: Column(
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   children: [
// //                     Text('Profile Picture Upload',
// //                       style: GoogleFonts.inter(
// //                           fontSize: 16, fontWeight: FontWeight.w900, color: kButtonColor),
// //                     ),
// //
// //                     const SizedBox(height: 8),
// //                     InfoBox(
// //                         text:  'It is not necessary to upload the profile picture. '
// //                             'You can easily skip if you wish. But uploading gives you a more personalized experience'
// //                     ),
// //
// //                   ],
// //                 ),
// //               ),
// //               Padding(
// //                 padding: EdgeInsets.only(top: 50, left: 15, right: 15),
// //                 child: Stack(
// //                   alignment: Alignment.topCenter,
// //                   children: [
// //                     Container(
// //                       width: 160,
// //                       height: 160,
// //                       decoration: BoxDecoration(
// //                           shape: BoxShape.circle,
// //                           border: Border.all(
// //                               color:  Colors.white,
// //                               width: 3
// //                           )
// //                       ),
// //                       child: ClipOval(
// //                         child: _imageFile != null ? Image.file(_imageFile!, fit: BoxFit.cover,) :
// //                         Icon(Icons.person, size: 130, color: kButtonColor,),
// //                       ),
// //                     ),
// //                     Padding(
// //                       padding: EdgeInsets.only(top: 120, left: 100),
// //                       child: GestureDetector(
// //                         onTap: _pickImage,
// //                         child: Container(
// //                           padding: EdgeInsets.all(8),
// //                           decoration: BoxDecoration(
// //                             color: kButtonColor,
// //                             shape: BoxShape.circle,
// //                           ),
// //                           child: Icon(FontAwesomeIcons.plusCircle,
// //                             size: 20, color: Colors.white,
// //                           ),
// //                         ),
// //                       ),
// //                     ),
// //                     Container(
// //                       margin: EdgeInsets.only(top: 210),
// //                       child: Row(
// //                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                         children: [
// //                           ElevatedButton(
// //                               style: ElevatedButton.styleFrom(
// //                                   backgroundColor: kButtonColor,
// //                                 elevation: 4,
// //                                 padding: EdgeInsets.symmetric(vertical: 15, horizontal: 12)
// //                               ),
// //                               onPressed: _pickImage,
// //                               child: Text('Upload profile picture',
// //                                   style: TextStyle(color: Colors.black,
// //                                       fontWeight: FontWeight.w700, fontSize: 16)
// //                               )),
// //                           SizedBox(height: 35,),
// //                           ElevatedButton(
// //                               style: ElevatedButton.styleFrom(
// //                                   backgroundColor: Colors.transparent,
// //                                   elevation: 4,
// //                                   padding: EdgeInsets.symmetric(vertical: 15, horizontal: 12),
// //                                   side: BorderSide(
// //                                       color: kButtonColor
// //                                   )
// //                               ),
// //                               onPressed: _imageFile != null
// //                                   ? () async {
// //                                 await _saveData();
// //                                 Navigator.pushAndRemoveUntil(
// //                                   context,
// //                                   MaterialPageRoute(
// //                                     builder: (_) => const CommunityScreen(isLogInOut: true),
// //                                   ),
// //                                       (route) => false,
// //                                 );
// //                               }
// //                                   : _pick,
// //                               child: Text(_imageFile == null ? 'No, thanks' : 'Proceed',
// //                                   style: TextStyle(color: Colors.white,
// //                                       fontWeight: FontWeight.w700, fontSize: 16)
// //                               )),
// //                         ],
// //                       ),
// //                     )
// //                   ],
// //                 ),
// //               )
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
//
//
// import 'dart:io';
// import 'dart:typed_data';
//
// import 'package:everywhere/features/auth/widgets/auth_ui_helpers.dart';
// import 'package:everywhere/providers/user_provider.dart';
// import 'package:everywhere/screens/community_screen.dart';
// import 'package:everywhere/services/api_service.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// import '../../constraints/constants.dart';
// import '../../shared/utils/flush_bar_message.dart';
// import '../../shared/utils/info_box.dart';
//
// class ProfilePicture extends StatefulWidget {
//   const ProfilePicture({super.key});
//
//   @override
//   State<ProfilePicture> createState() => _ProfilePictureState();
// }
//
// class _ProfilePictureState extends State<ProfilePicture> {
//   File? _imageFile;
//
//   File? _imageBytes;
//   String? _imageName;
//
//   bool _loading = false;
//
//   // ───────────────── PICK IMAGE ─────────────────
//
//   Future<void> _pickImage() async {
//     try {
//       final picker = ImagePicker();
//
//       final pickedFile = await picker.pickImage(
//         source: ImageSource.gallery,
//         imageQuality: 85,
//       );
//
//       if (pickedFile == null) return;
//
//       final file = File(pickedFile.path);
//
//       setState(() {
//         _imageFile = file;
//         _imageBytes = file;
//         _imageName = pickedFile.name;
//       });
//
//       await _saveLocalImage();
//     } catch (e) {
//       if (!mounted) return;
//
//       FlushBarMessage.showFlushBar(
//         context: context,
//         message: 'Unable to select image',
//         title: 'Error',
//       );
//     }
//   }
//
//   // ───────────────── DEFAULT LOCAL IMAGE ─────────────────
//
//   Future<File> getImageFileFromAssets(String path) async {
//     final byteData = await rootBundle.load(path);
//
//     final tempDir = await getTemporaryDirectory();
//
//     final file = File('${tempDir.path}/default_profile.png');
//
//     await file.writeAsBytes(byteData.buffer.asUint8List());
//
//     return file;
//   }
//
//   // ───────────────── LOCAL CACHE ─────────────────
//
//   Future<void> _saveLocalImage() async {
//     if (_imageFile == null) return;
//
//     final prefs = await SharedPreferences.getInstance();
//
//     await prefs.setString('imagePath', _imageFile!.path);
//   }
//
//   // ───────────────── COMPLETE SETUP ─────────────────
//
//   Future<void> _finishSetup() async {
//     setState(() => _loading = true);
//
//     try {
//       final api = ApiService();
//
//       String? avatarUrl;
//
//       // ─── Upload only if user selected image ───
//       if (_imageBytes != null && _imageName != null) {
//         final result = await api.upload(
//           'users/me/upload/profile-picture',
//           _imageBytes!,
//           _imageName!,
//         );
//
//         avatarUrl = result;
//
//         // ─── Update provider instantly ───
//         if (avatarUrl != null && mounted) {
//           context.read<UserProvider>().updateAvatar(
//             avatarUrl,
//           );
//         }
//       }
//
//       if (!mounted) return;
//
//       Navigator.pushAndRemoveUntil(
//         context,
//         MaterialPageRoute(
//           builder: (_) => const CommunityScreen(
//             isLogInOut: true,
//           ),
//         ),
//             (route) => false,
//       );
//     } catch (e) {
//       if (!mounted) return;
//
//       FlushBarMessage.showFlushBar(
//         context: context,
//         message: 'Failed to upload profile picture',
//         title: 'Upload Failed',
//       );
//     } finally {
//       if (mounted) {
//         setState(() => _loading = false);
//       }
//     }
//   }
//
//   // ───────────────── SKIP ─────────────────
//
//   Future<void> _skip() async {
//     final file = await getImageFileFromAssets(
//       'images/profile.png',
//     );
//
//     setState(() {
//       _imageFile = file;
//     });
//
//     await _saveLocalImage();
//
//     if (!mounted) return;
//
//     Navigator.pushAndRemoveUntil(
//       context,
//       MaterialPageRoute(
//         builder: (_) => const CommunityScreen(
//           isLogInOut: true,
//         ),
//       ),
//           (route) => false,
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF0F172A),
//       body: SafeArea(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // ───────────────── TOP BAR ─────────────────
//
//             Padding(
//               padding: const EdgeInsets.fromLTRB(
//                 16,
//                 12,
//                 16,
//                 0,
//               ),
//               child: BButton(
//                 onTap: () => Navigator.pop(context),
//               ),
//             ),
//
//             Expanded(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 24,
//                 ),
//                 child: Column(
//                   crossAxisAlignment:
//                   CrossAxisAlignment.start,
//                   children: [
//                     const SizedBox(height: 28),
//
//                     // ───────────────── STEP INDICATOR ─────────────────
//
//                     StepIndicator(
//                       current: 3,
//                       total: 3,
//                     ),
//
//                     const SizedBox(height: 24),
//
//                     // ───────────────── TITLE ─────────────────
//
//                     Text(
//                       'Add a profile\npicture.',
//                       style: GoogleFonts.inter(
//                         color: Colors.white,
//                         fontSize: 30,
//                         fontWeight: FontWeight.w900,
//                         height: 1.1,
//                       ),
//                     ),
//
//                     const SizedBox(height: 8),
//
//                     Text(
//                       'Help people recognize you.\nYou can always change it later.',
//                       style: GoogleFonts.inter(
//                         color: Colors.white54,
//                         fontSize: 14.5,
//                         height: 1.5,
//                       ),
//                     ),
//
//                     const SizedBox(height: 42),
//
//                     // ───────────────── AVATAR ─────────────────
//
//                     Center(
//                       child: Stack(
//                         alignment: Alignment.bottomRight,
//                         children: [
//                           Container(
//                             width: 130,
//                             height: 130,
//                             decoration: BoxDecoration(
//                               shape: BoxShape.circle,
//                               border: Border.all(
//                                 color: Colors.white,
//                                 width: 3,
//                               ),
//                             ),
//                             child: ClipOval(
//                               child: _imageFile != null
//                                   ? Image.file(
//                                 _imageFile!,
//                                 fit: BoxFit.cover,
//                               )
//                                   : const Icon(
//                                 Icons.person,
//                                 size: 100,
//
//                               ),
//                             ),
//                           ),
//
//                           GestureDetector(
//                             onTap: _pickImage,
//                             child: Container(
//                               padding:
//                               const EdgeInsets.all(12),
//                               decoration:
//                               const BoxDecoration(
//                                 color: kButtonColor,
//                                 shape: BoxShape.circle,
//                               ),
//                               child: const Icon(
//                                 Icons.add_a_photo,
//                                 color: Colors.black,
//                                 size: 16,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//
//                     const SizedBox(height: 42),
//
//                     // ───────────────── BUTTONS ─────────────────
//
//                     PrimaryButton(
//                       label: _loading
//                           ? 'Uploading...'
//                           : _imageFile == null
//                           ? 'Choose profile picture'
//                           : 'Continue',
//                       loading: _loading,
//                       onTap: _loading
//                           ? () {}
//                           : _imageFile == null
//                           ? _pickImage
//                           : _finishSetup,
//                     ),
//
//                     const SizedBox(height: 14),
//
//                     Center(
//                       child: TextButton(
//                         onPressed: _loading ? null : _skip,
//                         child: Text(
//                           'Skip for now',
//                           style: GoogleFonts.inter(
//                             color: Colors.white54,
//                             fontWeight: FontWeight.w600,
//                             fontSize: 14,
//                           ),
//                         ),
//                       ),
//                     ),
//
//                     const SizedBox(height: 24),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }