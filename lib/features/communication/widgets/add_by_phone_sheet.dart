import 'package:everywhere/core/auth/guest_helper.dart';
import 'package:flutter/material.dart';

import '../../../constraints/constants.dart';
import '../../../constraints/vendor_theme.dart';
import '../../../services/brain.dart';
import '../../../shared/widgets/country_code_picker_field.dart';
import '../screens/message_screen.dart';
import '../services/chat_room_service.dart';
import 'chat_loading.dart';

class AddByPhoneNumber extends StatefulWidget {

  final Brain pov;

  const AddByPhoneNumber({super.key,
    required this.pov,
  });

  @override
  State<AddByPhoneNumber> createState() => AddByPhoneNumberState();
}

class AddByPhoneNumberState extends State<AddByPhoneNumber> {

  final TextEditingController _phoneController = TextEditingController();

  String _dialCode = '+234';
  String _countryCode = 'NG';

  bool _loading = false;
  bool _searched = false;

  Map<String, dynamic>? _user;

  Future<void> _search() async {

    final phone =
        '$_dialCode${_phoneController.text.trim()}';

    if (_phoneController.text.trim().isEmpty) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _searched = true;
      _user = null;
    });

    final result = await ChatRoomService().findUserByPhone(phone);

    if (!mounted) return;

    setState(() {
      _user = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Container(
      height: MediaQuery.of(context).size.height * .84,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [

            Center(
              child: Container(
                width: 45,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius:
                  BorderRadius.circular(20),
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Find by phone number',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Search securely using phone number.',
              style: TextStyle(
                color: Colors.white.withOpacity(.6),
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 28),

            Row(
              children: [

                CountryCodePickerField(
                  initialCode: '+234',
                  onChanged: (dial, code) {
                    _dialCode = dial;
                    _countryCode = code;
                  },
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                      Colors.white.withOpacity(.05),
                      borderRadius:
                      BorderRadius.circular(18),
                    ),
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType:
                      TextInputType.phone,
                      cursorColor: Colors.white,
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: VendorTheme.surface,
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(10)
                        ),
                        hintText: '8012345678',
                        hintStyle: TextStyle(
                          color: Colors.white
                              .withOpacity(.3),
                        ),
                        contentPadding:
                        const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kButtonColor,
                  padding:
                  const EdgeInsets.symmetric(
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(16),
                  ),
                ),
                onPressed: _loading ? null : _search,
                child: _loading
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text(
                  'Search',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            Expanded(
              child: Builder(
                builder: (_) {

                  if (!_searched) {
                    return Center(
                      child: Column(
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        children: [

                          Icon(
                            Icons.phone_rounded,
                            color: Colors.white24,
                            size: 70,
                          ),

                          const SizedBox(height: 12),

                          const Text(
                            'Search with phone number',
                            style: TextStyle(
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (_loading) {
                    return const Center(
                      child:
                      CircularProgressIndicator(
                        color: kButtonColor,
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
                            Icons.person_off_outlined,
                            size: 70,
                            color: Colors.white24,
                          ),

                          const SizedBox(height: 14),

                          const Text(
                            'No user found',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight:
                              FontWeight.w700,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            'Nobody is using this number yet.',
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
                          onPressed: () =>  GuestHelper.guardAction(context, action: () async {

                            final roomId = await runWithChatLoader(
                              context,
                              () => ChatRoomService().createOrGetChatRoom(
                                  otherId: _user!['id'], initiatedVia: 'phone'),
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
                                      otherAvatarUrl:
                                      _user!['avatarUrl'],
                                    ),
                              ),
                            );
                          },
                              reason: 'chat with people'),
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
            ),
          ],
        ),
      ),
    );
  }
}