import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:everywhere/core/auth/guest_helper.dart';
import 'package:everywhere/features/communication/widgets/chat_bubble.dart';
import 'package:everywhere/features/communication/providers/sync_contact_provider.dart';
import 'package:everywhere/features/communication/widgets/sync_contact_sheet.dart';
import 'package:everywhere/screens/pages/transaction_history_screen.dart';
import 'package:everywhere/shared/widgets/pull_to_reveal.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/ph.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_reveal_flutter/pull_to_reveal_flutter.dart';
import '../../constraints/constants.dart';
import '../communication/providers/chat_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/brain.dart';
import '../communication/widgets/add_by_phone_sheet.dart';
import '../communication/widgets/add_by_username_sheet.dart';
import '../communication/screens/message_screen.dart';
import '../communication/screens/message_requests_screen.dart';


class Messages extends StatefulWidget {
  const Messages({super.key});

  @override
  State<Messages> createState() => _MessagesState();
}

class _MessagesState extends State<Messages> {

  ValueNotifier<String> filter = ValueNotifier('All');

  @override
  Widget build(BuildContext context) {
    final pov = Provider.of<Brain>(context);
    final chatsProvider = context.watch<ChatsProvider>();
    // Postgres user id — chat rooms store Postgres ids in `participants`,
    // so the list must be queried with this, not the Firebase uid.
    final myId = context.watch<UserProvider>().user?.userId;
    // Paint instantly from the Hive cache while Firestore catches up.
    if (myId != null) chatsProvider.seedFromCache(myId);
     return PullRevealOverlayWrapper(
       controller: PullToRevealController(),
       child: Scaffold(
         backgroundColor: Color(0xFF0F172A),
         appBar: AppBar(
           elevation: 0,
           backgroundColor: const Color(0xFF1E293B),
           title:   Text(
             'Chats',
             style: kTopAppbars.copyWith(
               fontFamily:  'DejaVu Sans', fontSize: 23),
           ),
           actions: [
             GestureDetector(
               onTap: () => context.push('/my-chat-qr'),
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.end,
                 crossAxisAlignment: CrossAxisAlignment.end,
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   Container(
                     padding: EdgeInsets.all(1.5),
                     decoration: BoxDecoration(
                         color: Colors.pink,
                         borderRadius: BorderRadius.circular(5)
                     ),
                     child: Text('Scan', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),),
                   ),
                   SizedBox(height: 2,),
                   Iconify(Ph.qr_code_duotone, size: 20, color: Colors.white,),
                 ],
               ),
             ),
             IconButton(
               icon: const FaIcon(FontAwesomeIcons.plusCircle, color: Colors.white),
               onPressed: () {
                 showAddFriendsSheet(context, pov);
               },
             ),

           ]
         ),
         body: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             const SizedBox(height: 16),
             FilterBar(
               selected: filter.value,
               filters:  ['All', 'Unread',
                 'Favourite', 'Groups', 'Official' ],
               onSelect: (selected) {
                 setState(() {
                   filter.value = selected;
                 });
               },
             ),
             const SizedBox(height: 10),
             if (GuestHelper.isGuest)
               Expanded(
                 child: EmptyChatView(
                   onAddFriends: () {
                     showAddFriendsSheet(context, pov);
                   },
                 ),
               ),
             if (!GuestHelper.isGuest) ...[
               Expanded(
                 child: StreamBuilder<QuerySnapshot>(
                   stream: chatsProvider.chatStream(myId),
                   builder: (context, snapshot) {

                     if (!snapshot.hasData) {
                       // Offline / first frame: show cached chats if we have
                       // them, otherwise a skeleton.
                       if (chatsProvider.chats.isNotEmpty) {
                         return ValueListenableBuilder(
                           valueListenable: filter,
                           builder: (_, value, __) =>
                               _buildCachedList(context, pov, value, chatsProvider),
                         );
                       }
                       return const _ChatListSkeleton();
                     }

                     final docs = snapshot.data!.docs;

                     if (docs.isEmpty) {
                       return EmptyChatView(
                         onAddFriends: () {
                           showAddFriendsSheet(context, pov);
                         },
                       );
                     }

                     chatsProvider.updateFromSnapshot(snapshot.data!, myId ?? '');

                     return ValueListenableBuilder(valueListenable: filter,
                         builder: (_, value, __) =>
                             _buildCachedList(context, pov, value, chatsProvider));

                   },
                 ),
               )
             ]
           ],
         ),
       ),
     );
  }

  /// Renders the chat list straight from cached [ChatModel]s (no Firestore
  /// docs) — used for the offline / first-frame path.
  Widget _buildCachedList(
    BuildContext context,
    Brain pov,
    String value,
    ChatsProvider chatsProvider,
  ) {
    final chats = chatsProvider.filtered(value);
    final requestCount = chatsProvider.requestCount;
    final banner = requestCount > 0 && value == 'All'
        ? _RequestsBanner(
            count: requestCount,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MessageRequestsScreen()),
            ),
          )
        : null;

    if (chats.isEmpty) {
      return Column(
        children: [
          if (banner != null) banner,
          Expanded(
            child: EmptyChatView(
                onAddFriends: () => showAddFriendsSheet(context, pov)),
          ),
        ],
      );
    }
    return Column(
      children: [
        if (banner != null) banner,
        Expanded(
          child: ListView.separated(
            separatorBuilder: (_, __) => Divider(
              indent: 16,
              endIndent: 16,
              color: Colors.white.withValues(alpha: 0.05),
              height: 1,
            ),
            itemCount: chats.length + 1,
            itemBuilder: (context, index) {
              if (index == chats.length) {
                return ChatListFooter(
                  onAddFriends: () => showAddFriendsSheet(context, pov),
                );
              }
              final chat = chats[index];
              return ChatCard(
                chat: chat,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Peer2PeerChat(
                        roomId: chat.id,
                        otherUserName: chat.name,
                        otherUid: chat.otherUserId,
                        otherAvatarUrl: chat.avatarUrl,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void showAddFriendsSheet(BuildContext context, Brain pov) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          decoration: const BoxDecoration(
            color: Color(0xFF111827),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Add people',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Start conversations with friends and contacts.',
                style: GoogleFonts.inter(
                  color: Colors.white38,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 24),

              _MinimalActionTile(
                icon: Icons.alternate_email_rounded,
                title: 'Username',
                subtitle: 'Find by unique username',
                onTap: () {
                  Navigator.pop(context);
                  _showAddByUsername(context, pov);
                },
              ),

              _MinimalActionTile(
                icon: Icons.phone_outlined,
                title: 'Phone number',
                subtitle: 'Search registered numbers',
                onTap: () {
                  Navigator.pop(context);
                  _showAddByPhone(context, pov);
                },
              ),

              _MinimalActionTile(
                icon: Icons.contacts_outlined,
                title: 'Contacts',
                subtitle: 'People from your phonebook',
                onTap: () {
                  Navigator.pop(context);
                  // show your contacts list
                  _showSyncFromContact(context, pov);

                },
              ),

              _MinimalActionTile(
                icon: Icons.qr_code_scanner_rounded,
                title: 'Scan QR code',
                subtitle: 'Scan a friend’s chat code',
                onTap: () {
                  Navigator.pop(context);
                  context.push('/scan');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
// ADD THESE METHODS INSIDE _MessagesState
// ─────────────────────────────────────────────────────────────

  void _showSyncFromContact(BuildContext context, Brain pov) {
    showModalBottomSheet(
      context: context,
      showDragHandle: false,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<SyncContactProvider>(),
        child: SyncContactsSheet(pov: pov),
      ),
    );
  }

  void _showAddByUsername(BuildContext context, Brain pov) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (_) => AddByUsernameSheet(pov: pov),
    );
  }

  void _showAddByPhone(BuildContext context, Brain pov) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (_) => AddByPhoneNumber(pov: pov),
    );
  }

}

class _MinimalActionTile extends StatelessWidget {

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MinimalActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 2,
            vertical: 14,
          ),
          child: Row(
            children: [

              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: Colors.white70,
                  size: 20,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      title,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white24,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withOpacity(0.05),
            ),
          ),
          child: Row(
            children: [

              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      title,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        color: Colors.white54,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white24,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyChatView extends StatelessWidget {
  final VoidCallback onAddFriends;

  const EmptyChatView({super.key, required this.onAddFriends});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          Icon(
            Icons.chat_bubble_outline,
            size: 70,
            color: Colors.white38,
          ),

          const SizedBox(height: 15),

          const Text(
            "No chats yet",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            "Start chatting with your friends",
            style: TextStyle(
              color: Colors.white54,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: onAddFriends,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF177E85),
            ),
            child: const Text("Add Friends", style: TextStyle(color: Colors.white),),
          )
        ],
      ),
    );
  }
}

class ChatListFooter extends StatelessWidget {

  final VoidCallback onAddFriends;

  const ChatListFooter({
    super.key,
    required this.onAddFriends,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 25),
      child: Column(
        children: [
          Text(
            "—-- Chats end here --—",
            style: TextStyle(
              color: Colors.white38,
              fontSize: 12,
            ),

          ),

          const SizedBox(height: 4),

          TextButton(
            onPressed: onAddFriends,
            child: const Text(
              "Add people",
              style: TextStyle(
                color: Color(0xFF177E85),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner shown atop the chat list when there are pending message requests.
class _RequestsBanner extends StatelessWidget {
  const _RequestsBanner({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF177E85).withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: const Color(0xFF177E85).withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.mark_email_unread_outlined,
                  color: Color(0xFF2DD4BF), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  count == 1
                      ? '1 message request'
                      : '$count message requests',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lightweight skeleton shown while the chat list is loading — a calmer,
/// more premium first paint than a lone spinner.
class _ChatListSkeleton extends StatelessWidget {
  const _ChatListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 8,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            _box(50, 50, radius: 25),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _box(140, 13, radius: 6),
                  const SizedBox(height: 8),
                  _box(double.infinity, 11, radius: 6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _box(double w, double h, {double radius = 8}) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}

// ─────────────────────────────────────────────────────────────
// ADD THIS ENTIRE WIDGET
// PREMIUM USERNAME SEARCH
// ─────────────────────────────────────────────────────────────



// ─────────────────────────────────────────────────────────────
// REPLACE YOUR _AddByPhoneNumber WITH THIS
// ─────────────────────────────────────────────────────────────


