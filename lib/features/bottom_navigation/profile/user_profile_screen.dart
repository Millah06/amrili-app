import 'package:everywhere/core/auth/guest_helper.dart';
import 'package:everywhere/core/constant/app_constants.dart';
import 'package:everywhere/features/profile/screens/settings_screeen.dart';
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
import '../../../models/user_profile_model.dart';
import '../../../providers/profile_provider.dart';
import '../../communication/services/chat_room_service.dart';
import '../../social/models/creator_stats_model.dart';
import '../../social/models/post_model.dart';
import '../../social/providers/reward_provider.dart';
import '../../social/screens/buy_coins_screen.dart';
import '../../social/widgets/loader_widget.dart';
import '../../social/widgets/post_card.dart';
import '../../social/widgets/verification_badge.dart';

import '../chats/message_screen.dart';
import '../../social/screens/create_post_screen.dart';
import '../../profile/screens/edit_profile.dart';


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
      _loadProfileData();
    });
  }

  void _loadProfileData() {
    final profileProvider = context.read<ProfileProvider>();
    // Always load profile to ensure we have the right one (uses cache)
    profileProvider.loadUserProfile(widget.userId);
    profileProvider.loadUserPosts(widget.userId);
    if (widget.isOwnProfile) {
      profileProvider.loadSavedPosts();
    }
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadProfileData();
      });

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final profileProvider = context.read<ProfileProvider>();
    if (profileProvider.profile == null || profileProvider.profile!.userId != widget.userId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadProfileData();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
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
          final CreatorStats ? giftProvider = context.read<RewardProvider>().stats;
          if (giftProvider == null) {
            context.read<RewardProvider>().loadCreatorStats();
          }
          if (profile == null) {
            return const Center(
              child: Text('Profile not found', style: TextStyle(color: Colors.white)),
            );
          }

          // Check if profile is private and user is not following
          final isPrivateAndNotFollowing = profile.isPrivate &&
              !profile.isFollowing &&
              !widget.isOwnProfile;

          return RefreshIndicator(
              color: const Color(0xFF177E85),
              backgroundColor: const Color(0xFF1E293B),
              onRefresh: () async {
                await profileProvider.loadUserProfile(widget.userId);
                await profileProvider.loadUserPosts(widget.userId);
                if (widget.isOwnProfile) {
                  await profileProvider.loadSavedPosts();
                }
              },
              child: NestedScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  // NEW COMPACT STICKY HEADER
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _ProfileHeaderDelegate(
                      profile: profile,
                      isOwnProfile: widget.isOwnProfile,
                      minHeight: 100,
                      maxHeight: 290,
                    ),
                  ),

                  // Tabs (keep existing)
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
                  _EarningsTab(profile: profile, stats: giftProvider!,),
                  _AboutTab(profile: profile),
                ]
                    : [
                  _PostsTab(posts: profileProvider.userPosts, userProfile: profileProvider),
                  _AboutTab(profile: profile),
                ],
              ),
            ),
          );
        },
      ),
    );
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
      return Center(
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 8,),
                Icon(Icons.grid_on, size: 64, color: Colors.grey[600]),
                const SizedBox(height: 16),
                Text(
                  'No posts yet',
                  style: TextStyle(color: Colors.grey[400], fontSize: 16),
                ),
              ],
            ),
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
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
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

class _EarningsTab extends StatelessWidget {
  final UserProfile profile;
  final CreatorStats? stats;

  const _EarningsTab({required this.profile, this.stats});

