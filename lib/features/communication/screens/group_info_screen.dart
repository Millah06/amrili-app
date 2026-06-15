import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/user_provider.dart';
import '../models/chat_model.dart';
import '../providers/chat_provider.dart';
import '../services/chat_room_service.dart';
import '../theme/chat_theme.dart';
import '../widgets/chat_avatar.dart';

/// Group info & management: members list with roles, add/remove (admins only),
/// and leave. Reads the room doc live so changes reflect immediately.
class GroupInfoScreen extends StatelessWidget {
  const GroupInfoScreen({super.key, required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context) {
    final myId = context.watch<UserProvider>().user?.userId ?? '';
    final roomRef =
        FirebaseFirestore.instance.collection('chat_room').doc(roomId);

    return Scaffold(
      backgroundColor: ChatTheme.scaffold,
      appBar: AppBar(
        backgroundColor: ChatTheme.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Group info',
            style: TextStyle(color: Colors.white, fontSize: 18)),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: roomRef.snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final room = snap.data!.data() as Map<String, dynamic>? ?? {};
          final participants =
              (room['participants'] as List?)?.cast<String>() ?? const [];
          final info =
              (room['participantInfo'] as Map?)?.cast<String, dynamic>() ?? {};
          final roles =
              (room['roles'] as Map?)?.cast<String, dynamic>() ?? {};
          final groupName = room['groupName'] ?? 'Group';
          final myRole = roles[myId] ?? 'member';
          final iAmAdmin = myRole == 'owner' || myRole == 'admin';

          return ListView(
            children: [
              const SizedBox(height: 20),
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: Color(0xFF0D6E7A)),
                  child: const Icon(Icons.group, color: Colors.white, size: 40),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(groupName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text('${participants.length} members',
                    style: const TextStyle(color: Colors.white54)),
              ),
              const SizedBox(height: 20),
              if (iAmAdmin)
                ListTile(
                  leading: const Icon(Icons.person_add_alt_1,
                      color: ChatTheme.brandBright),
                  title: const Text('Add members',
                      style: TextStyle(color: Colors.white)),
                  onTap: () => _addMembers(context, roomId, participants),
                ),
              const Divider(color: Colors.white12),
              ...participants.map((id) {
                final p = info[id] as Map<String, dynamic>? ?? {};
                final role = roles[id] ?? 'member';
                final canRemove = iAmAdmin && id != myId && role != 'owner';
                return ListTile(
                  leading: ChatAvatar(
                      name: p['name'] ?? 'Unknown',
                      avatarUrl: p['avatar'],
                      size: 44),
                  title: Text(
                    id == myId ? 'You' : (p['name'] ?? 'Unknown'),
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: role != 'member'
                      ? Text(role,
                          style: const TextStyle(
                              color: ChatTheme.brandBright, fontSize: 12))
                      : null,
                  trailing: canRemove
                      ? IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              color: Color(0xFFF87171)),
                          onPressed: () async {
                            await ChatRoomService()
                                .removeGroupMember(roomId, id);
                          },
                        )
                      : null,
                );
              }),
              const Divider(color: Colors.white12),
              ListTile(
                leading: const Icon(Icons.exit_to_app_rounded,
                    color: Color(0xFFF87171)),
                title: const Text('Leave group',
                    style: TextStyle(color: Color(0xFFF87171))),
                onTap: () async {
                  final ok = await ChatRoomService().leaveGroup(roomId);
                  if (ok && context.mounted) {
                    Navigator.of(context)
                      ..pop() // info screen
                      ..pop(); // chat screen
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addMembers(
      BuildContext context, String roomId, List<String> current) async {
    final candidates = context
        .read<ChatsProvider>()
        .chats
        .where((c) => !c.isGroup && c.otherUserId.isNotEmpty)
        .where((c) => !current.contains(c.otherUserId))
        .toList();

    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No one new to add')),
      );
      return;
    }

    final selected = <String>{};
    await showModalBottomSheet(
      context: context,
      backgroundColor: ChatTheme.surfaceHigh,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheet) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          builder: (_, scroll) => Column(
            children: [
              const SizedBox(height: 12),
              const Text('Add members',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              Expanded(
                child: ListView(
                  controller: scroll,
                  children: candidates.map((ChatModel c) {
                    final on = selected.contains(c.otherUserId);
                    return CheckboxListTile(
                      value: on,
                      activeColor: ChatTheme.brand,
                      secondary: ChatAvatar(
                          name: c.name, avatarUrl: c.avatarUrl, size: 40),
                      title: Text(c.name,
                          style: const TextStyle(color: Colors.white)),
                      onChanged: (_) => setSheet(() {
                        on
                            ? selected.remove(c.otherUserId)
                            : selected.add(c.otherUserId);
                      }),
                    );
                  }).toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: ChatTheme.brand),
                    onPressed: () async {
                      if (selected.isEmpty) {
                        Navigator.pop(sheetCtx);
                        return;
                      }
                      await ChatRoomService()
                          .addGroupMembers(roomId, selected.toList());
                      if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                    },
                    child: const Text('Add',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
