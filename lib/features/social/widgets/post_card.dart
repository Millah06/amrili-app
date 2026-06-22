// lib/features/social/widgets/post_card.dart
// =============================================================================
// PHASE 11 — PostCard (survey-aware + polish pass)
// -----------------------------------------------------------------------------
// Changes vs the previous version (everything else is behaviour-identical):
//   1. SURVEY: when `post.isSurvey`, the interactive SurveyCard is rendered in
//      the body, and the duplicate title is suppressed (SurveyCard shows it).
//   2. POLISH: ad-hoc Colors.grey[…] swapped for VendorTheme tokens so the card
//      is colour-cohesive with the rest of the app; a subtle avatar ring; tidier
//      stats/action spacing. No logic, providers, carousel, gallery, gift/boost,
//      or caption behaviour was changed.
// =============================================================================

import 'package:everywhere/core/auth/guest_helper.dart';
import 'package:everywhere/features/social/widgets/repost_dialog.dart';
import 'package:everywhere/providers/user_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:everywhere/shared/widgets/net_image.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../components/formatters.dart';
import '../../../constraints/constants.dart';
import '../../../constraints/vendor_theme.dart';
import '../../profile/providers/my_profile_provider.dart';
import '../../profile/models/profile_initial_data.dart';
import '../../profile/providers/user_profile_provider.dart';
import '../services/social_api_service.dart';
import '../../profile/screens/user_profile_screen.dart';
import '../models/post_model.dart';

import '../providers/feed_provider.dart';
import 'gift_bottom_sheet.dart';
import '../widgets/boost_dialog.dart';
import 'comment_sheet.dart';
import 'follow_button.dart';
import 'verification_badge.dart';
import 'post_options_menu.dart';
import 'survey_card.dart'; // PHASE 11

class PostCard extends StatefulWidget {
  final Post post;
  final VoidCallback? onPostUpdated; // Callback for updates
  final bool isInProfile; // Flag to know context

