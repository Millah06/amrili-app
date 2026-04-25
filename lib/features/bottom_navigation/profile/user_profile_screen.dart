import 'package:everywhere/core/constant/app_constants.dart';
import 'package:everywhere/features/bottom_navigation/profile/settings_screeen.dart';
import 'package:everywhere/services/api_service.dart';
import 'package:everywhere/shared/functions/shared_functions.dart';
import 'package:everywhere/shared/widgets/pull_to_reveal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pull_to_reveal_flutter/pull_to_reveal_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../constraints/constants.dart';
import '../../../constraints/vendor_theme.dart';
import '../../../features/social/providers/feed_provider.dart';
import '../../../providers/profile_provider.dart';
import '../../social/models/post_model.dart';
import '../../social/widgets/loader_widget.dart';
import '../../social/widgets/post_card.dart';
import '../../social/widgets/verification_badge.dart';

import '../socialFeature/create_post_screen.dart';
import 'edit_profile.dart';


class UserProfileScreen extends StatefulWidget {


  final String userId;
  final bool isOwnProfile;

  const UserProfileScreen({
    super.key,
    required this.userId,
    this.isOwnProfile = false,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // context.read<FeedProvider>().loadFeed(refresh: true);
    _tabController = TabController(
      length: widget.isOwnProfile ? 4 : 2,
      vsync: this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileProvider = context.read<ProfileProvider>();
      profileProvider.loadUserProfile(widget.userId);
      profileProvider.loadUserPosts(widget.userId);
      if (widget.isOwnProfile) {
        profileProvider.loadSavedPosts();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant UserProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.userId != widget.userId) {
      final profileProvider = context.read<ProfileProvider>();

      profileProvider.loadUserProfile(widget.userId);
      profileProvider.loadUserPosts(widget.userId);

      if (widget.isOwnProfile) {
        profileProvider.loadSavedPosts();

      }

      // Recreate TabController if ownership changed
      if (oldWidget.isOwnProfile != widget.isOwnProfile) {
        _tabController.dispose();
        _tabController = TabController(
          length: widget.isOwnProfile ? 4 : 2,
          vsync: this,
        );
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return PullRevealOverlayWrapper(
      controller: PullToRevealController(),
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Consumer<ProfileProvider>(
          builder: (context, profileProvider, _) {
            if (profileProvider.isLoadingProfile) {

              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF177E85)),
              );
            }

            if (profileProvider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load profile',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => profileProvider.loadUserProfile(widget.userId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF177E85),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final profile = profileProvider.profile;
            if (profile == null) {
              return const Center(
                child: Text('Profile not found', style: TextStyle(color: Colors.white)),
              );
            }

            // Check if profile is private and user is not following
            final isPrivateAndNotFollowing = profile.isPrivate &&
                !profile.isFollowing &&
                !widget.isOwnProfile;

            return NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  // App Bar
                  // lib/screens/user_profile_screen.dart - UPDATE AppBar

                  SliverAppBar(
                    expandedHeight: 0,
                    pinned: true,
                    backgroundColor: const Color(0xFF1E293B),
                    leading: widget.isOwnProfile
                        ? null // No back button for own profile
                        : IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    automaticallyImplyLeading: !widget.isOwnProfile, // Important!
                    actions: widget.isOwnProfile
                        ? [
                      IconButton(
                        icon: const Icon(Icons.settings, color: Colors.white),
                        onPressed: () {

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SettingsScreen(),
                            ),
                          );
                        },
                      ),
                    ]
                        : null,
                    flexibleSpace: FlexibleSpaceBar(
                      background:   SizedBox.shrink()
                    ),
                  ),

                  // Profile Header
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 220,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.topCenter,
                        children: [
                          // Cover Image
                          SizedBox(
                            height: 160,
                            width: double.infinity,
                            child: _buildCoverImage(profile.coverImage, widget.isOwnProfile),
                          ),

                          // Profile Header ABOVE cover
                          Positioned(
                            top: 90, // 200 - (half avatar size)
                            child:  widget.isOwnProfile ?
                            Stack(
                              alignment: Alignment.topCenter,
                              children: [
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color:  Colors.white,
                                          width: 3
                                      )
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF0F172A),
                                        width: 4,
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      radius: 40,
                                      backgroundColor: Colors.grey[700],
                                      backgroundImage: profile.avatar != null
                                          ? CachedNetworkImageProvider(profile.avatar!)
                                          : null,
                                      child: profile.avatar == null
                                          ? Text(
                                        profile.userName[0].toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      )
                                          : null,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(top: 90, left: 80),
                                  child: GestureDetector(
                                    onTap: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const CreatePostScreen(),
                                        ),
                                      );

                                      if (result == true) {
                                        context.read<FeedProvider>().loadFeed(refresh: true);
                                        profileProvider.loadUserPosts(widget.userId);
                                      }
                                    },
                                    child: Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Color(0xFF177E85),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(FontAwesomeIcons.plusCircle,
                                        size: 15, color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                                : Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF0F172A),
                                  width: 4,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 40,
                                backgroundColor: Colors.grey[700],
                                backgroundImage: profile.avatar != null
                                    ? CachedNetworkImageProvider(profile.avatar!)
                                    : null,
                                child: profile.avatar == null
                                    ? Text(
                                  profile.userName[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                )
                                    : null,
                              ),
                            ),
                          ),


                        ],
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        _ProfileHeader(
                          profile: profile,
                          isOwnProfile: widget.isOwnProfile,
                        ),
                        const SizedBox(height: 16),
                        _ProfileStats(profile: profile),
                        const SizedBox(height: 16),

                      ],
                    ),
                  ),

                  // Tabs
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _StickyTabBarDelegate(
                      TabBar(
                        controller: _tabController,
                        labelColor: const Color(0xFF177E85),
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: const Color(0xFF177E85),
                        tabs: widget.isOwnProfile
                            ? const [
                          Tab(text: 'Posts'),
                          Tab(text: 'Saved'),
                          Tab(text: 'Earnings'),
                          Tab(text: 'About'),
                        ]
                            : const [
                          Tab(text: 'Posts'),
                          Tab(text: 'About'),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: isPrivateAndNotFollowing
                  ? _buildPrivateAccountView()
                  : TabBarView(
                controller: _tabController,
                children: widget.isOwnProfile
                    ? [
                  _PostsTab(posts: profileProvider.userPosts, userProfile: profileProvider),
                  _SavedTab(posts: profileProvider.savedPosts, userProfile: profileProvider,),
                  _EarningsTab(profile: profile),
                  _AboutTab(profile: profile),
                ]
                    : [
                  _PostsTab(posts: profileProvider.userPosts, userProfile: profileProvider),
                  _AboutTab(profile: profile),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCoverImage(String? coverImage, bool isOwner) {
    if (coverImage != null) {
     return   CachedNetworkImage(
       imageUrl: coverImage,
       fit: BoxFit.cover,
       width: double.infinity,
       errorWidget: (context, url, error) => Container(
         color: const Color(0xFF1E293B),
       ),
     ) ;

    }
    else { return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF177E85).withOpacity(0.3),
      ),
    );
    }
  }

  Widget _buildPrivateAccountView() {
    return SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            Icon(
              Icons.lock_outline,
              size: 80,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 24),
            Text(
              'This Account is Private',
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Follow to see their posts',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// lib/screens/user_profile_screen.dart - UPDATE _ProfileHeader
class _ProfileHeader extends StatelessWidget {
  final profile;
  final bool isOwnProfile;

  const _ProfileHeader({
    required this.profile,
    required this.isOwnProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                profile.userName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 2),
              VerificationBadge(userId: profile.userId),
            ],
          ),

          // Username handle
          Text(
            '@${profile.displayName}',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 16,
            ),
          ),

          // Bio
          if (profile.bio != null && profile.bio!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              profile.bio!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],

          if (profile.buzEmail != null && profile.buzEmail!.isNotEmpty) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: ( ) {
                SharedFunctions.launchEmail('Hey I find your email from ${AppConstants.appName} app',
                    email: profile.buzEmail);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.email_outlined, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    'Email',
                    style: TextStyle(
                      color: const Color(0xFF177E85),
                      fontSize: 13,
                    ),
                  ),
                ],
              )
            )
          ],

          // Location & Website
          if (profile.location != null || profile.website != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (profile.location != null) ...[
                  Icon(Icons.location_on, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    profile.location!,
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                  if (profile.website != null) const SizedBox(width: 16),
                ],
                if (profile.website != null) ...[
                  Icon(Icons.link, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      SharedFunctions.openUrl(profile.website);
                    },
                    child: Text(
                      profile.website!,
                      style: TextStyle(
                        color: const Color(0xFF177E85),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],

          const SizedBox(height: 20),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isOwnProfile) ...[
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.read<ProfileProvider>().toggleFollow(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: profile.isFollowing
                          ? const Color(0xFF1E293B)
                          : const Color(0xFF177E85),
                      foregroundColor: Colors.white,
                      side: profile.isFollowing
                          ? BorderSide(color: Colors.grey[700]!)
                          : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      profile.isFollowing ? 'Following' : 'Follow',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () {
                    // Navigate to messages
                    // final chatService = ChatRoomService();
                    // final roomId = await chatService.createOrGetP2PRoom(
                    //   myUid: myUid,
                    //   otherUid: otherUid,
                    // );
                    //
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //     builder: (_) => Peer2PeerChat(
                    //       roomId: roomId,
                    //       otherUid: profile,
                    //       otherUserName: profile,
                    //       currentUserUid: profile,
                    //     ),
                    //   ),
                    // );
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey[700]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Message',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final result = await Navigator.push(context,
                          MaterialPageRoute(builder: (context) => EditProfilePage()));

                      if (result == true) {
                        final profileProvider = context.read<ProfileProvider>();
                        profileProvider.loadUserProfile(profile.userId);
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[700]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Edit Profile',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () {
                    // Share profile
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey[700]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Icon(Icons.share, color: Colors.white, size: 20),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileStats extends StatelessWidget {
  final profile;

  const _ProfileStats({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatItem(
            label: 'Posts',
            value: _formatCount(profile.postCount),
          ),
          _StatItem(
            label: 'Followers',
            value: _formatCount(profile.followerCount),
          ),
          _StatItem(
            label: 'Following',
            value: _formatCount(profile.followingCount),
          ),
          if (profile.totalNairaEarned > 0)
            _StatItem(
              label: 'Earned',
              value: '₦${_formatCount(profile.totalNairaEarned.toInt())}',
            ),
        ],
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
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _StickyTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFF1E293B),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) => false;
}

// Posts Tab
class _PostsTab extends StatelessWidget {
  final List<Post> posts;
  final ProfileProvider userProfile;
   

  const _PostsTab({required this.posts, required this.userProfile});

  @override
  Widget build(BuildContext context) {

    print(posts);
    
    if (userProfile.isLoadingPosts) {
      return PostFeedShimmer(itemCount: 4);
    }

    if (posts.isEmpty) {
      return SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.grid_on, size: 64, color: Colors.grey[600]),
              const SizedBox(height: 16),
              Text(
                'No posts yet',
                style: TextStyle(color: Colors.grey[400], fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: posts.length,
      itemBuilder: (context, index) => PostCard(post: posts[index]),
    );
  }
}

// Saved Tab
class _SavedTab extends StatelessWidget {
  final List<Post> posts;
  final ProfileProvider userProfile;

  const _SavedTab({required this.posts, required this.userProfile});

  @override
  Widget build(BuildContext context) {

    if (userProfile.isLoadingSaved) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF177E85)),
      );
    }
    
    if (posts.isEmpty) {
      return SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'No saved posts',
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Save posts to view them later',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: posts.length,
      itemBuilder: (context, index) => PostCard(
          post: posts[index],
        isInProfile: true,
      ),

    );
  }
}

// Earnings Tab
class _EarningsTab extends StatelessWidget {
  final profile;

  const _EarningsTab({required this.profile});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF177E85),
                  const Color(0xFF177E85).withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Earnings',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '₦${profile.totalNairaEarned.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Reward Points',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          profile.totalRewardPointsEarned.toStringAsFixed(0),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'This Week',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '₦${profile.weeklyPoints.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Breakdown
          const Text(
            'Earnings Breakdown',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _EarningCard(
            title: 'From Rewards',
            amount: profile.totalNairaEarned,
            icon: Icons.card_giftcard,
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _EarningCard(
            title: 'Pending Points',
            amount: profile.totalRewardPointsEarned - profile.totalNairaEarned,
            icon: Icons.pending,
            color: Colors.orange,
          ),

          const SizedBox(height: 24),

          // Convert button (if has points)
          if (profile.totalRewardPointsEarned < 1000)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Show convert dialog
                  _showConvertDialog(context, profile.totalRewardPointsEarned.toInt());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF177E85),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Convert Points to Cash',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

void _showConvertDialog(BuildContext context, int availablePoints) {
  final TextEditingController controller = TextEditingController();
  bool isLoading = false;

  int? selectedAmount = 0;

  final List<int> quickAmounts = [2500, 5000, 10000, 50000, 100000];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,

    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          // int enteredAmount = int.tryParse(controller.text) ?? 0;

          int? enteredAmount  = selectedAmount ?? int.tryParse(controller.text);

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:  Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.currency_exchange, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Convert Points',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white
                            ),
                          ),
                          Text(
                            'Available: $availablePoints pts',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                const Text(
                  'Quick Select',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: quickAmounts.map((amount) {
                    final isSelected = selectedAmount == amount;
                    return ChoiceChip(
                      label: Text(kFormatter.format(amount)),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          selectedAmount = selected ? amount : null;
                          controller.clear();
                        });
                      },
                      selectedColor: kButtonColor,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.black87 : Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      backgroundColor: VendorTheme.surface,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                /// Input
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  style: const TextStyle(color: VendorTheme.textPrimary, fontSize: 14),
                  decoration: InputDecoration(

                    hintText: "Enter points to convert",
                    hintStyle: TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: VendorTheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      selectedAmount = null;
                    });
                  },
                ),
                const SizedBox(height: 20),
                /// Conversion Preview
                if (enteredAmount != null && enteredAmount > 0)
                  Text(
                    "You’ll receive ₦$enteredAmount",
                    style: const TextStyle(color: Colors.green),
                  ),

                const SizedBox(height: 20),

                /// Convert Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (enteredAmount == null || enteredAmount <= 0 || isLoading)
                        ? null
                        : () async {
                      setState(() => isLoading = true);

                      try {

                        final api = ApiService();
                        await api.post('/rewards/convert', {
                          "amount": enteredAmount,
                        });

                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                "₦$enteredAmount added to your wallet"),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Conversion failed"),
                          ),
                        );
                      }

                      setState(() => isLoading = false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kButtonColor,
                      disabledBackgroundColor: kButtonColor.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Convert Now", style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black
                    ),),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      );
    },
  );
}

