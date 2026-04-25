// lib/models/comment_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String commentId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String text;
  final DateTime createdAt;

  Comment({
    required this.commentId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.text,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {


    return Comment(
      commentId: json['id'],
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? 'Anonymous',
      userAvatar: json['userAvatar'],
      text: json['text'] ?? '',
      createdAt:  json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
    );
  }
}