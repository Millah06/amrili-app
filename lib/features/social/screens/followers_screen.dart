// lib/features/social/screens/followers_screen.dart
//
// Used for BOTH followers and following lists.
// Features: infinite scroll, search within list, pull-to-refresh,
//           follow/unfollow with optimistic UI, empty + error states

import 'package:everywhere/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constraints/vendor_theme.dart';
import '../../search/models/search_model.dart';
import '../../search/providers/search_provider.dart';
import '../../search/widgets/search_tiles.dart';
import '../../social/services/social_api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────────────────────

class FollowersScreen extends StatelessWidget {
  final String userId;
  final String userName;
  final bool isFollowers; // true = Followers, false = Following

  const FollowersScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.isFollowers,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FollowListProvider(
        userId:      userId,
        isFollowers: isFollowers,
      )..init(),
      child: _FollowersBody(
        userName:    userName,
        originalUserId: userId,
        isFollowers: isFollowers,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _FollowersBody extends StatefulWidget {
  final String userName;
  final bool isFollowers;
  final String originalUserId;
  const _FollowersBody({required this.userName, required this.isFollowers,
    required this.originalUserId});

  @override
  State<_FollowersBody> createState() => _FollowersBodyState();
}

class _FollowersBodyState extends State<_FollowersBody> {
  final _scroll      = ScrollController();
  final _searchCtrl  = TextEditingController();
  final _searchFocus = FocusNode();
  bool _searchActive = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final p = context.read<FollowListProvider>();
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
        p.loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VendorTheme.background,
      body: NestedScrollView(
        // Sticky header: app bar + search bar
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned:          true,
            floating:        true,
            backgroundColor: VendorTheme.background,
            elevation:       0,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isFollowers ? 'Followers' : 'Following',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  '@${widget.userName}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: _SearchBar(
                controller: _searchCtrl,
                focusNode:  _searchFocus,
                isActive:   _searchActive,
                onChanged: (v) {
                  context.read<FollowListProvider>().onSearch(v);
                },
                onFocusChange: (v) => setState(() => _searchActive = v),
                onClear: () {
                  _searchCtrl.clear();
                  _searchFocus.unfocus();
                  context.read<FollowListProvider>().onSearch('');
                  setState(() => _searchActive = false);
                },
              ),
            ),
          ),
        ],

        // Scrollable list
        body: Consumer<FollowListProvider>(builder: (context, p, _) {
          if (p.loading) {
            return const SearchUserShimmer();
          }

          if (p.error != null && p.users.isEmpty) {
            return _ErrorState(message: p.error!, onRetry: p.refresh);
          }

          if (p.users.isEmpty) {
            return _EmptyState(
              isFollowers: widget.isFollowers,
              isSearching: _searchCtrl.text.isNotEmpty,
            );
          }

          return RefreshIndicator(
            color:           const Color(0xFF177E85),
            backgroundColor: const Color(0xFF1E293B),
            onRefresh:       p.refresh,
            child: ListView.builder(
              controller:   _scroll,
              padding: const EdgeInsets.only(top: 4, bottom: 80),
              itemCount:    p.users.length + (p.loadingMore ? 1 : 0),
              itemBuilder:  (_, i) {
                if (i == p.users.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF177E85), strokeWidth: 2),
                    ),
                  );
                }

                return _FollowerTile(
                  user: p.users[i],
                  onFollowToggled: p.toggleFollow,
                  isFollowersScreen: widget.isFollowers,
                  originalUserId: widget.originalUserId,
                );
              },
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search bar embedded in AppBar.bottom
// ─────────────────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isActive;
  final ValueChanged<String> onChanged;
  final ValueChanged<bool> onFocusChange;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.isActive,
    required this.onChanged,
    required this.onFocusChange,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: onFocusChange,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive
                  ? const Color(0xFF177E85).withOpacity(0.4)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: TextField(
            controller: controller,
            focusNode:  focusNode,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            onChanged:  onChanged,
            cursorColor: Colors.white,
            decoration: InputDecoration(
              hintText: 'Search…',
              hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
              prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[600], size: 18),
              suffixIcon: controller.text.isNotEmpty
                  ? GestureDetector(
                onTap: onClear,
                child: Icon(Icons.cancel, color: Colors.grey[600], size: 16),
              )
                  : null,
              focusedBorder: OutlineInputBorder(
                borderSide:  BorderSide.none,
                borderRadius: BorderRadius.circular(14),
              ),
              border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(14)
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual follower tile with follow/unfollow
// ─────────────────────────────────────────────────────────────────────────────

class _FollowerTile extends StatefulWidget {
  final UserResult user;
  final bool isFollowersScreen;
  final String originalUserId;
  final void Function(String userId, bool nowFollowing) onFollowToggled;

  const _FollowerTile({required this.user, required this.onFollowToggled,
    required this.isFollowersScreen, required this.originalUserId});

  @override
  State<_FollowerTile> createState() => _FollowerTileState();
}

class _FollowerTileState extends State<_FollowerTile> {
  bool _followLoading = false;

  Future<void> _toggle() async {
    if (_followLoading) return;
    setState(() => _followLoading = true);

    final nowFollowing = !widget.user.isFollowing;
    widget.onFollowToggled(widget.user.userId, nowFollowing); // optimistic

    try {
      final api = SocialApiService();
      if (widget.user.isFollowing) {
        await api.unfollowUser(widget.user.userId);
      } else {
        await api.followUser(widget.user.userId);
      }
    } catch (_) {
      widget.onFollowToggled(widget.user.userId, !nowFollowing); // revert
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Action failed. Please try again.'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _followLoading = false);
    }
  }

  Future<void> _toggleYou() async {
    if (_followLoading) return;
    setState(() => _followLoading = true);

    final nowFollowing = !widget.user.isFollowing;
    widget.onFollowToggled(widget.user.userId, nowFollowing); // optimistic

    try {
      final api = SocialApiService();
      if (widget.isFollowersScreen) {
        await api.unfollowUser(widget.originalUserId);
      } else {
        await api.followUser(widget.originalUserId);
      }
    } catch (_) {
      widget.onFollowToggled(widget.user.userId, !nowFollowing); // revert
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Action failed. Please try again.'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _followLoading = false);
    }
  }

  String _fmtCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000)    return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;

    final currentUserId = context.read<UserProvider>().user?.userId;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Avatar
          _buildAvatar(u),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        u.userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (u.isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, size: 14, color: Color(0xFF177E85)),
                    ],
                  ],
                ),
                if (u.userHandle.isNotEmpty)
                  Text('@${u.userHandle}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                if (u.bio != null && u.bio!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    u.bio!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[400], fontSize: 12.5),
                  ),
                ],
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.people_outline, size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 3),
                    Text(
                      '${_fmtCount(u.followersCount)} followers',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    if (u.isMutual) ...[
                      const SizedBox(width: 8),
                      _MutualBadge(),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Follow button
          currentUserId == u.userId ?
           _FollowButtonSmallYou(
               isFollowing: u.isFollowing,
               isLoading: _followLoading,
               onTap: _toggleYou,
               isFollowersScreen: widget.isFollowersScreen)
              :
          _FollowButtonSmall(
            isFollowing:  u.isFollowing,
            isLoading:    _followLoading,
            onTap:        _toggle,
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(UserResult u) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: const Color(0xFF334155),
          backgroundImage: u.avatarUrl != null
              ? NetworkImage(u.avatarUrl!)
              : null,
          child: u.avatarUrl == null
              ? Text(
            u.userName.isNotEmpty ? u.userName[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          )
              : null,
        ),
        if (u.isVerified)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: const Color(0xFF177E85),
                shape: BoxShape.circle,
                border: Border.all(color: VendorTheme.background, width: 1.5),
              ),
              child: const Icon(Icons.check, size: 10, color: Colors.white),
            ),
          ),
      ],
    );
  }
}

