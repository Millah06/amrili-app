import 'package:flutter/material.dart';

import '../theme/chat_theme.dart';

/// Inline attachment tray rendered BELOW the input bar (input stays above it,
/// the way most chat apps do it) instead of a modal sheet over the screen.
/// Show/hide it from the chat screen by toggling a bool and tapping "+".
class ChatAttachPanel extends StatelessWidget {
  const ChatAttachPanel({
    super.key,
    this.onGift,
    this.onRedPacket,
    this.onPhoto,
    this.onCamera,
    this.onDocument,
    this.onAirtime,
    this.onMoney,
    required this.onSelected,
  });

  /// Called after a tile is tapped (so the screen can collapse the panel).
  final VoidCallback onSelected;

  final VoidCallback? onGift;
  final VoidCallback? onRedPacket;
  final VoidCallback? onPhoto;
  final VoidCallback? onCamera;
  final VoidCallback? onDocument;
  final VoidCallback? onAirtime;
  final VoidCallback? onMoney;

  @override
  Widget build(BuildContext context) {
    final items = <_AttachItem>[
      if (onGift != null)
        _AttachItem('Gift', Icons.card_giftcard_rounded,
            const Color(0xFFF59E0B), onGift!),
      if (onRedPacket != null)
        _AttachItem('Red Pocket', Icons.redeem_rounded,
            const Color(0xFFEF4444), onRedPacket!),
      if (onPhoto != null)
        _AttachItem('Gallery', Icons.photo_rounded,
            const Color(0xFF8B5CF6), onPhoto!),
      if (onCamera != null)
        _AttachItem('Camera', Icons.photo_camera_rounded,
            const Color(0xFF0EA5E9), onCamera!),
      if (onDocument != null)
        _AttachItem('Document', Icons.insert_drive_file_rounded,
            const Color(0xFF14B8A6), onDocument!),
      if (onAirtime != null)
        _AttachItem('Airtime', Icons.sim_card_rounded,
            const Color(0xFF22C55E), onAirtime!),
      if (onMoney != null)
        _AttachItem('Send Money', Icons.payments_rounded,
            const Color(0xFF2DD4BF), onMoney!),
    ];

    return Container(
      width: double.infinity,
      color: ChatTheme.surface,
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 16,
        crossAxisSpacing: 8,
        childAspectRatio: 0.82,
        children: items
            .map((it) => _Tile(item: it, onSelected: onSelected))
            .toList(),
      ),
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
  const _Tile({required this.item, required this.onSelected});
  final _AttachItem item;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        onSelected();
        item.onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(item.icon, color: item.color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            item.label,
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
