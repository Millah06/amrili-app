import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chat_model.dart';
import '../providers/chat_provider.dart';
import '../services/chat_room_service.dart';
import '../theme/chat_theme.dart';
import '../widgets/chat_avatar.dart';
import 'group_chat_screen.dart';

/// Create a group: name + pick members from your existing 1:1 chats.
class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final Set<String> _selected = {};
  bool _creating = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter a group name')));
      return;
    }
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Pick at least one member')));
      return;
    }
    setState(() => _creating = true);
    final roomId = await ChatRoomService()
        .createGroup(name: name, memberIds: _selected.toList());
    if (!mounted) return;
    setState(() => _creating = false);
    if (roomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not create group')));
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => GroupChatScreen(roomId: roomId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Candidate members = my accepted 1:1 chats (people I already talk to).
    final candidates = context
        .watch<ChatsProvider>()
        .chats
        .where((c) => !c.isGroup && c.otherUserId.isNotEmpty)
        .toList();

    return Scaffold(
      backgroundColor: ChatTheme.scaffold,
      appBar: AppBar(
        backgroundColor: ChatTheme.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('New group',
            style: TextStyle(color: Colors.white, fontSize: 18)),
        actions: [
          TextButton(
            onPressed: _creating ? null : _create,
            child: _creating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Create',
                    style: TextStyle(
                        color: ChatTheme.brandBright,
                        fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 640), child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              cursorColor: ChatTheme.brandBright,
              decoration: InputDecoration(
                hintText: 'Group name',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: ChatTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (_selected.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('${_selected.length} selected',
                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ),
            ),
          Expanded(
            child: candidates.isEmpty
                ? const Center(
                    child: Text('Start a chat with someone first',
                        style: TextStyle(color: Colors.white54)),
                  )
                : ListView.builder(
                    itemCount: candidates.length,
                    itemBuilder: (_, i) => _memberTile(candidates[i]),
                  ),
          ),
        ],
      ),
      ),
    ),
    );
  }

  Widget _memberTile(ChatModel c) {
    final selected = _selected.contains(c.otherUserId);
    return ListTile(
      onTap: () => setState(() {
        selected ? _selected.remove(c.otherUserId) : _selected.add(c.otherUserId);
      }),
      leading: ChatAvatar(name: c.name, avatarUrl: c.avatarUrl, size: 44),
      title: Text(c.name, style: const TextStyle(color: Colors.white)),
      trailing: Checkbox(
        value: selected,
        activeColor: ChatTheme.brand,
        onChanged: (_) => setState(() {
          selected
              ? _selected.remove(c.otherUserId)
              : _selected.add(c.otherUserId);
        }),
      ),
    );
  }
}
