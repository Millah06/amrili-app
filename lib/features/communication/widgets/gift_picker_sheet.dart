import 'package:flutter/material.dart';

import '../../social/models/gift_type.dart';
import '../services/gift_service.dart';
import '../services/message_service.dart';
import '../theme/chat_theme.dart';
import 'chat_loading.dart';

/// Bottom sheet to pick and send a coin gift in a 1:1 chat. Shows the live coin
/// balance, the gift catalog, and posts a gift bubble on success.
class GiftPickerSheet extends StatefulWidget {
  const GiftPickerSheet({
    super.key,
    required this.roomId,
    required this.senderId,
    required this.receiverId,
  });

  final String roomId;
  final String senderId;
  final String receiverId;

  static Future<void> show(
    BuildContext context, {
    required String roomId,
    required String senderId,
    required String receiverId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ChatTheme.surfaceHigh,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => GiftPickerSheet(
        roomId: roomId,
        senderId: senderId,
        receiverId: receiverId,
      ),
    );
  }

  @override
  State<GiftPickerSheet> createState() => _GiftPickerSheetState();
}

class _GiftPickerSheetState extends State<GiftPickerSheet> {
  final _gifts = GiftService();
  int? _balance;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    final b = await _gifts.getCoinBalance();
    if (mounted) setState(() => _balance = b);
  }

  Future<void> _send(GiftType gift) async {
    if (_balance != null && _balance! < gift.coins) {
      _toast('Not enough coins — you have $_balance');
      return;
    }
    final result = await runWithChatLoader(
      context,
      () => _gifts.sendUserGift(
          receiverId: widget.receiverId, giftType: gift.id),
    );
    if (!mounted) return;
    if (!result.ok) {
      _toast(result.error ?? 'Could not send gift');
      return;
    }
    // Record the gift as a chat message so both sides see it.
    await MessageService().sendGiftMessage(
      roomId: widget.roomId,
      senderId: widget.senderId,
      receiverId: widget.receiverId,
      giftType: gift.id,
      giftEmoji: gift.emoji,
      giftName: gift.name,
      coins: gift.coins,
    );
    if (mounted) Navigator.of(context).pop();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: ChatTheme.surface),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Send a gift', style: text.titleMedium),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.monetization_on_rounded,
                              size: 16, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 4),
                          Text(_balance?.toString() ?? '…',
                              style: text.labelLarge
                                  ?.copyWith(color: const Color(0xFFF59E0B))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.52,
                  child: GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.92,
                  children: GiftType.allGifts.map((g) {
                    final affordable = _balance == null || _balance! >= g.coins;
                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: affordable ? () => _send(g) : null,
                      child: Opacity(
                        opacity: affordable ? 1 : 0.4,
                        child: Container(
                          decoration: BoxDecoration(
                            color: ChatTheme.surface,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(g.emoji,
                                  style: const TextStyle(fontSize: 34)),
                              const SizedBox(height: 6),
                              Text(g.name,
                                  style: text.labelMedium
                                      ?.copyWith(color: Colors.white)),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.monetization_on_rounded,
                                      size: 12, color: Color(0xFFF59E0B)),
                                  const SizedBox(width: 3),
                                  Text('${g.coins}',
                                      style: text.labelSmall?.copyWith(
                                          color: const Color(0xFFF59E0B))),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