  const PostCard({
    super.key,
    required this.post,
    this.onPostUpdated,
    this.isInProfile = false,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late Post _currentPost;
  bool _hasIncrementedView = false;

  int _currentImageIndex = 0;

  static const double _maxImageHeight = 400.0;
  final Map<int, double?> _imageAspectRatios = {};

  @override
  void initState() {
    super.initState();
    _currentPost = widget.post;
    _incrementView();
    _preloadAspectRatios();
  }

  @override
  void didUpdateWidget(PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post != widget.post) {
      setState(() {
        _currentPost = widget.post;
      });
      _imageAspectRatios.clear();
      _preloadAspectRatios();
    }
  }

  void _preloadAspectRatios() {
    for (int i = 0; i < _currentPost.images.length; i++) {
      _loadAspectRatio(i, _currentPost.images[i]);
    }
  }

  void _loadAspectRatio(int index, String url) {
    // On web, NetworkImage.resolve() fires XHR which fails against R2's CORS/TLS.
    // NetImage already renders <img> elements there — fall back to _maxImageHeight.
    if (kIsWeb) return;
    final provider = NetworkImage(url);
    final stream = provider.resolve(ImageConfiguration.empty);
    late ImageStreamListener listener;
    listener = ImageStreamListener((info, _) {
      if (mounted) {
        setState(() {
          _imageAspectRatios[index] = info.image.width / info.image.height;
        });
      }
      stream.removeListener(listener);
    });
    stream.addListener(listener);
  }

  Future<void> _incrementView() async {
    if (_hasIncrementedView) return;

    try {
      final apiService = SocialApiService();
      await apiService.incrementPostView(_currentPost.postId);
      _hasIncrementedView = true;
    } catch (e) {
      // Silently fail
    }
  }

  void _updatePost(Post updatedPost) {
    setState(() {
      _currentPost = updatedPost;
    });

    // Update in providers
    try {
      context.read<FeedProvider>().updatePost(_currentPost.postId, updatedPost);
    } catch (e) {
      // FeedProvider might not be available
    }

    try {
      context
          .read<MyProfileProvider>()
          .updatePost(_currentPost.postId, updatedPost);
    } catch (e) {
      // MyProfileProvider might not be available (guest view)
    }

    widget.onPostUpdated?.call();
  }

  void _openFullScreen(int startIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullScreenGallery(
          images: _currentPost.images,
          initialIndex: startIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pov = context.watch<UserProvider>();

    final currentUserId = pov.user?.userId ?? '';
    final isOwnPost = currentUserId == _currentPost.userId;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: VendorTheme.surface, // == 0xFF1E293B, now via the token
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: _currentPost.isBoostActive
            ? Border.all(color: VendorTheme.warning, width: 1.5)
            : Border.all(color: VendorTheme.surfaceVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Repost indicator
          if (_currentPost.isRepost)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 12),
              child: Row(
                children: [
                  const Icon(Icons.repeat, size: 14, color: VendorTheme.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    _currentPost.originalUserHandle == null ||
                        _currentPost.originalUserHandle!.isEmpty
                        ? 'Reposted from @${_currentPost.originalUserName}'
                        : 'Reposted from @${_currentPost.originalUserHandle}',
                    style: const TextStyle(
                      color: VendorTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => openUserProfile(context,
                      userId: _currentPost.userId,
                      userName: _currentPost.userName,
                      avatar: _currentPost.userAvatar),
                  child: Container(
                    // subtle ring lifts the avatar off the slate surface
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: VendorTheme.surfaceVariant, width: 1.5),
                    ),
                    child: NetImage.circle(
                      url: _currentPost.userAvatar,
                      radius: 20,
                      fallback: Text(
                        _currentPost.userName.isNotEmpty
                            ? _currentPost.userName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
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
                            child: GestureDetector(
                              onTap: () => openUserProfile(context,
                                  userId: _currentPost.userId,
                                  userName: _currentPost.userName,
                                  avatar: _currentPost.userAvatar),
                              child: Text(
                                _currentPost.userName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: VendorTheme.textPrimary,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          VerificationBadgeForPost(verified: _currentPost.authorIsVerified),
                        ],
                      ),
                      if (_currentPost.userHandle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          '@${_currentPost.userHandle}',
                          style: const TextStyle(
                            color: VendorTheme.textMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                      const SizedBox(height: 3),
                      _currentPost.isBoostActive
                          ? Row(
                        children: [
                          Text(
                            timeago.format(_currentPost.createdAt),
                            style: const TextStyle(
                              color: VendorTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: VendorTheme.warning,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.rocket_launch,
                                    size: 12, color: Colors.white),
                                SizedBox(width: 4),
                                Text('Boosted',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    )),
                              ],
                            ),
                          ),
                        ],
                      )
                          : Text(
                        timeago.format(_currentPost.createdAt),
                        style: const TextStyle(
                          color: VendorTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Follow button or options menu
                if (!isOwnPost && !_currentPost.isFollowing)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      GestureDetector(
                        child: const Icon(Icons.more_horiz,
                            color: VendorTheme.textPrimary),
                        onTap: () => _showOptionsMenu(context),
                      ),
                      const SizedBox(height: 8),
                      FollowButton(
                        userId: _currentPost.userId,
                        isFollowing: _currentPost.isFollowing,
                        onToggle: () => GuestHelper.guardAction(context,
                            action: _toggleFollow,
                            reason: 'start following creators'),
                      ),
                    ],
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.more_horiz,
                        color: VendorTheme.textPrimary),
                    onPressed: () => _showOptionsMenu(context),
                  ),
              ],
            ),
          ),

          // Caption (title). For SURVEY posts the title is shown by SurveyCard,
          // so we suppress it here to avoid showing it twice.
          if (_currentPost.title.isNotEmpty && !_currentPost.isSurvey)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
              child: Text(
                _currentPost.title,
                style: const TextStyle(
                  color: VendorTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          // Body text + hashtags (context for surveys, the post for standard)
          if (_currentPost.text.isNotEmpty || _currentPost.hashtags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ExpandableCaption(
                text: _currentPost.text,
                hashTags: _currentPost.hashtags,
                hasImage: _currentPost.images.isNotEmpty,
              ),
            ),
          const SizedBox(height: 10),

          _buildCarousel(),

          // PHASE 11 — a survey post renders its interactive survey here (vote →
          // live results), between the body and the stats/actions.
          if (_currentPost.isSurvey) SurveyCard(post: _currentPost),

          // Stats Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: Row(
              children: [
                if (_currentPost.viewCount > 0) ...[
                  const Icon(Icons.remove_red_eye,
                      size: 16, color: VendorTheme.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    _formatCount(_currentPost.viewCount),
                    style: const TextStyle(
                        color: VendorTheme.textMuted, fontSize: 13),
                  ),
                  const SizedBox(width: 16),
                ],
                if (_currentPost.coinTotal > 0) ...[
                  const Icon(Icons.stars_rounded,
                      size: 16, color: VendorTheme.gold),
                  const SizedBox(width: 4),
                  Text(
                    kFormatterNo.format(_currentPost.coinTotal),
                    style: const TextStyle(
                      color: VendorTheme.gold,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                if (isOwnPost && _currentPost.repostCount > 0) ...[
                  const Icon(Icons.repeat,
                      size: 16, color: VendorTheme.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    _formatCount(_currentPost.repostCount),
                    style: const TextStyle(
                        color: VendorTheme.textMuted, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),

          const Divider(height: 1, color: VendorTheme.background),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _ActionButton(
                      icon: _currentPost.isLikedByCurrentUser
                          ? Icons.favorite
                          : Icons.favorite_outline,
                      label: _currentPost.likeCount < 1
                          ? ''
                          : _formatCount(_currentPost.likeCount),
                      color: _currentPost.isLikedByCurrentUser
                          ? VendorTheme.error
                          : VendorTheme.textSecondary,
                      onTap: () => GuestHelper.guardAction(context,
                          action: () => _toggleLike(),
                          reason: 'like people\'s post'),
                    ),
                    const SizedBox(width: 16),
                    _ActionButton(
                      icon: Icons.chat_bubble_outline,
                      label: _currentPost.commentCount < 1
                          ? ''
                          : _formatCount(_currentPost.commentCount),
                      color: VendorTheme.textSecondary,
                      onTap: () => _showComments(context),
                    ),
                    const SizedBox(width: 16),
                    !isOwnPost
                        ? _ActionButton(
                      icon: Icons.repeat,
                      label: _currentPost.repostCount < 1
                          ? ''
                          : _formatCount(_currentPost.repostCount),
                      color: VendorTheme.textSecondary,
                      onTap: () => GuestHelper.guardAction(context,
                          action: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    RepostDialog(post: widget.post),
                              ),
                            );
                          }, reason: 'repost a post'),
                    )
                        : _ActionButton(
                      icon: Icons.share,
                      label: '',
                      color: VendorTheme.textSecondary,
                      onTap: () => _sharePost(),
                    ),
                  ],
                ),
                if (!isOwnPost)
                  GestureDetector(
                    onTap: () => _showRewardSheet(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: VendorTheme.circularProgressColor
                            .withValues(alpha: 0.12), // teal 0xFF177E85
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.card_giftcard_rounded,
                              size: 16,
                              color: VendorTheme.circularProgressColor),
                          const SizedBox(width: 4),
                          Text(
                            _currentPost.giftCount > 0
                                ? _formatCount(_currentPost.giftCount)
                                : 'Gift',
                            style: const TextStyle(
                              color: VendorTheme.circularProgressColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (isOwnPost && !_currentPost.isBoostActive)
                  _ActionButton(
                    icon: Icons.rocket_launch,
                    label: 'Boost',
                    color: VendorTheme.textSecondary,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => BoostDialog(post: widget.post),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sharePost() {
    AppShareHelper.sharePost(
      widget.post.postId,
      widget.post.userName,
      widget.post.text,
    );
  }

  void _toggleLike() async {
    // Optimistic update
    final wasLiked = _currentPost.isLikedByCurrentUser;
    final updatedPost = _currentPost.copyWith(
      isLikedByCurrentUser: !wasLiked,
      likeCount:
      wasLiked ? _currentPost.likeCount - 1 : _currentPost.likeCount + 1,
    );

    _updatePost(updatedPost);

    try {
      final apiService = SocialApiService();
      await apiService.likePost(_currentPost.postId);
    } catch (e) {
      // Revert on error
      _updatePost(_currentPost.copyWith(
        isLikedByCurrentUser: wasLiked,
        likeCount: _currentPost.likeCount,
      ));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to like: $e'),
            backgroundColor: VendorTheme.error,
          ),
        );
      }
    }
  }

  void _toggleFollow() async {
    // Optimistic update
    final wasFollowing = _currentPost.isFollowing;
    final updatedPost = _currentPost.copyWith(isFollowing: !wasFollowing);

    _updatePost(updatedPost);

    try {
      final apiService = SocialApiService();
      if (wasFollowing) {
        await apiService.unfollowUser(_currentPost.userId);
      } else {
        await apiService.followUser(_currentPost.userId);
      }
    } catch (e) {
      // Revert on error
      _updatePost(_currentPost.copyWith(isFollowing: wasFollowing));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to follow: $e'),
            backgroundColor: VendorTheme.error,
          ),
        );
      }
    }
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  void openUserProfile(
      BuildContext context, {
        required String userId,
        String? userName,
        String? avatar,
        String? displayName,
        bool? isVerified,
      }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => UserProfileProvider(),
          child: UserProfileScreen(
            userId: userId,
            initialData: ProfileInitialData(
              userId: userId,
              userName: userName,
              displayName: displayName,
              avatar: avatar,
              isVerified: isVerified,
            ),
          ),
        ),
      ),
    );
  }

  void _showRewardSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (context) => GiftBottomSheet(post: _currentPost),
    );
  }

