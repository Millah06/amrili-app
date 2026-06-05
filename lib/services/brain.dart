import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../features/social/services/social_api_service.dart';

class Brain extends ChangeNotifier {


  List<Map<String, dynamic>> _transactions = [];

  List<Map<String, dynamic>> get transactions => _transactions;



  String get currentUser => FirebaseAuth.instance.currentUser!.uid;

  Future<bool> canAuthenticate() async {
    final LocalAuthentication auth = LocalAuthentication();
    final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
    final bool canAuthenticate =
        canAuthenticateWithBiometrics || await auth.isDeviceSupported();
    return canAuthenticate;
  }
  String passCode = '';
  // String userName = '';
  // String accountBalance = '0';
  // String phoneNumber = '';
  // String accountReward = '0';

  double totalMonthlySpent = 0;

  double  airtimePercent = 0;
  String ? baseURL;
  double dataPercent = 0;
  double  cablePercent = 0;
  double  electricPercent = 0;
  double  waecPercent = 0;
  double  jambPercent = 0;
  double fundingFees = 0;
  double  rCPersonalPercent = 0;
  double  rCBusinessPercent = 0;
  double  internetPercent = 0;
  int buildNumberFromFireStore = 0;

  Map<String, bool> cableProviders = {};
  Map<String, bool> electricProviders = {};
  Map<String, bool> dataProviders = {};
  Map<String, bool> airtimeProviders = {};
  List<String> whatIsNew = [];
  bool mandatory = false;
  String versionName = '1.0.0';

  Map accountData = {};
  List<dynamic> availableJambServices = [];
  List<dynamic> availableWaecRegistration = [];
  List<dynamic> availableWaecPin = [];
  String pIN = '';
  String imagePath = '';
  bool _isLoading = true;

  String get localPasscode => passCode;
  String get localPIN => pIN;
  bool get isLoading => _isLoading;
  String get image => imagePath;
  Map get userAccount => accountData;

  Future<String?> getIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return await user.getIdToken();
    }
    return null;
  }

  Future<void> getData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final prefs = await SharedPreferences.getInstance();
    // // passCode  = prefs.getString('loginPassCode')!;
    // imagePath = prefs.getString('imagePath')!;
    try {

      final doc = await FirebaseFirestore.instance.collection('users')
          .doc(userId).get();

      final bonusDoc = await FirebaseFirestore.instance.collection('bonuses ').doc('reward').get();
      DocumentSnapshot updateSnap = await FirebaseFirestore.instance.collection('bonuses ').doc('updateInfo').get();

      if (updateSnap.exists) {
        whatIsNew = List<String>.from(updateSnap['whatIsNew'].values);
        mandatory = updateSnap['mandatory'] ?? false;
        versionName = updateSnap['versionName'];
      }

      final serviceDoc = await FirebaseFirestore.instance.collection('services').doc('services').get();

      if (bonusDoc.exists) {
        print("Bonus doc data: ${bonusDoc.data()}");
      } else {
        print("No bonus doc found!");
      }

      cableProviders = Map<String, bool>.from(serviceDoc['cableServices']);
      dataProviders =  Map<String, bool>.from(serviceDoc['dataNetwork']);
      airtimeProviders =  Map<String, bool>.from(serviceDoc['airtimeServices']);
      electricProviders = Map<String, bool>.from(serviceDoc['electricProviders']);

      airtimePercent = (bonusDoc['airtime'] as num).toDouble();
      dataPercent = (bonusDoc['data'] as num).toDouble();
      cablePercent = (bonusDoc['cable'] as num).toDouble();
      electricPercent = (bonusDoc['electric'] as num).toDouble();
      rCBusinessPercent = (bonusDoc['rechargeB'] as num).toDouble();
      rCPersonalPercent = (bonusDoc['rechargeP'] as num).toDouble();
      internetPercent = (bonusDoc['internet'] as num).toDouble();
      waecPercent = (bonusDoc['waec'] as num).toDouble();
      jambPercent = (bonusDoc['jamb'] as num).toDouble();
      fundingFees = (bonusDoc['fundingFees'] as num).toDouble();
      buildNumberFromFireStore = (bonusDoc['buildNumber'] as num).toInt();
      baseURL = bonusDoc['baseURL'] ?? {
        print('Base Url not found'),
        "https://everywhere-data-app.onrender.com"
      };
      notifyListeners();
    }
    catch (e) {
      print('Error fetching username: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  String generateRequestId() {

    final now = DateTime.now().toUtc().add(const Duration(hours: 1));

    final dateTimePart = DateFormat('yyyyMMddHHmm').format(now);


    final uuidPart = const Uuid().v4().replaceAll('-', '').substring(0, 12);

    return '$dateTimePart$uuidPart';
  }

  Future<List> getAvailableJambServices() async {
    final idToken = await getIdToken();
    final dio = Dio();
    try {
      var response = await dio.get(
          "$baseURL/exams/jambServices",
          data: {
            'serviceID' : 'jamb'
          },
          options: Options(
              headers: {
                "Authorization": "Bearer $idToken",
                "Content-Type": "application/json",
              }
          )
      );

      print(response.data);

      return response.data['response']['content']['variations'];

    }
    catch(e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getAvailableWaecRegistration() async {
    final idToken = await getIdToken();
    final dio = Dio();
    try {
      var response = await dio.get(
          "$baseURL/exams/jambServices",
          data: {
            'serviceID' : 'waec-registration'
          },
          options: Options(
              headers: {
                "Authorization": "Bearer $idToken",
                "Content-Type": "application/json",
              }
          )
      );

      print(response.data);

      return response.data['response']['content']['variations'];

    }
    catch(e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getAvailableWaecPin() async {
    final idToken = await getIdToken();
    final dio = Dio();
    try {
      var response = await dio.get(
          "$baseURL/exams/jambServices",
          data: {
            'serviceID' : 'waec'
          },
          options: Options(
              headers: {
                "Authorization": "Bearer $idToken",
                "Content-Type": "application/json",
              }
          )
      );

      print(response.data);

      return response.data['response']['content']['variations'];

    }
    catch(e) {
      rethrow;
    }
  }


  Future<void> updateImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final savedImage = await File(pickedFile.path).copy('${appDir.path}/profile.png');
      String imgUrl = await SocialApiService().uploadPostImage(savedImage);
      final userRef = FirebaseFirestore.instance.collection('users').doc(currentUser);
      await userRef.update({
        'photoURL' : imgUrl,
      });


      // imagePath = File(pickedFile.path).path;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('imagePath', savedImage.path);
    }
    notifyListeners();
  }

  void reset() {
    _transactions = [];
    notifyListeners();
  }

}