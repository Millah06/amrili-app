import 'package:cloud_firestore/cloud_firestore.dart';

class UserContactService {
  static Future<void> saveUserContacts(
      String myUid,
      List<Map<String, dynamic>> contacts,
      ) async {
    await FirebaseFirestore.instance
        .collection('user_contacts')
        .doc(myUid)
        .set({
      'contacts': contacts,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
