// lib/widgets/post_card.dart - COMPLETE REWRITE FOR REACTIVITY

import 'package:carousel_slider/carousel_slider.dart';
import 'package:everywhere/features/social/widgets/repost_dialog.dart';
import 'package:everywhere/providers/user_provider.dart';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:firebase_auth/firebase_auth.dart';
import '../../../constraints/vendor_theme.dart';
import '../../../providers/profile_provider.dart';
import '../services/social_api_service.dart';
import '../../bottom_navigation/profile/user_profile_screen.dart';
import '../models/post_model.dart';

import '../providers/feed_provider.dart';
import 'reward_bottom_sheet.dart';
import '../widgets/boost_dialog.dart';
import 'comment_sheet.dart';
import 'follow_button.dart';
import 'verification_badge.dart';
import 'post_options_menu.dart';


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

  // static const double _maxImageHeight = 480.0;
  static const double _maxImageHeight = 420.0;
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
    final provider = CachedNetworkImageProvider(url);
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
    String currentPostId = _currentPost.userId;
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
      context.read<ProfileProvider>().updatePostInLists(_currentPost.postId, updatedPost);
    } catch (e) {
      // ProfileProvider might not be available
    }

    widget.onPostUpdated?.call();
  }

  //consider this
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
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: _currentPost.isBoostActive
            ? Border.all(color: Colors.amber, width: 2)
            : null,
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
                  const Icon(Icons.repeat, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    _currentPost.originalUserHandle == null ||
                        _currentPost.originalUserHandle!.isEmpty ?
                    'Reposted from @${_currentPost.originalUserName}' :
                    'Reposted from @${_currentPost.originalUserHandle}' ,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _navigateToProfile(context),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey[700],
                    backgroundImage: _currentPost.userAvatar != null
                        ? CachedNetworkImageProvider(_currentPost.userAvatar!)
                        : null,
                    child: _currentPost.userAvatar == null
                        ? Text(
                      _currentPost.userName[0].toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => _navigateToProfile(context),
                            child: Text(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              _currentPost.userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          VerificationBadgeForPost(badge: _currentPost.topBadge),
                        ],
                      ),
                      if (_currentPost.userHandle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          '@${_currentPost.userHandle}',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      SizedBox(height: 3,),
                      _currentPost.isBoostActive ?
                        // const SizedBox(width: 8),
                        Row(
                          children: [
                            Text(
                              timeago.format(_currentPost.createdAt),
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(width: 4,),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.rocket_launch,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Boosted',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          ],
                        ) :  Text(
                        timeago.format(_currentPost.createdAt),
                        style: TextStyle(
                          color: Colors.grey[500],
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

                        child: const Icon(Icons.more_horiz, color: Colors.white),
                        onTap: () {
                          print(_currentPost.isFollowing);
                          _showOptionsMenu(context);

                        },
                      ),
                      FollowButton(
                        userId: _currentPost.userId,
                        isFollowing: _currentPost.isFollowing,
                        onToggle: _toggleFollow,
                      ),
                    ],
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.more_horiz, color: Colors.white),
                    onPressed: () => _showOptionsMenu(context),
                  ),
              ],
            ),
          ),

          // Caption with hashtags
          if (_currentPost.title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Text(
                _currentPost.title,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildCaptionWithHashtags(_currentPost.text, _currentPost.hashtags),
          ),
          const SizedBox(height: 12,),

          _buildCarousel(),

          // Stats Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                if (_currentPost.viewCount > 0) ...[
                  Icon(Icons.remove_red_eye, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    _formatCount(_currentPost.viewCount),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                if (_currentPost.rewardPointsTotal > 0) ...[
                  const Icon(Icons.stars, size: 16, color: Color(0xFFFFD700)),
                  const SizedBox(width: 4),
                  Text(
                    '₦${_currentPost.rewardPointsTotal.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                if (isOwnPost) ...[
                  Icon(Icons.repeat, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    _formatCount(_currentPost.repostCount),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFF0F172A)),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ActionButton(
                  icon: _currentPost.isLikedByCurrentUser
                      ? Icons.favorite
                      : Icons.favorite_outline,
                  label: _formatCount(_currentPost.likeCount),
                  color: _currentPost.isLikedByCurrentUser
                      ? Colors.red
                      : Colors.grey[400],
                  onTap: _toggleLike,
                ),
                _ActionButton(
                  icon: Icons.chat_bubble_outline,
                  label: _formatCount(_currentPost.commentCount),
                  color: Colors.grey[400],
                  onTap: () => _showComments(context),
                ),
                if (!isOwnPost)
                _ActionButton(
                    icon: Icons.repeat,
                    label: _formatCount(_currentPost.repostCount),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => RepostDialog(post: widget.post),
                      );
                    }
                    ),
                !isOwnPost ?
                  _ActionButton(
                    icon: Icons.card_giftcard,
                    label: _currentPost.rewardCount > 0
                        ? _formatCount(_currentPost.rewardCount)
                        : 'Reward',
                    color: const Color(0xFF177E85),
                    onTap: () => _showRewardSheet(context),
                  ) :
                _ActionButton(icon: Icons.share, label: '', onTap: (

                    ) {
                  _sharePost();
                }),
                if (isOwnPost && !_currentPost.isBoostActive)
                  _ActionButton(
                      icon: Icons.rocket_launch,
                      label: 'Boost Post',
                      onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => BoostDialog(post: widget.post),
                    );
                  })
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sharePost() {
    final shareText = '''
${widget.post.text}

By @${widget.post.userName}

View on Everywhere: https://everywhere.app/post/${widget.post.postId}
''';

    Share.share(shareText);
  }

  void _toggleLike() async {
    // Optimistic update
    final wasLiked = _currentPost.isLikedByCurrentUser;
    final updatedPost = _currentPost.copyWith(
      isLikedByCurrentUser: !wasLiked,
      likeCount: wasLiked ? _currentPost.likeCount - 1 : _currentPost.likeCount + 1,
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
            backgroundColor: Colors.red,
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
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildCaptionWithHashtags(String text, List<String> hashtags) {
    final textSpans = <TextSpan>[];
    final words = text.split(' ');

    for (var word in words) {
      if (word.startsWith('#')) {
        textSpans.add(
          TextSpan(
            text: '$word ',
            style: const TextStyle(
              color: Color(0xFF177E85),
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      } else {
        textSpans.add(
          TextSpan(
            text: '$word ',
            style: const TextStyle(color: Colors.white),
          ),
        );
      }
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 16, height: 1.4),
        children: textSpans,
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  void _navigateToProfile(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(
          userId: _currentPost.userId,
          isOwnProfile: currentUserId == _currentPost.userId,
        ),
      ),
    );
  }

  void _showRewardSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RewardBottomSheet(post: _currentPost),
    );
  }

  void _showComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentSheet(post: _currentPost),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => PostOptionsMenu(
        post: _currentPost,
        onPostUpdated: (updatedPost) {
          _updatePost(updatedPost);
        },
      ),
    );
  }

  //consider this
  Widget _buildCarousel() {
    if (_currentPost.images.isEmpty) return const SizedBox.shrink();

    final hasMultiple = _currentPost.images.length > 1;

    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;

      // Compute display height for the current image only
      final ratio = _imageAspectRatios[_currentImageIndex];
      final naturalHeight = ratio != null ? width / ratio : null;
      final displayHeight = naturalHeight != null
          ? naturalHeight.clamp(120.0, _maxImageHeight)
          : _maxImageHeight; // fallback while ratios are loading
      final exceedsMax = naturalHeight != null && naturalHeight > _maxImageHeight;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        height: displayHeight,
        child: Stack(
          children: [
            PageView.builder(
              itemCount: _currentPost.images.length,
              onPageChanged: (index) =>
                  setState(() => _currentImageIndex = index),
              itemBuilder: (context, index) => GestureDetector(
                onTap: () => _openFullScreen(index),
                child: CachedNetworkImage(
                  imageUrl: _currentPost.images[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  placeholder: (_, __) =>
                      Container(color: const Color(0xFF0F172A)),
                  errorWidget: (_, __, ___) => Container(
                    color: const Color(0xFF0F172A),
                    child: const Icon(Icons.broken_image,
                        size: 48, color: Color(0xFF334155)),
                  ),
                ),
              ),
            ),

            // Dot indicators
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
                      width: isActive ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isActive
                            ? VendorTheme.primary
                            : Colors.white.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }).toList(),
                ),
              ),

            // Tap to expand — only when this image is actually clipped
            if (exceedsMax)
              Positioned(
                bottom: hasMultiple ? 30 : 10,
                right: 12,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fullscreen, color: Colors.white, size: 14),
                      SizedBox(width: 3),
                      Text('Tap to expand',
                          style:
                          TextStyle(color: Colors.white, fontSize: 10)),
                    ],
                  ),
                ),
              ),

            // Image counter badge
            if (hasMultiple)
              Positioned(
                top: 10,
                right: 12,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
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

//consider this
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
          // Image page view (swipe to go next)
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 1.0,
                maxScale: 4.0,
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: widget.images[index],
                    fit: BoxFit.contain,
                    placeholder: (_, __) => const Center(
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    ),
                    errorWidget: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image,
                          color: Colors.white54, size: 60),
                    ),
                  ),
                ),
              );
            },
          ),

          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),

          // Image counter
          if (widget.images.length > 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
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

          // Dot indicators
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
                          : Colors.white.withOpacity(0.4),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color ?? Colors.grey[400]),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color ?? Colors.grey[400],
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}