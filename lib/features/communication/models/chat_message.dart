import 'package:cloud_firestore/cloud_firestore.dart';

/// A single chat message, decoupled from Firestore so it can be cached in Hive
/// and rendered offline. Firestore is the transport; this is the local archive.
class ChatMessage {
  final String id;
  final String? text;
  final String senderId;
  final String type; // 'text' | 'moneyTransfer' | ...
  final String status; // 'sending' | 'sent' | 'delivered' | 'read'
  final String? amount;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.senderId,
    required this.type,
    required this.status,
    required this.createdAt,
    this.amount,
  });

  factory ChatMessage.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final ts = (data['createdAt'] ?? data['localCreatedAt']) as Timestamp?;
    return ChatMessage(
      id: doc.id,
      text: data['text'],
      senderId: data['senderId'] ?? '',
      type: data['type'] ?? 'text',
      status: data['status'] ?? 'sent',
      amount: data['amount']?.toString(),
      createdAt: ts?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'text': text,
        'senderId': senderId,
        'type': type,
        'status': status,
        'amount': amount,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory ChatMessage.fromMap(Map<String, dynamic> map) => ChatMessage(
        id: map['id'] ?? '',
        text: map['text'],
        senderId: map['senderId'] ?? '',
        type: map['type'] ?? 'text',
        status: map['status'] ?? 'sent',
        amount: map['amount']?.toString(),
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            map['createdAt'] ?? 0),
      );
}
