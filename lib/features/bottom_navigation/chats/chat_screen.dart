import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:everywhere/features/bottom_navigation/chats/widgets/chat_bubble.dart';
import 'package:everywhere/screens/pages/transaction_history_screen.dart';
import 'package:everywhere/shared/widgets/pull_to_reveal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/ph.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_reveal_flutter/pull_to_reveal_flutter.dart';

import '../../../constraints/constants.dart';
import '../../../constraints/vendor_theme.dart';
import '../../../features/communication/providers/chat_provider.dart';
import '../../../services/brain.dart';
import '../../communication/services/chat_room_service.dart';
import '../../communication/models/chat_model.dart';
import 'message_screen.dart';


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
               onTap: () async {
                 // TODO: Implement QR scan / help link

               },
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
               icon: const Icon( FontAwesomeIcons.plusCircle, color: Colors.white),
               onPressed: () async {



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
             Expanded(
               child: StreamBuilder<QuerySnapshot>(
                 stream: chatsProvider.chatStream(pov.currentUser),
                 builder: (context, snapshot) {

                   if (!snapshot.hasData) {
                     return const Center(
                       child: CircularProgressIndicator(),
                     );
                   }

                   final docs = snapshot.data!.docs;

                   if (docs.isEmpty) {
                     return EmptyChatView(
                       onAddFriends: () {
                         showAddFriendsSheet(context, pov);
                       },
                     );
                   }

                   chatsProvider.updateFromSnapshot(snapshot.data!, pov.currentUser);

                   return ValueListenableBuilder(valueListenable: filter,
                       builder: (_, value, _) {
                     final chats = chatsProvider.filtered(value);
                     return ListView.separated(
                       separatorBuilder: (_, __) => Divider(
                         indent: 16,
                         endIndent: 16,
                         color: Colors.white.withOpacity(0.05),
                         height: 1,
                       ),
                       itemCount: chats.length + 1,
                       itemBuilder: (context, index) {

                         if (index == chats.length) {
                           return ChatListFooter(
                             onAddFriends: () {
                               showAddFriendsSheet(context, pov);
                             },
                           );
                         }

                         final data = docs[index];

                         final participantInfo =
                         data['participantInfo'] as Map;

                         final otherUser =
                         participantInfo.entries.firstWhere(
                               (e) => e.key != pov.currentUser,
                         );

                         final name = otherUser.value['name'];

                         final chat = chats[index];

                         return ChatCard(
                           chat: chat,
                           onTap: () {
                             Navigator.push(
                               context,
                               MaterialPageRoute(
                                 builder: (_) => Peer2PeerChat(
                                   roomId: data.id,
                                   otherUserName: name,
                                   currentUserUid: pov.currentUser,
                                   otherUid: otherUser.key,
                                 ),
                               ),
                             );
                           },
                         );
                       },
                     );
                   });

                 },
               ),
             )
           ],
         ),
       ),
     );
  }

  void showAddFriendsSheet(BuildContext context, Brain pov) {

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (_) {

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              ListTile(
                leading: const Icon(Icons.person_search, color: Colors.white),
                title: const Text("Add by username", style: TextStyle(color: Colors.white),),
                onTap: () {},
              ),

              ListTile(
                leading: const Icon(Icons.phone, color: Colors.white),
                title: const Text("Add by phone number", style: TextStyle(color: Colors.white),),
                onTap: () {},
              ),

              ListTile(
                leading: const Icon(Icons.contacts, color: Colors.white),
                title: const Text("Add from contacts", style: TextStyle(color: Colors.white),),
                onTap: () async {
                  Navigator.pop(context);
                  // show your contacts list
                  if (mounted)  {
                    await context.read<Brain>().loadContactsOnce();
                    showModalBottomSheet(context: context, isScrollControlled: false, builder: (context) {
                      if (pov.contactsPermissionDenied)
                       { return Padding(
                          padding: const EdgeInsets.only(top: 40.0, left: 16, right: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Turn on contacts access to automatically find people you already know who are using Everywhere.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF177E85),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                  onPressed: () async {
                                    final granted = await FlutterContacts.requestPermission(readonly: true);
                                    if (granted && mounted) {
                                      await pov.loadContactsOnce();
                                    }
                                  },
                                  child: const Text(
                                    'Enable contacts access',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );}
                      // Show a clear loading state while contacts are being fetched/matched
                      else if (pov.contactsLoading && !pov.contactsLoaded)
                        {return Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 40.0),
                            child: CircularProgressIndicator(color: VendorTheme.circularProgressColor,),
                          ),
                        );}
                      return SingleChildScrollView(
                        child: StreamBuilder(
                            stream: FirebaseFirestore.instance
                                .collection('user_contacts')
                                .doc(pov.currentUser)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                print('In awaiting stage');
                                return Center(child: CircularProgressIndicator());
                              }

                              if (!snapshot.hasData || !snapshot.data!.exists) {
                                // Contacts not saved yet or document missing
                                return Padding(
                                  padding: const EdgeInsets.only(top: 40.0),
                                  child: Center(
                                    child: Text(
                                      'No matched contacts yet.\nWe will show people from your phonebook here once scanning finishes.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.white60, fontSize: 12),
                                    ),
                                  ),
                                );
                              }

                              final data = snapshot.data!.data();
                              if (data == null || data['contacts'] == null) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 40.0),
                                  child: Center(
                                    child: Text(
                                      'No matched contacts found from your phonebook.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.white60, fontSize: 12),
                                    ),
                                  ),
                                );
                              }

                              final contacts = List.from(data['contacts'] as List);
                              if (contacts.isEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 40.0),
                                  child: Center(
                                    child: Text(
                                      'No matched contacts found from your phonebook.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.white60, fontSize: 12),
                                    ),
                                  ),
                                );
                              }
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: contacts.map((c) {
                                  ChatModel chat = ChatModel(id: c['uid'], name: c['name']);
                                  return ChatCard(
                                    chat: chat,
                                    onTap: () async {
                                      final myUid = pov.currentUser;
                                      final otherUid = c['uid']; // from user_contacts
                                      final otherUserName = c['name'];
                                      final chatService = ChatRoomService();
                                      final roomId = await chatService.createOrGetP2PRoom(
                                        myUid: myUid,
                                        otherUid: otherUid,
                                      );
                                      Navigator.pop(context);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => Peer2PeerChat(
                                            roomId: roomId,
                                            otherUid: otherUid,
                                            otherUserName: otherUserName,
                                            currentUserUid: pov.currentUser,
                                          ),
                                        ),
                                      );

                                    },
                                    onArchive: () {},
                                    onPin: () {},
                                    onViewPicture: () {},
                                    onViewProfile: () {},
                                  );
                                }).toList(),
                              );
                            },
                          ),
                      );
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
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