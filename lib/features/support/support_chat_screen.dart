import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:everywhere/features/bottom_navigation/chats/shortcut_actions.dart';
import 'package:everywhere/features/bottom_navigation/chats/widgets/message_bubble.dart';

import 'package:everywhere/features/communication/services/message_service.dart';
import 'package:everywhere/features/support/provider.dart';
import 'package:everywhere/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../components/service_fraame.dart';
import '../../../components/textInput_formater.dart';
import '../../../constraints/constants.dart';
import '../../../constraints/formatters.dart';
import '../../../services/brain.dart';
import 'api_service.dart';



class SupportChatScreen extends StatefulWidget {

  final String roomId;

  final String otherUserName;

  const SupportChatScreen ({super.key,  required this.roomId,
    required this.otherUserName});


  @override
  State<SupportChatScreen > createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen > {
  final messageTextController = TextEditingController();


  bool hasTouched = false;

  final FocusNode _focusNode =  FocusNode();

  final SupportProvider _supportProvider = SupportProvider();

  @override
  Widget build(BuildContext context) {
    final pov = Provider.of<UserProvider>(context);
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            color:  Color(0xFF177E85),
            padding: EdgeInsets.only(top: 35, bottom: 10, left: 10 ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.arrow_back, color: Colors.white, size: 25,),
                const SizedBox(width: 12,),
                Text(widget.otherUserName,
                  style: GoogleFonts.raleway(color: Colors.white,
                      fontWeight: FontWeight.bold, fontSize: 18),),

              ],
            ),
          ),

          MessagesStream(
            roomId: widget.roomId,
            currentUserId: pov.user!.userId,
          ),
          Container(
            decoration: BoxDecoration(
              color:  Color(0xFF1E293B),
              borderRadius: BorderRadius.only(
                  topRight: Radius.circular(32),
                  topLeft: Radius.circular(32)
              ),
            ),
            padding: EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 10),
            child: Column(
              children: [
                Container(
                  decoration: kMessageContainerDecoration,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      GestureDetector(
                          onTap: ()  {
                            // showModalBottomSheet(context: context, builder: (context) => EmojiPicker( ))
                            setState(() {
                              hasTouched = !hasTouched;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 3),
                            child: FaIcon(FontAwesomeIcons.faceSmileBeam, color: Colors.white, size: 25,
                            ),
                          )),
                      Expanded(
                        child: TextFormField(
                          controller: messageTextController,
                          focusNode: _focusNode,
                          decoration: kMessageTextFieldDecoration,
                          style: TextStyle(color: Colors.white, fontSize: 18),
                          cursorColor: Colors.white,
                          onTap: () {
                            if (hasTouched == false) {
                              setState(() {
                                hasTouched = true;
                              });
                            }
                          },
                          maxLines: 5,
                          minLines: 1,
                        ),
                      ),
                      hasTouched ? GestureDetector(
                          onTap: ()  {
                            setState(() {
                              hasTouched = !hasTouched;
                            });
                          }, child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 3),
                        child: FaIcon(
                          FontAwesomeIcons.plusCircle,
                          color: Colors.white,
                          size: 28,
                        ),
                      )) : GestureDetector(
                        onTap: () {
                          FocusScope.of(context).requestFocus(_focusNode);
                          setState(() {
                            hasTouched = !hasTouched;
                          });
                        }, child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 3),
                        child: FaIcon(FontAwesomeIcons.keyboard, size: 28,),
                      ),),
                      Visibility(
                          visible: messageTextController.text.isNotEmpty,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 10,  bottom: 10, right: 3, left: 10),
                            child: GestureDetector(
                                onTap: () async {
                                  await _supportProvider.sendMessage(
                                      chatId: widget.roomId,
                                      message: messageTextController.text,
                                  );
                                  if (mounted) {
                                     messageTextController.clear();
                                  }

                                },
                                child: _supportProvider.isSending ? CircularProgressIndicator() :
                                Icon(Icons.send, size: 30,)),
                          )
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MessagesStream extends StatelessWidget {
  const MessagesStream({
    super.key,

    required this.roomId,
    required this.currentUserId,
  });


  final String roomId;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: SupportServices().messageStream(roomId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Expanded(
            child: Center(
              child: Text(
                'Start the conversation 👋, no recent chats were found',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ),
          );
        }

        final List<Widget> items = [];

        // We are using a descending query (newest -> oldest) and ListView(reverse: true)
        // to keep the latest message near the keyboard (WhatsApp-style).
        // For date separators: add the separator AFTER the last message of that day
        // (so it doesn't get stuck at the very bottom).
        for (int i = 0; i < docs.length; i++) {
          final  doc = docs[i];

          final Timestamp ts =
          (doc['createdAt'] ?? doc['localCreatedAt'] ?? Timestamp.now())
          as Timestamp;
          final date = ts.toDate();
          final dayKey = DateTime(date.year, date.month, date.day);

          items.add(
            SupportMessageBubble(
              messageId: doc.id,
              text: doc['message'],
              isMe: doc['senderId'] == currentUserId,
              time: Formatters()
                  .formatTimeInMessages(doc['createdAt'] ?? Timestamp.now()),
              status: 'delivered',
              roomId: roomId,
            ),
          );

          DateTime? nextDayKey;
          if (i + 1 < docs.length) {
            final nextDoc = docs[i + 1];
            final Timestamp nextTs =
            (nextDoc['createdAt'] ?? nextDoc['localCreatedAt'] ?? Timestamp.now())
            as Timestamp;
            final nextDate = nextTs.toDate();
            nextDayKey = DateTime(nextDate.year, nextDate.month, nextDate.day);
          }

          final isEndOfThisDay = nextDayKey == null || nextDayKey != dayKey;
          if (isEndOfThisDay) {
            items.add(
              _DateSeparator(
                label: Formatters().formatDateSeparator(ts),
              ),
            );
          }


        }

        return Expanded(
          child: ListView(
            reverse: true,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            children: items,
          ),
        );
      },
    );
  }
}