class _EarningCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;

  const _EarningCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₦${amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// About Tab
class _AboutTab extends StatelessWidget {
  final profile;

  const _AboutTab({required this.profile});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (profile.email != null) ...[
            _InfoSection(
              title: 'Email',
              content: profile.email!,
              icon: Icons.email,
            ),
            const SizedBox(height: 20),
          ],
          if (profile.phoneNumber != null) ...[
            _InfoSection(
              title: 'Phone',
              content: profile.phoneNumber!,
              icon: Icons.phone,
            ),
            const SizedBox(height: 20),
          ],
          if (profile.chatTag != null) ...[
            _InfoSection(
              title: 'Chat Tag',
              content: profile.chatTag!,
              icon: Icons.tag,
            ),
            const SizedBox(height: 20),
          ],
          if (profile.transferUID != null) ...[
            _InfoSection(
              title: 'Transfer ID',
              content: profile.transferUID!,
              icon: Icons.account_balance,
            ),
            const SizedBox(height: 20),
          ],

          // Account Info
          _InfoSection(
            title: 'Member Since',
            content: _formatDate(profile.createdAt),
            icon: Icons.calendar_today,
          ),
          const SizedBox(height: 20),

          _InfoSection(
            title: 'Last Active',
            content: timeago.format(profile.lastActiveAt),
            icon: Icons.access_time,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;

  const _InfoSection({
    required this.title,
    required this.content,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF177E85), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}