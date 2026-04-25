class ChatItem {
  final String chatId;
  final String otherUid;
  final String name;
  final String lastMessage;
  final DateTime lastMessageAt;
  final bool unread;

  ChatItem({
    required this.chatId,
    required this.otherUid,
    required this.name,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unread,
  });
}

class ChatRoom {
  final String roomId;
  final List<String> participants;
  final DateTime createdAt;
  final String lastMessage;
  final String lastMessageType;
  final DateTime? lastMessageTime;

  ChatRoom({
    required this.roomId,
    required this.participants,
    required this.createdAt,
    required this.lastMessage,
    required this.lastMessageType,
    this.lastMessageTime,
  });

  Map<String, dynamic> toMap() => {
    'participants': participants,
    'createdAt': createdAt,
    'lastMessage': lastMessage,
    'lastMessageType': lastMessageType,
    'lastMessageTime': lastMessageTime,
  };
}

