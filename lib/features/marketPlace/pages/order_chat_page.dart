import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../constraints/vendor_theme.dart';
import '../../social/services/social_api_service.dart';
import '../models/order_model.dart';
import '../providers/order_provider.dart';
import '../providers/vendor_center_provider.dart';

class ChatTab extends StatefulWidget {
  final OrderModel order;
  final String userId;

  const ChatTab({super.key, required this.order, required this.userId});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  final _msgCtrl = TextEditingController();
  final _scroll = ScrollController();
  bool _uploadingImage = false;

  bool get _isUser => widget.order.userId == widget.userId;

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickAndSendImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null || !mounted) return;

    setState(() => _uploadingImage = true);
    try {
      final api = context.read<VendorCenterProvider>().api;
      final SocialApiService apiService = SocialApiService();
      final urls = await apiService.uploadPostImages([picked]);
      if (!mounted) return;
      if (urls.isNotEmpty) {
        await context
            .read<OrderChatProvider>()
            .sendImage(widget.order.id, urls.first);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image upload failed: ${e.toString()}'),
            backgroundColor: VendorTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _sendText() async {
    final chat = context.read<OrderChatProvider>();
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
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.read<OrderChatProvider>();

    return Scaffold(
      backgroundColor: VendorTheme.background,
      appBar: AppBar(
        backgroundColor: VendorTheme.surface,
        elevation: 0,
        titleSpacing: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: VendorTheme.textPrimary),
        ),
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: VendorTheme.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.storefront, color: VendorTheme.textMuted, size: 16),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isUser ? widget.order.vendorName : widget.order.userName,
                  style: const TextStyle(
                      color: VendorTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
                Text(
                  'Order ${widget.order.id.substring(0, 8).toUpperCase()}',
                  style: const TextStyle(
                      color: VendorTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Closed chat warning
          if (widget.order.status.isFinal)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: VendorTheme.surfaceVariant,
              child: const Text(
                'This order is closed. Chat may still be available for a limited time.',
                textAlign: TextAlign.center,
                style: TextStyle(color: VendorTheme.textMuted, fontSize: 11),
              ),
            ),

          // Messages
          Expanded(
            child: StreamBuilder<List<ChatMessageModel>>(
              stream: chat.messageStream(widget.order.id),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: VendorTheme.primary));
                }
                final msgs = snap.data ?? [];
                if (msgs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: VendorTheme.surfaceVariant,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.chat_bubble_outline,
                              color: VendorTheme.textMuted, size: 28),
                        ),
                        const SizedBox(height: 12),
                        const Text('No messages yet',
                            style: TextStyle(
                                color: VendorTheme.textPrimary,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        const Text('Start the conversation',
                            style: TextStyle(
                                color: VendorTheme.textMuted, fontSize: 12)),
                      ],
                    ),
                  );
                }
                _scrollToBottom();
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) => _MessageBubble(
                    msg: msgs[i],
                    isMe: msgs[i].senderId == widget.userId,
                  ),
                );
              },
            ),
          ),

          // Input bar
          Consumer<OrderChatProvider>(
            builder: (_, chat, __) => Container(
              padding: EdgeInsets.fromLTRB(
                  12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
              decoration: const BoxDecoration(
                color: VendorTheme.surface,
                border: Border(top: BorderSide(color: VendorTheme.divider)),
              ),
              child: Row(
                children: [
                  // Image attach button
                  GestureDetector(
                    onTap: (_uploadingImage || chat.sending)
                        ? null
                        : _pickAndSendImage,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: VendorTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: _uploadingImage
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: VendorTheme.primary, strokeWidth: 2),
                      )
                          : const Icon(Icons.image_outlined,
                          color: VendorTheme.textMuted, size: 18),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Text input
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      style: const TextStyle(
                          color: VendorTheme.textPrimary, fontSize: 14),
                      maxLines: 3,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendText(),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle:
                        const TextStyle(color: VendorTheme.textMuted),
                        filled: true,
                        fillColor: VendorTheme.surfaceVariant,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Send button
                  GestureDetector(
                    onTap: (chat.sending || _uploadingImage) ? null : _sendText,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (chat.sending || _uploadingImage)
                            ? VendorTheme.textMuted
                            : VendorTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: chat.sending
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.black, strokeWidth: 2),
                      )
                          : const Icon(Icons.send_rounded,
                          color: Colors.black, size: 18),
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

// ─── Message Bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessageModel msg;
  final bool isMe;

  const _MessageBubble({required this.msg, required this.isMe});

  @override
  Widget build(BuildContext context) {
    if (msg.isAdmin) return _AdminBubble(msg: msg);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
        isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                  color: VendorTheme.surfaceVariant, shape: BoxShape.circle),
              child: const Icon(Icons.storefront,
                  color: VendorTheme.textMuted, size: 14),
            ),
            const SizedBox(width: 8),
          ],
          Column(
            crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMe)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(msg.senderName,
                      style: const TextStyle(
                          color: VendorTheme.textMuted, fontSize: 11)),
                ),
              // Image bubble
              if (msg.hasImage) ...[
                _ImageBubble(imageUrl: msg.imageUrl!, isMe: isMe),
                if (msg.message.isNotEmpty) const SizedBox(height: 4),
              ],
              // Text bubble
              if (msg.message.isNotEmpty)
                Container(
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.65),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? VendorTheme.primary : VendorTheme.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                    border: isMe
                        ? null
                        : Border.all(color: VendorTheme.divider),
                  ),
                  child: Text(
                    msg.message,
                    style: TextStyle(
                        color: isMe ? Colors.black : VendorTheme.textPrimary,
                        fontSize: 13),
                  ),
                ),
              const SizedBox(height: 3),
              Text(
                _time(msg.createdAt),
                style: const TextStyle(
                    color: VendorTheme.textMuted, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _time(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _ImageBubble extends StatelessWidget {
  final String imageUrl;
  final bool isMe;

  const _ImageBubble({required this.imageUrl, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openFullscreen(context),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(14),
          topRight: const Radius.circular(14),
          bottomLeft: Radius.circular(isMe ? 14 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 14),
        ),
        child: Image.network(
          imageUrl,
          width: MediaQuery.of(context).size.width * 0.55,
          height: 180,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) => progress == null
              ? child
              : Container(
            width: MediaQuery.of(context).size.width * 0.55,
            height: 180,
            color: VendorTheme.surfaceVariant,
            child: const Center(
              child: CircularProgressIndicator(
                  color: VendorTheme.primary, strokeWidth: 2),
            ),
          ),
          errorBuilder: (_, __, ___) => Container(
            width: MediaQuery.of(context).size.width * 0.55,
            height: 100,
            color: VendorTheme.surfaceVariant,
            child: const Icon(Icons.broken_image_outlined,
                color: VendorTheme.textMuted),
          ),
        ),
      ),
    );
  }

  void _openFullscreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(imageUrl),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminBubble extends StatelessWidget {
  final ChatMessageModel msg;
  const _AdminBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
                color: VendorTheme.warning.withOpacity(0.2),
                shape: BoxShape.circle),
            child: const Icon(Icons.support_agent,
                color: VendorTheme.warning, size: 14),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Support',
                    style: TextStyle(
                        color: VendorTheme.warning, fontSize: 11)),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  constraints: BoxConstraints(
                      maxWidth:
                      MediaQuery.of(context).size.width * 0.7),
                  decoration: BoxDecoration(
                    color: VendorTheme.warning.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(4),
                      bottomRight: Radius.circular(16),
                    ),
                    border: Border.all(
                        color: VendorTheme.warning.withOpacity(0.3)),
                  ),
                  child: Text(msg.message,
                      style: const TextStyle(
                          color: VendorTheme.warning,
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}