class _MutualBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFF177E85).withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'Follows you',
        style: TextStyle(color: Color(0xFF177E85), fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _FollowButtonSmall extends StatelessWidget {
  final bool isFollowing;
  final bool isLoading;
  final VoidCallback onTap;

  const _FollowButtonSmall({
    required this.isFollowing,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 34,
      decoration: BoxDecoration(
        color: isFollowing ? Colors.transparent : const Color(0xFF177E85),
        border: Border.all(
          color: isFollowing ? Colors.grey[700]! : const Color(0xFF177E85),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap:         isLoading ? null : onTap,
            borderRadius:  BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
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

class _FollowButtonSmallYou extends StatelessWidget {
  final bool isFollowing;
  final bool isLoading;
  final bool isFollowersScreen;
  final VoidCallback onTap;

  const _FollowButtonSmallYou({
    required this.isFollowing,
    required this.isLoading,
    required this.onTap,
    required this.isFollowersScreen,
  });

  @override
  Widget build(BuildContext context) {

    final bool showUnfollow = isFollowersScreen;

    final String buttonText = showUnfollow
        ? 'Unfollow'
        : 'Follow Back';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 34,
      decoration: BoxDecoration(
        color: showUnfollow
            ? Colors.transparent
            : const Color(0xFF177E85),
        border: Border.all(
          color: showUnfollow
              ? Colors.grey[700]!
              : const Color(0xFF177E85),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: isLoading
                ? Center(
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: showUnfollow
                      ? Colors.grey[400]
                      : Colors.white,
                ),
              ),
            )
                : Row(
              mainAxisSize: MainAxisSize.min,
              children: [

                // YOU BADGE
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'You',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                Container(
                  width: 1,
                  height: 14,
                  color: Colors.white24,
                ),

                const SizedBox(width: 8),

                Text(
                  buttonText,
                  style: TextStyle(
                    color: showUnfollow
                        ? Colors.grey[400]
                        : Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
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

// ─────────────────────────────────────────────────────────────────────────────
// Empty / Error states
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isFollowers;
  final bool isSearching;
  const _EmptyState({required this.isFollowers, required this.isSearching});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSearching ? Icons.search_off_rounded : Icons.people_outline_rounded,
            size: 52,
            color: Colors.grey[700],
          ),
          const SizedBox(height: 16),
          Text(
            isSearching
                ? 'No results found'
                : isFollowers
                ? 'No followers yet'
                : 'Not following anyone',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSearching
                ? 'Try a different name or handle'
                : isFollowers
                ? 'When someone follows, they\'ll appear here'
                : 'Accounts followed will appear here',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey[700]),
          const SizedBox(height: 12),
          const Text('Could not load',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(message, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          const SizedBox(height: 18),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF177E85).withOpacity(0.12),
              foregroundColor: const Color(0xFF177E85),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Try again', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// USAGE — open from your profile screen:
//
//   Navigator.push(
//     context,
//     MaterialPageRoute(
//       builder: (_) => FollowersScreen(
//         userId:      profile.userId,
//         userName:    profile.userName,
//         isFollowers: true,  // false for Following
//       ),
//     ),
//   );
// ─────────────────────────────────────────────────────────────────────────────