  @override
  Widget build(BuildContext context) {
    final rewardProvider = context.watch<RewardProvider>();
    final coinBalance = rewardProvider.coinBalance;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main earnings card - COMPACT
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFFFD700).withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                // Total cash earned
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Cash Earned',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '₦${kFormatter.format(stats?.totalNairaEarned ?? 0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const Divider(height: 32, color: Color(0xFF334155)),

                // Coin balance
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Available Coins',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.stars_rounded,
                          color: Color(0xFFFFD700),
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          kFormatterNo.format(coinBalance),
                          style: const TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 24,
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
          const SizedBox(height: 16,),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Convert to Cash',
                  icon: Icons.swap_horiz_rounded,
                  color: VendorTheme.primary,
                  onTap: () => _showConvertDialog(context, coinBalance),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  label: 'Buy Coins',
                  icon: Icons.add_circle_outline,
                  color: VendorTheme.gold,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BuyCoinsScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),



          // Stats grid - COMPACT
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _StatCard(
                icon: Icons.stars_rounded,
                label: 'Total Coins Earned',
                value: kFormatterNo.format(stats?.totalCoinsEarned ?? 0),
                color: VendorTheme.gold,
              ),
              _StatCard(
                icon: Icons.card_giftcard_rounded,
                label: 'Gifts Received',
                value: kFormatterNo.format(stats?.totalGiftsReceived ?? 0),
                color: VendorTheme.primary,
              ),
              _StatCard(
                icon: Icons.trending_up,
                label: 'This Week',
                value: kFormatterNo.format(stats?.weeklyCoins ?? 0),
                color: VendorTheme.accent,
              ),
              _StatCard(
                icon: Icons.military_tech,
                label: 'Level',
                value: '${stats?.level ?? 1}',
                color: VendorTheme.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.15),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.3)),
        ),
        elevation: 0,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: VendorTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
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

class _ProfileHeaderDelegate extends SliverPersistentHeaderDelegate {
  final UserProfile profile;
  final bool isOwnProfile;
  final double minHeight;
  final double maxHeight;

  _ProfileHeaderDelegate({
    required this.profile,
    required this.isOwnProfile,
    required this.minHeight,
    required this.maxHeight,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final progress = (shrinkOffset / maxExtent).clamp(0.0, 1.0);
    final isCompressed = progress > 0.6;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Cover photo background
        Positioned.fill(
          child: profile.coverImage != null
              ? CachedNetworkImage(
            imageUrl: profile.coverImage!,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => _gradientBackground(),
          )
              : _gradientBackground(),
        ),

        // Dark gradient overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.4),
                  Colors.black.withOpacity(0.8),
                  const Color(0xFF0F172A),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),

        // Content
        AnimatedPositioned(
          duration: const Duration(milliseconds: 200),
          left: 16,
          right: 16,
          top: isCompressed ? 12 : null,
          bottom: isCompressed ? null : 16,
          child: isCompressed
              ? _CompressedHeader(profile: profile, isOwnProfile: isOwnProfile)
              : _ExpandedHeader(profile: profile, isOwnProfile: isOwnProfile),
        ),

        // Back button & Settings (always visible)
        Positioned(
          top: MediaQuery.of(context).padding.top + 4,
          left: 0,
          right: 0,
          bottom: null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!isOwnProfile)
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  )
                else
                  const SizedBox(width: 48),
                if (isOwnProfile)
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
                  )
                else
                  const SizedBox(width: 48),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _gradientBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF177E85).withOpacity(0.4),
            const Color(0xFF1E293B),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_ProfileHeaderDelegate oldDelegate) {
    return profile != oldDelegate.profile || isOwnProfile != oldDelegate.isOwnProfile;
  }
}


class _ExpandedHeader extends StatelessWidget {
  final UserProfile profile;
  final bool isOwnProfile;

  const _ExpandedHeader({required this.profile, required this.isOwnProfile});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar + Name + Stats Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Avatar
            isOwnProfile
                ? Stack(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 42,
                    backgroundColor: Colors.grey[700],
                    backgroundImage: profile.avatar != null
                        ? CachedNetworkImageProvider(profile.avatar!)
                        : null,
                    child: profile.avatar == null
                        ? Text(
                      profile.userName[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
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
                        context.read<ProfileProvider>().loadUserPosts(profile.userId);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF177E85),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            )
                : Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 42,
                backgroundColor: Colors.grey[700],
                backgroundImage: profile.avatar != null
                    ? CachedNetworkImageProvider(profile.avatar!)
                    : null,
                child: profile.avatar == null
                    ? Text(
                  profile.userName[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                )
                    : null,
              ),
            ),

