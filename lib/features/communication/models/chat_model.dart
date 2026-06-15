
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

  /// Postgres id of the other participant — kept so a cached row can open the
  /// conversation offline without re-reading Firestore participantInfo.
  final String otherUserId;

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

  /// Message-requests: 'accepted' | 'pending' | 'blocked'. Legacy rooms with no
  /// field are treated as 'accepted'.
  final String requestState;

  /// Postgres id of whoever initiated the chat (the recipient is the *other*
  /// participant, and is the one who sees/acts on a pending request).
  final String requestedBy;

  final MessageStatus? messageStatus;

  const ChatModel({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.otherUserId = '',
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
    this.requestState = 'accepted',
    this.requestedBy = '',
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

    // Groups use a single group identity instead of the "other" participant.
    final bool group =
        data['type'] == 'group' || participants.length > 2;

    return ChatModel(
      id: doc.id,

      name: group
          ? (data['groupName'] ?? 'Group')
          : (otherUser['name'] ?? 'Unknown'),

      avatarUrl: group ? data['groupAvatar'] : otherUser['avatar'],

      otherUserId: otherUid,

      lastMessage: data['lastMessage'] ?? '',

      lastMessageType: messageType,

      lastMessageAt:
      (data['lastMessageTime'] as Timestamp?)?.toDate(),

      unreadCount: unread,

      isPinned: data['isPinned'] ?? false,

      isArchived: data['isArchived'] ?? false,

      isOfficial: data['isOfficial'] ?? false,

      isGroup: group,

      requestState: data['requestState'] ?? 'accepted',

      requestedBy: data['requestedBy'] ?? '',
    );
  }

  /// Plain-map serialization for the Hive cache (JSON-safe primitives only).
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'avatarUrl': avatarUrl,
        'otherUserId': otherUserId,
        'lastMessage': lastMessage,
        'lastMessageType': lastMessageType.name,
        'lastMessageAt': lastMessageAt?.millisecondsSinceEpoch,
        'unreadCount': unreadCount,
        'isPinned': isPinned,
        'isArchived': isArchived,
        'isOfficial': isOfficial,
        'isSystem': isSystem,
        'isGroup': isGroup,
        'isFavourite': isFavourite,
        'requestState': requestState,
        'requestedBy': requestedBy,
        'messageStatus': messageStatus?.name,
      };

  factory ChatModel.fromMap(Map<String, dynamic> map) => ChatModel(
        id: map['id'] ?? '',
        name: map['name'] ?? 'Unknown',
        avatarUrl: map['avatarUrl'],
        otherUserId: map['otherUserId'] ?? '',
        lastMessage: map['lastMessage'] ?? '',
        lastMessageType: MessageType.values.firstWhere(
          (e) => e.name == map['lastMessageType'],
          orElse: () => MessageType.text,
        ),
        lastMessageAt: map['lastMessageAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['lastMessageAt'])
            : null,
        unreadCount: map['unreadCount'] ?? 0,
        isPinned: map['isPinned'] ?? false,
        isArchived: map['isArchived'] ?? false,
        isOfficial: map['isOfficial'] ?? false,
        isSystem: map['isSystem'] ?? false,
        isGroup: map['isGroup'] ?? false,
        isFavourite: map['isFavourite'] ?? false,
        requestState: map['requestState'] ?? 'accepted',
        requestedBy: map['requestedBy'] ?? '',
        messageStatus: map['messageStatus'] != null
            ? MessageStatus.values.firstWhere(
                (e) => e.name == map['messageStatus'],
                orElse: () => MessageStatus.sent,
              )
            : null,
      );

}