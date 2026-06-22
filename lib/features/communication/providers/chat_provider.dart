import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_model.dart';
import '../services/chat_cache_service.dart';

class ChatsProvider extends ChangeNotifier {

  bool _disposed = false;

  List<ChatModel> _allChats = [];

  List<ChatModel> get chats => _allChats;

  String _myId = '';

  bool _seeded = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// Incoming message requests: pending rooms the OTHER person started
  /// (so I'm the recipient who must accept/decline). Blocked are excluded.
  List<ChatModel> get requests => _allChats
      .where((c) => c.requestState == 'pending' && c.requestedBy != _myId && c.requestedBy.isNotEmpty)
      .toList();

  int get requestCount => requests.length;

  /// Everything that belongs in the normal inbox: accepted chats, plus pending
  /// ones I initiated (waiting on them). Excludes incoming requests + blocked.
  List<ChatModel> get _inbox => _allChats.where((c) {
        if (c.requestState == 'blocked') return false;
        if (c.requestState == 'pending' && c.requestedBy != _myId && c.requestedBy.isNotEmpty) {
          return false; // incoming request → lives in the Requests screen
        }
        return true;
      }).toList();

  /// Seed the list from the Hive cache once, so the screen paints instantly
  /// (and works offline) before the Firestore stream returns.
  void seedFromCache(String userId) {
    _myId = userId;
    if (_seeded || userId.isEmpty) return;
    _seeded = true;
    final cached = ChatCacheService.instance.getChatList(userId);
    if (cached.isNotEmpty) {
      _allChats = cached;
      _notify();
    }
  }

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

  void updateFromSnapshot(QuerySnapshot snapshot, String currentUserUid) {
    _myId = currentUserUid;
    _allChats = snapshot.docs
        .map((doc) => ChatModel.fromFirestore(
      doc,
      currentUserUid: currentUserUid,
    ))
        .toList();
    // Persist newest list for instant/offline load next time.
    ChatCacheService.instance.saveChatList(currentUserUid, _allChats);
    _notify();
  }

  /// Filters operate on the inbox (requests are surfaced separately).
  List<ChatModel> filtered(String filter) {
    final inbox = _inbox;
    switch (filter) {
      case 'Unread':
        return inbox.where((c) => c.unreadCount > 0).toList();

      case 'Groups':
        return inbox.where((c) => c.isGroup).toList();

      case 'Official':
        return inbox.where((c) => c.isOfficial).toList();

      case 'Favourite':
        return inbox.where((c) => c.isPinned).toList();

      default:
        return inbox;
    }
  }
}