            const SizedBox(width: 16),

            // Stats + Name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name + Verification
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          profile.userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      VerificationBadge(userId: profile.userId),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${profile.displayName}',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Compact stats
                  Row(
                    children: [
                      _MiniStat(
                        value: _formatCount(profile.postCount),
                        label: 'Posts',
                      ),
                      const SizedBox(width: 16),
                      _MiniStat(
                        value: _formatCount(profile.followerCount),
                        label: 'Followers',
                      ),
                      const SizedBox(width: 16),
                      _MiniStat(
                        value: _formatCount(profile.followingCount),
                        label: 'Following',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Bio (if exists)
        if (profile.bio != null && profile.bio!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              profile.bio!,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 14,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        // Location & Website
        if (profile.location != null || profile.website != null
            || (profile.buzEmail != null && profile.buzEmail!.isNotEmpty)) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (profile.buzEmail != null && profile.buzEmail!.isNotEmpty)...[
                GestureDetector(
                    onTap: ( ) {
                      SharedFunctions.launchEmail(
                          'Hey I find your email from ${AppConstants.appName} app',
                          email: profile.buzEmail!);
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
                ),
                if (profile.location != null) const SizedBox(width: 16,)
              ],
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
                    SharedFunctions.openUrl(profile.website!);
                  },
                  child: Text(
                    profile.website!,
                    style: TextStyle(
                      color: const Color(0xFF177E85),
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ],
          ),
          const SizedBox(height: 8),
        ],

        // Action buttons
        Row(
          children: [
            if (!isOwnProfile) ...[
              Expanded(
                child: ElevatedButton(
                  onPressed: () => GuestHelper.guardAction(context,
                      action: () => context.read<ProfileProvider>().toggleFollow(),
                      reason: 'follow creators'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: profile.isFollowing
                        ? const Color(0xFF1E293B)
                        : const Color(0xFF177E85),
                    foregroundColor: Colors.white,
                    side: profile.isFollowing
                        ? BorderSide(color: Colors.grey[700]!)
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text(
                    profile.isFollowing ? 'Following' : 'Follow',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () => GuestHelper.guardAction(context,
                    action: () async {
                      final roomId =
                          await ChatRoomService()
                          .createOrGetChatRoom(otherId: profile.userId,
                      );

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              Peer2PeerChat(
                                roomId: roomId,
                                otherUid: '',
                                otherUserName: '',
                                currentUserUid: '',
                              ),
                        ),
                      );
                    },
                    reason: 'message a user'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey[700]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: const Text(
                  'Message',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ] else ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EditProfilePage()),
                    );
                    if (result == true) {
                      context.read<ProfileProvider>().loadUserProfile(profile.userId);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey[700]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text(
                    'Edit Profile',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey[700]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: const Icon(Icons.share, color: Colors.white, size: 18),
              ),
            ],
          ],
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}


class _CompressedHeader extends StatelessWidget {
  final UserProfile profile;
  final bool isOwnProfile;

  const _CompressedHeader({required this.profile, required this.isOwnProfile});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 30, left: isOwnProfile ? 0 : 35),
      child: Row(
        children: [
          // Small avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[700],
              backgroundImage:
              profile.avatar != null ? CachedNetworkImageProvider(profile.avatar!) : null,
              child: profile.avatar == null
                  ? Text(
                profile.userName[0].toUpperCase(),
                style: const TextStyle(fontSize: 16, color: Colors.white),
              )
                  : null,
            ),
          ),
          const SizedBox(width: 12),

          // Name + verification
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        profile.userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    VerificationBadge(userId: profile.userId),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '@${profile.displayName}',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 13,
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

// Mini stat widget
class _MiniStat extends StatelessWidget {
  final String value;
  final String label;

  const _MiniStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}