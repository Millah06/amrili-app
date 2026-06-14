import 'package:everywhere/core/auth/guest_helper.dart';
import 'package:everywhere/core/constant/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../../constraints/vendor_theme.dart';
import '../../../services/api_service.dart';
import '../../../services/brain.dart';
import '../screens/message_screen.dart';
import 'chat_bubble.dart';
import '../models/chat_model.dart';
import '../providers/sync_contact_provider.dart';
import '../services/chat_room_service.dart';



class SyncContactsSheet extends StatefulWidget {
  final Brain pov;
  const SyncContactsSheet({super.key, required this.pov});

  @override
  State<SyncContactsSheet> createState() => _SyncContactsSheetState();
}

class _SyncContactsSheetState extends State<SyncContactsSheet> {
  _SheetState _state = _SheetState.loading;
  List _users = [];
  int _totalBatches = 0;
  int _doneBatches = 0;

  // sync_contacts_sheet.dart

  @override
  void initState() {
    super.initState();
    // ✅ Wait for the first frame to finish before triggering any state changes
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  Future<void> _sync() async {
    setState(() {
      _state = _SheetState.loading;
      _users = [];
      _doneBatches = 0;
      _totalBatches = 0;
    });

    try {
      final syncProvider = context.read<SyncContactProvider>();
      final phones = await syncProvider.loadContacts();

      if (!mounted) return;

      if (syncProvider.contactsPermissionDenied) {
        setState(() => _state = _SheetState.permissionDenied);
        return;
      }

      if (phones.isEmpty) {
        setState(() => _state = _SheetState.empty);
        return;
      }

      const batchSize = 500;
      setState(() => _totalBatches = (phones.length / batchSize).ceil());

      final api = ApiService();
      final allUsers = <dynamic>[];

      await syncProvider.syncWithApi((batch) async {
        final response = await api.post('/chat/sync-contacts',
            {'contacts': batch}, optionalHeader: true);
        allUsers.addAll(response['users'] ?? []);
        if (mounted) setState(() => _doneBatches++);
      });

      if (!mounted) return;
      setState(() {
        _users = allUsers;
        _state = _users.isEmpty ? _SheetState.empty : _SheetState.done;
      });
    } catch (e) {
      debugPrint('_sync error: $e');
      if (mounted) setState(() => _state = _SheetState.error);
    }
  }

  Future<void> _retryAfterPermission() async {
    final status = await Permission.contacts.request();
    if (!mounted) return;
    if (status.isGranted) {
      context.read<SyncContactProvider>().retryLoadContacts();
      _sync();
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  Future<void> _openChat(Map user) async {
    final roomId = await ChatRoomService().createOrGetChatRoom(
      otherId: user['id'],
      initiatedVia: 'contact',
    );
    if (!mounted) return;
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Peer2PeerChat(
          roomId: roomId,
          otherUid: user['id'],
          otherUserName: user['name'],
          otherAvatarUrl: user['avatarUrl'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF111827),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        minHeight: 320,
        maxHeight: MediaQuery.of(context).size.height * 0.78,
      ),
      padding: EdgeInsets.only(bottom: bottomPadding + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          _buildHeader(),
          const Divider(color: Colors.white10, height: 1),
          Flexible(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
      child: Row(
        children: [
          const Text(
            'People You May Know',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          if (_state == _SheetState.done && _users.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF177E85).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF177E85).withOpacity(0.4)),
              ),
              child: Text(
                '${_users.length} found',
                style: const TextStyle(
                  color: Color(0xFF2DD4BF),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return switch (_state) {
      _SheetState.loading        => _buildLoading(),
      _SheetState.permissionDenied => _buildPermissionDenied(),
      _SheetState.empty          => _buildEmpty(),
      _SheetState.error          => _buildError(),
      _SheetState.done           => _buildUserList(),
    };
  }

  Widget _buildLoading() {
    return SizedBox(
      height: 220,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              color: VendorTheme.circularProgressColor,
              strokeWidth: 2.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _totalBatches > 1
                ? 'Syncing... $_doneBatches / $_totalBatches'
                : 'Finding your contacts on ${AppConstants.appName}...',
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 13,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionDenied() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.contacts_outlined, color: Colors.white30, size: 30),
          ),
          const SizedBox(height: 18),
          const Text(
            'Contacts Access Needed',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Allow access to automatically find people you already know who are on ${AppConstants.appName}.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF177E85),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              onPressed: _retryAfterPermission,
              child: const Text(
                'Enable Contacts Access',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return SizedBox(
      height: 220,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline_rounded, color: Colors.white12, size: 52),
          const SizedBox(height: 14),
          Text(
            'None of your contacts are on ${AppConstants.appName} yet.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white38, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return SizedBox(
      height: 220,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 44),
          const SizedBox(height: 12),
          const Text(
            'Something went wrong.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _sync,
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF2DD4BF)),
            child: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    return ListView.builder(
      itemCount: _users.length,
      padding: const EdgeInsets.only(top: 8),
      itemBuilder: (_, index) {
        final user = _users[index];
        return ChatCard(
          chat: ChatModel(id: user['id'], name: user['name']),
          onTap: () => GuestHelper.guardAction(context, action: () => _openChat(user),
              reason: 'chat with people'),
        );
      },
    );
  }
}

enum _SheetState { loading, permissionDenied, empty, error, done }