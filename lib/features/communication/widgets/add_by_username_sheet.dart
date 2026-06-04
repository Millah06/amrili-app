import 'package:everywhere/core/auth/guest_helper.dart';
import 'package:flutter/material.dart';

import '../../../constraints/constants.dart';
import '../../../constraints/vendor_theme.dart';
import '../../../services/brain.dart';
import '../screens/message_screen.dart';
import '../services/chat_room_service.dart';

class AddByUsernameSheet extends StatefulWidget {
  final Brain pov;

  const AddByUsernameSheet({super.key,
    required this.pov,
  });

  @override
  State<AddByUsernameSheet> createState() =>
      AddByUsernameSheetState();
}

class AddByUsernameSheetState extends State<AddByUsernameSheet> {

  final TextEditingController _controller =
  TextEditingController();

  bool _loading = false;
  Map<String, dynamic>? _user;
  bool _searched = false;

  Future<void> _search() async {
    final value = _controller.text.trim();

    if (value.isEmpty) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _searched = true;
      _user = null;
    });

    final result =
    await ChatRoomService().findUserByUsername(value);

    if (!mounted) return;

    setState(() {
      _user = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * .82,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Center(
              child: Container(
                width: 45,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Find by username',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Search for any user instantly.',
              style: TextStyle(
                color: Colors.white.withOpacity(.6),
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 28),

            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.05),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withOpacity(.05),
                ),
              ),
              child: TextFormField(
                controller: _controller,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                textInputAction: TextInputAction.search,
                onFieldSubmitted: (_) => _search(),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: VendorTheme.surface,
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(18)
                  ),
                  // border: InputBorder.none,
                  hintText: '@username',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(.3),
                  ),
                  prefixIcon: const Icon(
                    Icons.alternate_email_rounded,
                    color: Colors.white54,
                  ),
                  suffixIcon: IconButton(
                    onPressed: _search,
                    icon: const Icon(
                      Icons.search_rounded,
                      color: kButtonColor,
                    ),
                  ),
                  contentPadding:
                  const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            Expanded(
              child: Builder(
                builder: (_) {

                  if (_loading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: kButtonColor,
                      ),
                    );
                  }

                  if (!_searched) {
                    return Center(
                      child: Column(
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_search_rounded,
                            color: Colors.white24,
                            size: 70,
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Search using username',
                            style: TextStyle(
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (_user == null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        children: [

                          Icon(
                            Icons.sentiment_dissatisfied_rounded,
                            size: 70,
                            color: Colors.white24,
                          ),

                          const SizedBox(height: 16),

                          const Text(
                            'User not found',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            'Check the username and try again.',
                            style: TextStyle(
                              color: Colors.white
                                  .withOpacity(.45),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final avatar =
                      _user!['avatarUrl'] ?? '';

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.04),
                      borderRadius:
                      BorderRadius.circular(22),
                    ),
                    child: Row(
                      children: [

                        CircleAvatar(
                          radius: 30,
                          backgroundColor:
                          Colors.white12,
                          backgroundImage:
                          avatar.toString().isNotEmpty
                              ? NetworkImage(avatar)
                              : null,
                          child:
                          avatar.toString().isEmpty
                              ? const Icon(
                            Icons.person,
                            color: Colors.white54,
                          )
                              : null,
                        ),

                        const SizedBox(width: 14),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [

                              Text(
                                _user!['name'] ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight:
                                  FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                '@${_user!['userName']}',
                                style: TextStyle(
                                  color: Colors.white
                                      .withOpacity(.55),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),

                        ElevatedButton(
                          style:
                          ElevatedButton.styleFrom(
                            backgroundColor:
                            kButtonColor,
                            shape:
                            RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(
                                  12),
                            ),
                          ),
                          onPressed: () => GuestHelper.guardAction(context, action: () async {

                            final roomId =
                            await ChatRoomService()
                                .createOrGetChatRoom(otherId: _user!['id'],
                            );

                            if (!mounted) return;

                            Navigator.pop(context);

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    Peer2PeerChat(
                                      roomId: roomId,
                                      otherUid:
                                      _user!['id'],
                                      otherUserName:
                                      _user!['name'],
                                      currentUserUid:
                                      widget.pov.currentUser,
                                    ),
                              ),
                            );

                          }, reason: 'chat with people'),
                          child: const Text(
                            'Chat',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}