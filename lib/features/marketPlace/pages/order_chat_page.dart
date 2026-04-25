import "package:everywhere/providers/user_provider.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import 'package:provider/provider.dart';
import "../../../constraints/vendor_theme.dart";
import "../models/order_model.dart";
import "../providers/order_provider.dart";
import "../widgets/shared_widgets.dart";

// ─── Chat Tab ─────────────────────────────────────────────────────────────────

class ChatTab extends StatefulWidget {
  final OrderModel order;
  final String userId;
  const ChatTab({super.key, required this.order, required this.userId});

  @override
  State<ChatTab> createState() => ChatTabState();
}

class ChatTabState extends State<ChatTab> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.read<OrderChatProvider>();

    bool isUser = widget.order.userId == widget.userId;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: VendorTheme.background.withOpacity(0.5),
        elevation: 0,
        title: Text(isUser ? widget.order.vendorName : widget.order.userName,
            style: const TextStyle(color: VendorTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: VendorTheme.textPrimary),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessageModel>>(
              stream: chat.messageStream(widget.order.id),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: VendorTheme.primary));
                }
                final msgs = snap.data ?? [];
                if (msgs.isEmpty) {
                  return const VEmptyState(
                    icon: Icons.chat_bubble_outline,
                    title: 'No messages yet',
                    subtitle: 'Start the conversation with the vendor',
                  );
                }
                print(isUser);
                _scrollToBottom();
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) => _MessageBubble(
                    msg: msgs[i],
                    isMe: msgs[i].senderId == widget.userId,
                  ),
                );
              },
            ),
          ),
          Consumer<OrderChatProvider>(
            builder: (context, chat, _) => Container(
              padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
              decoration: const BoxDecoration(
                color: VendorTheme.surface,
                border: Border(top: BorderSide(color: VendorTheme.divider)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      style: const TextStyle(color: VendorTheme.textPrimary, fontSize: 14),
                      maxLines: 3,
                      minLines: 1,
                      decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: const TextStyle(color: VendorTheme.textMuted),
                          filled: true,
                          fillColor: VendorTheme.surfaceVariant,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          focusedBorder: InputBorder.none
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: chat.sending
                        ? null
                        : () async {
                      final text = _msgCtrl.text.trim();
                      if (text.isEmpty) return;
                      if (chat.containsPhone(text)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Phone numbers are not allowed'),
                            backgroundColor: VendorTheme.error,
                          ),
                        );
                        return;
                      }
                      _msgCtrl.clear();
                      await chat.sendMessage(widget.order.id, text);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: chat.sending ? VendorTheme.textMuted : VendorTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: chat.sending
                          ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessageModel msg;
  final bool isMe;

  const _MessageBubble({required this.msg, required this.isMe});

  @override
  Widget build(BuildContext context) {
    if (msg.isAdmin) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: VendorTheme.warning.withOpacity(0.3), shape: BoxShape.circle),
              child: const Icon(Icons.support_agent, color: VendorTheme.warning, size: 14),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text('Support',
                      style: const TextStyle(color: VendorTheme.warning, fontSize: 11)),
                ),
                Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: VendorTheme.warning.withOpacity(0.15),
                    // borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: VendorTheme.warning.withOpacity(0.4)),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(4),
                      bottomRight: Radius.circular(16),
                    ),

                  ),
                  child: Text(msg.message,
                      style: const TextStyle(color: VendorTheme.warning, fontSize: 12, fontWeight: FontWeight.w500)),
                ),
                const SizedBox(height: 3),
                Text(
                  msg.createdAt != null
                      ? '${msg.createdAt!.hour.toString().padLeft(2, '0')}:${msg.createdAt!.minute.toString().padLeft(2, '0')}'
                      : '',
                  style: const TextStyle(color: VendorTheme.textMuted, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      );
    }
    // if (msg.isAdmin) {
    //   return Padding(
    //     padding: const EdgeInsets.symmetric(vertical: 6),
    //     child: Container(
    //       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    //       decoration: BoxDecoration(
    //         color: VendorTheme.warning.withOpacity(0.15),
    //         borderRadius: BorderRadius.circular(20),
    //         border: Border.all(color: VendorTheme.warning.withOpacity(0.4)),
    //       ),
    //       child: Column(
    //         crossAxisAlignment: CrossAxisAlignment.start,
    //         children: [
    //           Row(
    //             mainAxisSize: MainAxisSize.min,
    //             children: [
    //               const Icon(Icons.support_agent, color: VendorTheme.warning, size: 14),
    //               const SizedBox(width: 6),
    //               Text('Support: ${msg.message}',
    //                   style: const TextStyle(color: VendorTheme.warning, fontSize: 12, fontWeight: FontWeight.w500)),
    //             ],
    //           ),
    //         ],
    //       ),
    //     ),
    //   );
    // }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: VendorTheme.surfaceVariant, shape: BoxShape.circle),
              child: const Icon(Icons.storefront, color: VendorTheme.textMuted, size: 14),
            ),
            const SizedBox(width: 8),
          ],
          Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMe)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(msg.senderName,
                      style: const TextStyle(color: VendorTheme.textMuted, fontSize: 11)),
                ),
              Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isMe ? VendorTheme.primary : VendorTheme.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                  border: isMe ? null : Border.all(color: VendorTheme.divider),
                ),
                child: Text(msg.message,
                    style: TextStyle(
                        color: isMe ? Colors.white : VendorTheme.textPrimary,
                        fontSize: 13)),
              ),
              const SizedBox(height: 3),
              Text(
                msg.createdAt != null
                    ? '${msg.createdAt!.hour.toString().padLeft(2, '0')}:${msg.createdAt!.minute.toString().padLeft(2, '0')}'
                    : '',
                style: const TextStyle(color: VendorTheme.textMuted, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}