// lib/features/search/widgets/search_tiles.dart
//
// Contains: UserSearchTile, HashtagTile, SuggestionTile, SearchHistoryTile,
//           TrendingHashtagRow, SuggestedUserRow, SearchShimmer

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/search_model.dart';
import '../../social/services/social_api_service.dart'; // your existing follow API
import '../../profile/screens/user_profile_screen.dart';
import '../../profile/providers/user_profile_provider.dart';
import '../../profile/models/profile_initial_data.dart';
import 'package:provider/provider.dart';
import '../providers/search_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// UserSearchTile
// ─────────────────────────────────────────────────────────────────────────────

class UserSearchTile extends StatefulWidget {
  final UserResult user;
  final bool showFollowButton;

  const UserSearchTile({
    super.key,
    required this.user,
    this.showFollowButton = true,
  });

  @override
  State<UserSearchTile> createState() => _UserSearchTileState();
}

class _UserSearchTileState extends State<UserSearchTile> {
  bool _followLoading = false;

  Future<void> _toggleFollow() async {
    if (_followLoading) return;
    setState(() => _followLoading = true);

    final nowFollowing = !widget.user.isFollowing;

    // Optimistic update in provider
    context.read<SearchProvider>().toggleFollowUser(widget.user.userId, nowFollowing);

    try {
      final api = SocialApiService();
      if (widget.user.isFollowing) {
        await api.unfollowUser(widget.user.userId);
      } else {
        await api.followUser(widget.user.userId);
      }
    } catch (_) {
      // Revert
      if (mounted) {
        context.read<SearchProvider>().toggleFollowUser(widget.user.userId, !nowFollowing);
      }
    } finally {
      if (mounted) setState(() => _followLoading = false);
    }
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => UserProfileProvider(),
          child: UserProfileScreen(
            userId: widget.user.userId,
            initialData: ProfileInitialData(
              userId:    widget.user.userId,
              userName:  widget.user.userHandle,
              avatar:    widget.user.avatarUrl,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;

    return InkWell(
      onTap: _openProfile,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Avatar
            _Avatar(url: u.avatarUrl, name: u.userName, radius: 24),
            const SizedBox(width: 12),

            // Name + meta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display name + badge row
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          u.userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      if (u.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, size: 15, color: Color(0xFF177E85)),
                      ],
                    ],
                  ),
                  if (u.userHandle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '@${u.userHandle}',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 13,
                      ),
                    ),
                  ],
                  if (u.bio != null && u.bio!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      u.bio!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[400], fontSize: 12.5),
                    ),
                  ],
                  const SizedBox(height: 4),
                  _MetaRow(user: u),
                ],
              ),
            ),

            // Follow button
            if (widget.showFollowButton) ...[
              const SizedBox(width: 12),
              _FollowButton(
                isFollowing:  u.isFollowing,
                isLoading:    _followLoading,
                onTap:        _toggleFollow,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final UserResult user;
  const _MetaRow({required this.user});

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000)    return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.people_outline, size: 13, color: Colors.grey[600]),
        const SizedBox(width: 3),
        Text(
          '${_fmt(user.followersCount)} followers',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        if (user.isMutual) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0xFF177E85).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Follows you',
              style: TextStyle(
                color: Color(0xFF177E85),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _FollowButton extends StatelessWidget {
  final bool isFollowing;
  final bool isLoading;
  final VoidCallback onTap;
  const _FollowButton({required this.isFollowing, required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 34,
      decoration: BoxDecoration(
        color: isFollowing ? Colors.transparent : const Color(0xFF177E85),
        border: Border.all(
          color: isFollowing ? Colors.grey[600]! : const Color(0xFF177E85),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading ? null : onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: isLoading
                  ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: isFollowing ? Colors.grey[400] : Colors.white,
                ),
              )
                  : Text(
                isFollowing ? 'Following' : 'Follow',
                style: TextStyle(
                  color: isFollowing ? Colors.grey[400] : Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? url;
  final String name;
  final double radius;
  const _Avatar({this.url, required this.name, this.radius = 22});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF334155),
      backgroundImage: url != null ? CachedNetworkImageProvider(url!) : null,
      child: url == null
          ? Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.75,
        ),
      )
          : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HashtagTile
// ─────────────────────────────────────────────────────────────────────────────

class HashtagTile extends StatelessWidget {
  final HashtagResult hashtag;
  final VoidCallback? onTap;

  const HashtagTile({super.key, required this.hashtag, this.onTap});

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000)    return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Hash icon bubble
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF177E85).withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text(
                  '#',
                  style: TextStyle(
                    color: Color(0xFF177E85),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Tag + count
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '#${hashtag.tag}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      if (hashtag.isTrending) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.trending_up, size: 11, color: Colors.orange),
                              SizedBox(width: 3),
                              Text(
                                'Trending',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${_fmt(hashtag.postCount)} posts',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                ],
              ),
            ),

            Icon(Icons.chevron_right, color: Colors.grey[700], size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SuggestionTile — dropdown while typing
// ─────────────────────────────────────────────────────────────────────────────

class SuggestionTile extends StatelessWidget {
  final Suggestion suggestion;
  final VoidCallback onTap;

  const SuggestionTile({super.key, required this.suggestion, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isUser    = suggestion.kind == SuggestionKind.user;
    final isHashtag = suggestion.kind == SuggestionKind.hashtag;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Icon / avatar
            if (isUser)
              _Avatar(url: suggestion.avatarUrl, name: suggestion.label, radius: 18)
            else
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isHashtag
                      ? const Color(0xFF177E85).withOpacity(0.12)
                      : Colors.grey[800],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isHashtag ? Icons.tag : Icons.search,
                  size: 17,
                  color: isHashtag ? const Color(0xFF177E85) : Colors.grey[400],
                ),
              ),

            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          suggestion.label,
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isUser && suggestion.isVerified == true) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, size: 13, color: Color(0xFF177E85)),
                      ],
                    ],
                  ),
                  if (suggestion.subLabel != null)
                    Text(suggestion.subLabel!, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
            ),

            // Arrow to fill suggestion into bar
            Icon(Icons.north_west, size: 14, color: Colors.grey[700]),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SearchHistoryTile