  void _showComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (context) => CommentSheet(post: _currentPost),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (context) => PostOptionsMenu(
        post: _currentPost,
        onPostUpdated: (updatedPost) => _updatePost(updatedPost),
      ),
    );
  }

  Widget _buildCarousel() {
    if (_currentPost.images.isEmpty) return const SizedBox.shrink();

    final hasMultiple = _currentPost.images.length > 1;

    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;

      final ratio = _imageAspectRatios[_currentImageIndex];
      final naturalHeight = ratio != null ? width / ratio : null;
      final displayHeight = naturalHeight != null
          ? naturalHeight.clamp(120.0, _maxImageHeight)
          : _maxImageHeight;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        height: displayHeight,
        child: Stack(
          children: [
            PageView.builder(
              controller: hasMultiple
                  ? PageController(viewportFraction: 0.92)
                  : PageController(viewportFraction: 1),
              itemCount: _currentPost.images.length,
              onPageChanged: (index) =>
                  setState(() => _currentImageIndex = index),
              itemBuilder: (context, index) => GestureDetector(
                onTap: () => _openFullScreen(index),
                child: Padding(
                  padding: hasMultiple
                      ? EdgeInsets.only(
                      right: index != _currentPost.images.length - 1 ? 8 : 0)
                      : EdgeInsets.zero,
                  child: NetImage(
                    url: _currentPost.images[index],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    borderRadius: BorderRadius.circular(12),
                    backgroundColor: VendorTheme.background,
                  ),
                ),
              ),
            ),
            if (hasMultiple)
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _currentPost.images.asMap().entries.map((entry) {
                    final isActive = _currentImageIndex == entry.key;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: isActive ? 12 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isActive
                            ? VendorTheme.primary
                            : Colors.white.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }).toList(),
                ),
              ),
            if (hasMultiple)
              Positioned(
                top: 10,
                right: 12,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentImageIndex + 1} / ${_currentPost.images.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

class _FullScreenGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _FullScreenGallery({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late int _currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 1.0,
                maxScale: 4.0,
                child: Center(
                  child: NetImage(
                    url: widget.images[index],
                    fit: BoxFit.contain,
                    errorChild: const Center(
                      child: Icon(Icons.broken_image,
                          color: Colors.white54, size: 60),
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),
          if (widget.images.length > 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentIndex + 1} / ${widget.images.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (widget.images.length > 1)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: widget.images.asMap().entries.map((entry) {
                  final isActive = _currentIndex == entry.key;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap(),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 16, color: color ?? VendorTheme.textSecondary),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color ?? VendorTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExpandableCaption extends StatefulWidget {
  final String text;
  final bool hasImage;
  final List<String> hashTags;

  const ExpandableCaption({
    super.key,
    required this.text,
    required this.hasImage,
    this.hashTags = const [],
  });

  @override
  State<ExpandableCaption> createState() => _ExpandableCaptureState();
}

class _ExpandableCaptureState extends State<ExpandableCaption> {
  bool _isExpanded = false;

  late final String _displayText;

  // Mirrors the backend regex: /#[\w]+/g
  static final RegExp _hashtagRegex = RegExp(r'#[\w]+');

  static const int _charsPerLine = 50;

  @override
  void initState() {
    super.initState();
    _displayText = _stripHashtags(widget.text);
  }

  String _stripHashtags(String raw) {
    return raw
        .replaceAll(_hashtagRegex, '')
        .replaceAll(RegExp(r' +'), ' ')
        .trim();
  }

  int get _collapsedMaxLines => widget.hasImage ? 2 : 4;

  int get _charThreshold => _collapsedMaxLines * _charsPerLine;

  bool get _doesOverflow => _displayText.length > _charThreshold;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_displayText.isNotEmpty)
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: _doesOverflow && !_isExpanded
                      ? '${_displayText.substring(0, _charThreshold)}... '
                      : '$_displayText ',
                ),
                if (_doesOverflow)
                  TextSpan(
                    text: _isExpanded ? ' show less' : 'read more',
                    style: const TextStyle(
                      color: VendorTheme.circularProgressColor,
                      fontWeight: FontWeight.bold,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () =>
                          setState(() => _isExpanded = !_isExpanded),
                  ),
              ],
              style: const TextStyle(
                  fontSize: 15, height: 1.4, color: VendorTheme.textPrimary),
            ),
          ),
        if (widget.hashTags.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: widget.hashTags.map((tag) {
              final normalized = tag.startsWith('#') ? tag : '#$tag';
              return Text(
                normalized,
                style: const TextStyle(
                  color: VendorTheme.circularProgressColor,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}