import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../constraints/formatters.dart';
import '../services/chat_cache_service.dart';
import '../theme/chat_theme.dart';

/// Read-only global announcements channel (admin → all users). Everyone
/// subscribes to the single `official_broadcast` collection; only admins can
/// post (enforced by the backend endpoint). No input bar here by design.
class OfficialBroadcastScreen extends StatelessWidget {
  const OfficialBroadcastScreen({super.key});

  static const String collection = 'official_broadcast';

  @override
  Widget build(BuildContext context) {
    // Opening the channel marks all current announcements as read.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ChatCacheService.instance
          .setOfficialLastRead(DateTime.now().millisecondsSinceEpoch);
    });
    return Scaffold(
      backgroundColor: ChatTheme.scaffold,
      appBar: AppBar(
        backgroundColor: ChatTheme.brand,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            const Icon(Icons.verified_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('Amril Official',
                style: GoogleFonts.raleway(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(collection)
            .orderBy('createdAt', descending: true)
            .limit(100)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Text('No announcements yet',
                  style: TextStyle(color: Colors.white54)),
            );
          }
          return ListView.builder(
            reverse: true,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return _BroadcastCard(
                title: data['title'] as String?,
                text: data['text'] ?? '',
                time: data['createdAt'] is Timestamp
                    ? Formatters().formatTimeInMessages(data['createdAt'])
                    : '',
              );
            },
          );
        },
      ),
    );
  }
}

class _BroadcastCard extends StatelessWidget {
  const _BroadcastCard({required this.text, this.title, this.time = ''});

  final String? title;
  final String text;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ChatTheme.surface,
        borderRadius: BorderRadius.circular(ChatTheme.bubbleRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null && title!.isNotEmpty) ...[
            Text(title!,
                style: GoogleFonts.inter(
                    color: ChatTheme.brandBright,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
          ],
          Text(text,
              style: GoogleFonts.inter(
                  color: Colors.white, fontSize: 14.5, height: 1.4)),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(time,
                style: GoogleFonts.inter(
                    color: Colors.white38, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
