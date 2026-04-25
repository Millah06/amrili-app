import 'package:flutter/material.dart';

import '../../../../constraints/constants.dart';
import '../../../communication/services/message_service.dart';


class MessageBubble extends StatelessWidget {
  const MessageBubble( this.amount, {
    super.key,
    required this.text,
    required this.messageId,
    required this.type,
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
  final String ? type;
  final String ? amount;

  @override
  Widget build(BuildContext context) {
    if (type == 'moneyTransfer') {

      return GestureDetector(
        onLongPress: () => _showOptions(context),
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 6),
            width: MediaQuery.of(context).size.width * 0.75,
            height: 100,
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
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, size: 40,),
                        SizedBox(width: 20,),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$kNaira${kFormatter.format(double.parse(amount!))}',
                              style: isMe ? messageTextStyle.copyWith( fontSize: 20,
                                fontWeight: FontWeight.w900,) : otherMessageTextStyle.copyWith( fontSize: 20,
                                fontWeight: FontWeight.w900,),
                              textAlign: TextAlign.left,
                              softWrap: true,
                            ),
                            Text(status,  style: isMe ? messageTextStyle : otherMessageTextStyle,)
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Divider(),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('NexPay Transfer', style: timeTextStyle,),
                      Row(
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

                    ],
                  ),
                  Visibility(
                      visible: status != 'Accepted',
                      child: ElevatedButton(style: ElevatedButton.styleFrom(
                        // Use fixedSize to set exact dimensions
                        fixedSize: Size(3, 5),

                        // Alternatively, use minimumSize to set a minimum threshold
                        // minimumSize: Size(50, 30),

                        // Reduce padding
                        padding: EdgeInsets.zero,
                      ),
                          onPressed: isMe ? ( ) {} : () {} , child: Text(isMe ? 'Cancel' : 'Accept'))
                  )
                ],
              ),
            ),
          ),
        ),
      );

    }
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