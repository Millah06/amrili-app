import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
// import '../utils/phone_utils.dart';
import 'contact_service.dart';

class UserMatchService {

  Future<Map<String, String>> buildPhoneNameMap(
      List<Contact> contacts) async {
    final Map<String, String> phoneToName = {};

    for (final contact in contacts) {
      if (contact.phones.isEmpty) continue;

      final name = contact.displayName.trim();
      if (name.isEmpty) continue;

      for (final phone in contact.phones) {
        final normalized = ContactService().normalizePhone(phone.number);
        if (normalized.isNotEmpty) {
          phoneToName[normalized] = name;
        }
      }
    }

    return phoneToName;
  }


  Future<List<Map<String, dynamic>>> findMatchedUsers(List<Contact> contacts) async {

    // 1️⃣ Build contact phone → name lookup
    final phoneToName = await buildPhoneNameMap(contacts);

    // 2️⃣ Fetch users
    final usersSnap =
    await FirebaseFirestore.instance.collection('users').get();

    final List<Map<String, dynamic>> matchedUsers = [];

    // 3️⃣ Match
    for (final userDoc in usersSnap.docs) {
      final data = userDoc.data();

      final rawPhone = data['phoneNumber'];
      if (rawPhone == null) continue;

      print(rawPhone);

      final userPhone = ContactService().normalizePhone(rawPhone);
      print(userPhone);
      final name = phoneToName[userPhone];

      if (name != null) {
        matchedUsers.add({
          'uid': userDoc.id,
          'phone': userPhone,
          'name': name, // ✅ ALWAYS PRESENT
        });
      }
    }

    return matchedUsers;
  }

  // Future<List<Map<String, dynamic>>> findMatchedUsers(List<Contact> contacts) async {
  //
  //   final phoneToName = await buildPhoneNameMap(contacts);
  //   final List<Map<String, dynamic>> matchedUsers = [];
  //
  //   for (final phone in phoneToName.keys) {
  //     final snap = await FirebaseFirestore.instance
  //         .collection('users')
  //         .where('phoneNumber', isEqualTo: phone)
  //         .limit(1)
  //         .get();
  //
  //     if (snap.docs.isNotEmpty) {
  //       final doc = snap.docs.first;
  //       matchedUsers.add({
  //         'uid': doc.id,
  //         'phone': phone,
  //         'name': phoneToName[phone],
  //       });
  //     }
  //   }
  //
  //   return matchedUsers;
  // }



}
