import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../services/api_service.dart';

class ChatRoomService {
  final _db = FirebaseFirestore.instance;

  final api = ApiService();


  // Future<String> createOrGetP2PRoom({required String myUid, required String otherUid, required String otherUserAvatar}) async {
  //   final query = await _db
  //       .collection('chat_room')
  //       .where('participants', arrayContains: myUid)
  //       .get();
  //
  //   for (var doc in query.docs) {
  //     List participants = doc['participants'];
  //
  //     if (participants.contains(otherUid)) {
  //       return doc.id;
  //     }
  //   }
  //
  //   final roomRef = _db.collection('chat_room').doc();
  //
  //   final myUser =
  //   await _db.collection('users').doc(myUid).get();
  //
  //
  //   final otherUser =
  //   await _db.collection('users').doc(otherUid).get();
  //
  //   final myUserProfile =
  //   await _db.collection('userProfiles').doc(myUid).get();
  //
  //   final otherUserProfile =
  //   await _db.collection('userProfiles').doc(otherUid).get();
  //
  //   await roomRef.set({
  //     "type": "p2p",
  //     "participants": [myUid, otherUid],
  //
  //     "participantInfo": {
  //       myUid: {
  //         "name": myUser['name'],
  //         "avatar": myUserProfile['avatar']
  //       },
  //       otherUid: {
  //         "name": otherUser['name'],
  //         "avatar": otherUserProfile['avatar']
  //       }
  //     },
  //     "lastMessage": "",
  //     "lastMessageType": "text",
  //     "lastMessageTime": null,
  //     "createdAt": FieldValue.serverTimestamp(),
  //   },
  //     SetOptions(merge: true)
  //   );
  //
  //   return roomRef.id;
  // }

  Future<String> createOrGetChatRoom({required String otherId, String? initiatedVia}) async {

    try {
      final data = await api.post('/chat/create-or-get-room', {
        'otherUserId': otherId,
        if (initiatedVia != null) 'initiatedVia': initiatedVia,
      });
      return data['roomId'];
    }
    catch (e) {
      rethrow;
    }
  }

  /// Respond to a message request: 'accept' | 'decline' | 'block'.
  Future<bool> respondToRequest({required String roomId, required String action}) async {
    try {
      await api.post('/chat/room/$roomId/respond', {'action': action});
      return true;
    } catch (_) {
      return false;
    }
  }

  Stream<QuerySnapshot> messageStream(String roomId) {
    return FirebaseFirestore.instance
        .collection('chat_room')
        .doc(roomId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  Stream<QuerySnapshot> chatStream(String uid) {
    return FirebaseFirestore.instance
        .collection('chat_room')
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  Future<Map<String, dynamic>?> findUserByUsername(String username,) async {
    try {
      final data = await api.get(
        '/chat/find-by-username?username=${Uri.encodeComponent(username)}', optionalHeader: true
      );

      if (data == null) return null;
      return Map<String, dynamic>.from(data['user']);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> findUserByPhone(String phone,) async {
    try {
      final data = await api.get(
        '/chat/find-by-phone?phone=${Uri.encodeComponent(phone)}', optionalHeader: true
      );

      if (data == null) return null;
      return Map<String, dynamic>.from(data['user']);
    } catch (_) {
      return null;
    }
  }

  /// Resolve a Postgres User.id → profile card (for the chat-QR landing).
  Future<Map<String, dynamic>?> findUserById(String userId) async {
    try {
      final data = await api.get(
        '/chat/user/${Uri.encodeComponent(userId)}',
        optionalHeader: true,
      );
      if (data == null) return null;
      return Map<String, dynamic>.from(data['user']);
    } catch (_) {
      return null;
    }
  }


  String _getRoomId(String uid1, String uid2) {
    return uid1.compareTo(uid2) < 0
        ? '${uid1}_$uid2'
        : '${uid2}_$uid1';
  }

}
