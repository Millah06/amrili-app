import 'package:flutter/cupertino.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class ContactPermissionDeniedException implements Exception {
  final String message;
  ContactPermissionDeniedException([this.message = 'Contacts permission denied']);

  @override
  String toString() => message;
}

class ContactService {

  String normalizePhone(String phone) {
    // 1️⃣ Remove everything except digits
    String digits = phone.replaceAll(RegExp(r'\D'), '');

    // 2️⃣ Nigerian numbers handling
    if (digits.startsWith('0') && digits.length == 11) {
      // 0803xxxxxxx → 234803xxxxxxx
      digits = '234${digits.substring(1)}';
    } else if (digits.startsWith('234') && digits.length == 13) {
      // already correct
      digits = digits;
    } else if (digits.startsWith('2340')) {
      // edge case: 2340803xxxxxxx
      digits = '234${digits.substring(4)}';
    }

    return digits;
  }

  // String normalizePhone(String phone) {
  //   if (phone.startsWith('+234')) {
  //     return '0${phone.substring(4)}';
  //   }
  //   return phone;
  // }



  Future<List<Contact>> fetchContacts() async {

    final List<Contact> myList;

    try {

      if (!await FlutterContacts.requestPermission(readonly: true)) {
        debugPrint('Contacts permission denied');
        throw ContactPermissionDeniedException();
      }

      myList = await FlutterContacts.getContacts(withProperties: true, withPhoto: false);

      return myList;


    }
    catch (e) {
      rethrow;
    }
  }
}
