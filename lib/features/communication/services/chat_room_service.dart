import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomService {
  final _db = FirebaseFirestore.instance;


  Future<String> createOrGetP2PRoom({required String myUid, required String otherUid,}) async {
    final query = await _db
        .collection('chat_room')
        .where('participants', arrayContains: myUid)
        .get();

    for (var doc in query.docs) {
      List participants = doc['participants'];

      if (participants.contains(otherUid)) {
        return doc.id;
      }
    }

    final roomRef = _db.collection('chat_room').doc();

    final myUser =
    await _db.collection('users').doc(myUid).get();

    final otherUser =
    await _db.collection('users').doc(otherUid).get();

    final myUserProfile =
    await _db.collection('userProfiles').doc(myUid).get();

    final otherUserProfile =
    await _db.collection('userProfiles').doc(otherUid).get();

    await roomRef.set({
      "type": "p2p",
      "participants": [myUid, otherUid],

      "participantInfo": {
        myUid: {
          "name": myUser['name'],
          "avatar": myUserProfile['avatar']
        },
        otherUid: {
          "name": otherUser['name'],
          "avatar": otherUserProfile['avatar']
        }
      },
      "lastMessage": "",
      "lastMessageType": "text",
      "lastMessageTime": null,
      "createdAt": FieldValue.serverTimestamp(),
    },
      SetOptions(merge: true)
    );

    return roomRef.id;
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


  String _getRoomId(String uid1, String uid2) {
    return uid1.compareTo(uid2) < 0
        ? '${uid1}_$uid2'
        : '${uid2}_$uid1';
  }

}