class SupportMessageBubble extends StatelessWidget {
  const SupportMessageBubble({
    super.key,
    required this.text,
    required this.messageId,
    required this.isMe,
    required this.time,
    required this.status,
    required this.roomId,
  });

  final String messageId;
  final String ? text;
  final bool isMe;
  final String time;
  final String status;
  final String roomId;


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showOptions(context),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 6),
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
              minWidth: 100
          ),
          decoration: BoxDecoration(
            color: isMe ? myMessageBubbleColor : otherMessageBubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: isMe ? const Radius.circular(18) : Radius.zero,
              bottomRight: isMe ? Radius.zero : const Radius.circular(18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
              )
            ],
          ),
          child: IntrinsicWidth(
            child: Column(
              // crossAxisAlignment: CrossAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              // mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    text!,
                    style: isMe ? messageTextStyle : otherMessageTextStyle,
                    textAlign: TextAlign.left,
                    softWrap: true,
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        time,
                        style:  timeTextStyle,
                        textAlign: TextAlign.right,
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        _buildStatusIcon(),
                      ]
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {

    IconData icon;
    Color color;
    double size;

    switch (status) {
      case 'read':
        icon = Icons.done_all;
        color = messageStatusReadBlue;
        size = readIconSize;
        break;
      case 'delivered':
        icon = Icons.done_all;
        color = Colors.grey;
        size = deliveredIconSize;
        break;
      case 'sent':
        icon = Icons.check;
        color = messageStatusGrey;
        size = sentIconSize;
        break;
      case 'sending':
        icon = Icons.access_time;
        color = messageStatusGrey;
        size = sendingIconSize;
        break;
      default:
        icon = Icons.error;
        color = Colors.grey;
        size = 12;
    }

    return Icon(icon, size: size, color: color, );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete', style: TextStyle(color: Colors.white),),
              onTap: () {
                MessageService().deleteMessage(roomId, messageId);
                Navigator.pop(context);
              },
            ),
            if (isMe)
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit (future)', style: TextStyle(color: Colors.white),),
                onTap: () {},
              ),
          ],
        ),
      ),
    );
  }
}

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          const Expanded(
            child: Divider(
              color: dateSeparatorBgColor,
              thickness: 0.8,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: dateSeparatorBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              label,
              style: dateSeparatorTextStyle,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Divider(
              color: dateSeparatorBgColor,
              thickness: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

