
import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  text,
  image,
  video,
  voice,
  file,
  gif,
  system,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
}

class ChatModel {
  final String id;
  final String name;
  final String? avatarUrl;

  final String? lastMessage;
  final MessageType lastMessageType;

  final DateTime? lastMessageAt;

  final int unreadCount;

  final bool isPinned;
  final bool isArchived;

  final bool isOfficial;
  final bool isSystem;
  final bool isGroup;
  final bool isFavourite;

  final bool isOnline;
  final bool isTyping;

  final MessageStatus? messageStatus;

  const ChatModel({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.lastMessage,
    this.lastMessageType = MessageType.text,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.isPinned = false,
    this.isArchived = false,
    this.isOfficial = false,
    this.isSystem = false,
    this.isGroup = false,
    this.isFavourite = false,
    this.isOnline = false,
    this.isTyping = false,
    this.messageStatus,
  });

  factory ChatModel.fromFirestore(
      DocumentSnapshot doc, {
        required String currentUserUid,
      }) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    final participants =
        data['participants'] as List<dynamic>? ?? [];

    final participantInfo =
        data['participantInfo'] as Map<String, dynamic>? ?? {};

    /// Determine other user
    String otherUid = '';

    for (final uid in participants) {
      if (uid != currentUserUid) {
        otherUid = uid;
        break;
      }
    }

    final otherUser =
        participantInfo[otherUid] as Map<String, dynamic>? ?? {};

    /// Message type parsing
    MessageType messageType = MessageType.text;

    final typeString = data['lastMessageType'];

    if (typeString != null) {
      messageType = MessageType.values.firstWhere(
            (e) => e.name == typeString,
        orElse: () => MessageType.text,
      );
    }

    final unreadMap = data['unreadCount'] as Map<String, dynamic>? ?? {};

    final unread = unreadMap[currentUserUid] ?? 0;

    return ChatModel(
      id: doc.id,

      name: otherUser['name'] ?? 'Unknown',

      avatarUrl: otherUser['avatar'],

      lastMessage: data['lastMessage'] ?? '',

      lastMessageType: messageType,

      lastMessageAt:
      (data['lastMessageTime'] as Timestamp?)?.toDate(),

      unreadCount: unread,

      isPinned: data['isPinned'] ?? false,

      isArchived: data['isArchived'] ?? false,

      isOfficial: data['isOfficial'] ?? false,

      isGroup: (participants.length > 2),
    );
  }

}