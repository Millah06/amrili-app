import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_model.dart';

class ChatsProvider extends ChangeNotifier {


  List<ChatModel> _allChats = [];

  List<ChatModel> get chats => _allChats;

  Stream<QuerySnapshot>? chatStream(currentUserUid) {
    if (currentUserUid == null) {
      return null;
    }
    return FirebaseFirestore.instance
        .collection('chat_room')
        .where('participants', arrayContains: currentUserUid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  void updateFromSnapshot(QuerySnapshot snapshot,String currentUserUid) {
    _allChats = snapshot.docs
        .map((doc) => ChatModel.fromFirestore(
      doc,
      currentUserUid: currentUserUid,
    ))
        .toList();
  }

  /// Filters
  List<ChatModel> filtered(String filter) {
    switch (filter) {
      case 'Unread':
        return _allChats.where((c) => c.unreadCount > 0).toList();

      case 'Groups':
        return _allChats.where((c) => c.isGroup).toList();

      case 'Official':
        return _allChats.where((c) => c.isOfficial).toList();

      case 'Favourite':
        return _allChats.where((c) => c.isPinned).toList();

      default:
        return _allChats;
    }
  }
}