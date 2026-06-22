import 'package:flutter/material.dart';

import '../theme/chat_theme.dart';

/// A clean, professional attachment / utilities sheet for the chat input "+".
/// Tiles only appear when a handler is supplied, so 1:1 and group chats can
/// expose different actions. Open with [ChatAttachSheet.show].
class ChatAttachSheet {
  static Future<void> show(
    BuildContext context, {
    VoidCallback? onGift,
    VoidCallback? onRedPacket,
    VoidCallback? onPhoto,
    VoidCallback? onCamera,
    VoidCallback? onDocument,
    VoidCallback? onAirtime,
    VoidCallback? onMoney,
  }) {
    final items = <_AttachItem>[
      if (onGift != null)
        _AttachItem('Gift', Icons.card_giftcard_rounded,
            const Color(0xFFF59E0B), onGift),
      if (onRedPacket != null)
        _AttachItem('Red Pocket', Icons.redeem_rounded,
            const Color(0xFFEF4444), onRedPacket),
      if (onPhoto != null)
        _AttachItem('Gallery', Icons.photo_rounded,
            const Color(0xFF8B5CF6), onPhoto),
      if (onCamera != null)
        _AttachItem('Camera', Icons.photo_camera_rounded,
            const Color(0xFF0EA5E9), onCamera),
      if (onDocument != null)
        _AttachItem('Document', Icons.insert_drive_file_rounded,
            const Color(0xFF14B8A6), onDocument),
      if (onAirtime != null)
        _AttachItem('Airtime', Icons.sim_card_rounded,
            const Color(0xFF22C55E), onAirtime),
      if (onMoney != null)
        _AttachItem('Send Money', Icons.payments_rounded,
            const Color(0xFF2DD4BF), onMoney),
    ];

    return showModalBottomSheet(
      context: context,
      backgroundColor: ChatTheme.surfaceHigh,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        final text = Theme.of(sheetCtx).textTheme;
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
                    Text('Send', style: text.titleMedium),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 18,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.82,
                      children: items
                          .map((it) => _Tile(item: it, label: it.label))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AttachItem {
  const _AttachItem(this.label, this.icon, this.color, this.onTap);
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class _Tile extends StatelessWidget {
  const _Tile({required this.item, required this.label});
  final _AttachItem item;
  final String label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.of(context).pop();
        item.onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(item.icon, color: item.color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
