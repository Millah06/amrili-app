import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  static Stream<QuerySnapshot> getUserChats(String uid) {
    return FirebaseFirestore.instance
        .collection('chats')
        .where('members', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots();
  }
}
