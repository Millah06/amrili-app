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

  /// Write a gift as a chat message (after the backend has moved the coins).
  Future<void> sendGiftMessage({
    required String roomId,
    required String senderId,
    required String receiverId,
    required String giftType,
    required String giftEmoji,
    required String giftName,
    required int coins,
  }) async {
    final messageRef =
        _db.collection('chat_room').doc(roomId).collection('messages');
    final messageDoc = messageRef.doc();

    try {
      await messageDoc.set({
        'text': '$giftEmoji $giftName',
        'type': 'gift',
        'giftType': giftType,
        'giftEmoji': giftEmoji,
        'giftName': giftName,
        'coins': coins,
        'senderId': senderId,
        'createdAt': FieldValue.serverTimestamp(),
        'localCreatedAt': Timestamp.now(),
        'status': 'sent',
        'expireAt':
            Timestamp.fromDate(DateTime.now().add(const Duration(hours: 120))),
      });
    } catch (_) {}

    await _db.collection('chat_room').doc(roomId).update({
      'lastMessage': '$giftEmoji $giftName',
      'lastMessageType': 'text',
      'unreadCount.$receiverId': FieldValue.increment(1),
      'messageStatus': 'sent',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  /// Group send: writes the message then bumps unread for every member except
  /// the sender (p2p sendTextMessage only bumps a single receiver).
  Future<void> sendGroupMessage({
    required String roomId,
    required String senderId,
    required String text,
    required List<String> participantIds,
  }) async {
    final messageRef =
        _db.collection('chat_room').doc(roomId).collection('messages');
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
        'status': 'sent',
        'expireAt':
            Timestamp.fromDate(DateTime.now().add(const Duration(hours: 120))),
      });
    } catch (_) {}

    final preview = <String, dynamic>{
      'lastMessage': text,
      'lastMessageType': 'text',
      'messageStatus': 'sent',
      'lastMessageTime': FieldValue.serverTimestamp(),
    };
    for (final id in participantIds) {
      if (id == senderId) continue;
      preview['unreadCount.$id'] = FieldValue.increment(1);
    }
    await _db.collection('chat_room').doc(roomId).update(preview);
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

    if (query.docs.isNotEmpty) {
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in query.docs) {
        batch.update(doc.reference, {'status': 'read'});
      }
      await batch.commit();
    }

    // Always clear my unread counter for this room — independent of whether
    // there were 'delivered' messages to flip. (Previously this lived after an
    // early-return, so the badge never reset when messages were already read.)
    await clearUnread(roomId: roomId, currentUserId: currentUserId);
  }

  /// Reset only the current user's unread counter for a room. Safe to call on
  /// every room open; does not touch message statuses.
  Future<void> clearUnread({required String roomId, required String currentUserId}) async {
    if (roomId.isEmpty || currentUserId.isEmpty) return;
    try {
      await _db.collection('chat_room').doc(roomId).update({
        'unreadCount.$currentUserId': 0,
      });
    } catch (_) {
      // Room may not exist yet / offline — ignore.
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

  // MessageService().deleteMessage(roomId, messageId);
  deleteMessage(roomId, messageId) {
    _db.collection('chat_room').doc(roomId).collection('messages').doc(messageId).delete();
  }

}