// ─────────────────────────────────────────────────────────────────────────────

class SearchHistoryTile extends StatelessWidget {
  final SearchHistoryItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const SearchHistoryTile({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isUser    = item.kind == SuggestionKind.user;
    final isHashtag = item.kind == SuggestionKind.hashtag;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            if (isUser)
              _Avatar(url: item.avatarUrl, name: item.label, radius: 18)
            else
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: Colors.grey[850], shape: BoxShape.circle),
                child: Icon(
                  isHashtag ? Icons.tag : Icons.history,
                  size: 17,
                  color: Colors.grey[500],
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.label,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              onTap: onDelete,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close, size: 16, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shimmer skeleton for loading states
// ─────────────────────────────────────────────────────────────────────────────

class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;
  const _ShimmerBox({required this.width, required this.height, this.radius = 8});

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Color.lerp(const Color(0xFF1E293B), const Color(0xFF334155), _anim.value),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

class SearchUserShimmer extends StatelessWidget {
  const SearchUserShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: 6,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            _ShimmerBox(width: 48, height: 48, radius: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ShimmerBox(width: 140, height: 14),
                  const SizedBox(height: 6),
                  _ShimmerBox(width: 100, height: 12),
                  const SizedBox(height: 6),
                  _ShimmerBox(width: 180, height: 11),
                ],
              ),
            ),
            _ShimmerBox(width: 80, height: 32, radius: 20),
          ],
        ),
      ),
    );
  }
}

class SearchHashtagShimmer extends StatelessWidget {
  const SearchHashtagShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: 6,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            _ShimmerBox(width: 48, height: 48, radius: 14),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ShimmerBox(width: 120, height: 14),
                  const SizedBox(height: 6),
                  _ShimmerBox(width: 80, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}