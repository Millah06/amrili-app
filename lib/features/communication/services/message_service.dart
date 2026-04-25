import 'package:cloud_firestore/cloud_firestore.dart';



class MessageService {
  final _db = FirebaseFirestore.instance;

  /// Remove all non-digit characters from a phone string
  String normalizeToDigits(String phone) {
    return phone.replaceAll(RegExp(r'\D'), '');
  }

  /// Return the last 10 digits of a phone number, or empty string if not enough digits
  String last10Digits(String phone) {
    final digits = normalizeToDigits(phone);
    if (digits.length < 10) return '';
    return digits.substring(digits.length - 10);
  }

  /// Read the other user's phoneNumber from Firestore and return its last 10 digits.
  /// Returns null if user / phoneNumber is missing or invalid.
  Future<String?> getOtherUserPhoneLast10(String otherUid) async {
    final doc = await _db.collection('users').doc(otherUid).get();
    if (!doc.exists) return null;

    final data = doc.data();
    if (data == null) return null;

    final phone = data['phoneNumber'];
    if (phone is! String) return null;

    final last10 = last10Digits(phone);
    if (last10.isEmpty) return null;
    return last10;
  }

  Future<void> sendTextMessage({required String roomId,  required String receiverId, required String senderId, required String text,}) async {
    final messageRef = _db
        .collection('chat_room')
        .doc(roomId)
        .collection('messages');

    final messageDoc = messageRef.doc();
    final localTime = Timestamp.now();

    try {
      await messageDoc.set({
        'text': text,
        'type': 'text',
        'senderId': senderId,
        'metadata': null,
        'createdAt': FieldValue.serverTimestamp(),
        'localCreatedAt': localTime,
        'status': 'sending',
        'expireAt': Timestamp.fromDate(
          DateTime.now().add(Duration(hours: 120)),
        )
      });

      await messageDoc.update({
        'status': 'sent',
      });

    } catch (e) {
      // Optional: keep status as "sending"
      // Later Hive retry will handle this
      // debugPrint('Send message failed: $e');
    }


    final doc = await _db.collection('chat_room').doc(roomId).get();

    // int currentUnread = int.parse(doc['unreadCount']);
    // update chat room preview
    await _db.collection('chat_room').doc(roomId).update({
      'lastMessage': text,
      'lastMessageType' : 'text',
      "unreadCount.$receiverId": FieldValue.increment(1),
      'messageStatus' : 'sent',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }


  Future<void> markMessagesAsDelivered({required String roomId, required String currentUserId}) async {
    final query = await FirebaseFirestore.instance
        .collection('chat_room')
        .doc(roomId)
        .collection('messages')
        .where('senderId', isNotEqualTo: currentUserId)
        .where('status', isEqualTo: 'sent')
        .get();

    if (query.docs.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();

    for (final doc in query.docs) {
      batch.update(doc.reference, {'status': 'delivered'});
    }

    await batch.commit();

    final doc = await _db.collection('chat_room').doc(roomId).get();

    // update chat room preview
    await _db.collection('chat_room').doc(roomId).update({
      'messageStatus' : 'delivered',
    });

  }

  Future<void> markMessagesAsRead({required String roomId, required String currentUserId}) async {
    final query = await FirebaseFirestore.instance
        .collection('chat_room')
        .doc(roomId)
        .collection('messages')
        .where('senderId', isNotEqualTo: currentUserId)
        .where('status', isEqualTo: 'delivered')
        .get();

    if (query.docs.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();

    for (final doc in query.docs) {
      batch.update(doc.reference, {'status': 'read'});
    }

    await batch.commit();

    final doc = await _db.collection('chat_room').doc(roomId).get();

     
    // update chat room preview
    await _db.collection('chat_room').doc(roomId).update({
      'unreadCount.$currentUserId' : 0,
      'messageStatus' : 'read',
    });

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

  // MessageService().deleteMessage(roomId, messageId);
  deleteMessage(roomId, messageId) {
    _db.collection('chat_room').doc(roomId).collection('messages').doc(messageId).delete();
  }

}
