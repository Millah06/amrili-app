import 'package:everywhere/features/profile/models/profile_display_data.dart';
import 'package:everywhere/features/profile/providers/my_profile_provider.dart';
import 'package:everywhere/features/profile/widgets/earning_tab.dart';
// import 'package:everywhere/features/profile/widgets/profile_header_delegate.dart';
import 'package:everywhere/features/profile/widgets/profile_not_logged_in.dart';
import 'package:everywhere/features/profile/widgets/profile_posts_tab.dart';
import 'package:everywhere/features/social/providers/reward_provider.dart';
import 'package:everywhere/features/social/widgets/loader_widget.dart';
import 'package:everywhere/features/social/widgets/post_card.dart';
import 'package:everywhere/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'edit_profile.dart';
import 'settings_screeen.dart';
import '../../social/screens/create_post_screen.dart';
import '../../social/models/creator_stats_model.dart';
import '../../social/providers/feed_provider.dart';
import '../../social/screens/buy_coins_screen.dart';
import '../../social/widgets/loader_widget.dart';
import '../widgets/about_placeholder.dart';
import '../widgets/about_tab.dart';
import '../widgets/profile_header_delegate.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {

  late TabController _tabController;
  int _selectedTab = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() => _selectedTab = _tabController.index);
    }
  }

  void _init() {
    final userId = context.read<UserProvider>().user?.userId;
    if (userId == null) return;
    final provider = context.read<MyProfileProvider>();
    provider.initialize(userId);
    provider.loadInitialPosts(userId);
    provider.loadSavedPosts();
    context.read<RewardProvider>().loadCreatorStats(); // FIXED: was checking wrong condition
  }

  Future<void> _onRefresh() async {
    final userId = context.read<UserProvider>().user?.userId;
    if (userId == null) return;
    await context.read<MyProfileProvider>().refresh(userId);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final userId = context.watch<UserProvider>().user?.userId;
    if (userId == null) return const ProfileNotLoggedInView();

    return Consumer<MyProfileProvider>(
      builder: (context, provider, _) {
        // Build display data — prefer full profile, fall back to cache
        final displayData = provider.profile != null
            ? ProfileDisplayData.fromProfile(provider.profile!)
            : provider.cached != null
            ? ProfileDisplayData.fromCache(provider.cached!)
            : null;

        return Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          body: NestedScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            headerSliverBuilder: (ctx, _) => [
              // Profile header (shows cached data instantly, hydrates silently)
              SliverPersistentHeader(
                pinned: true,
                delegate: ProfileHeaderDelegate(
                  display: displayData,
                  isOwnProfile: true,
                  isLoading: provider.profileLoading && !provider.hasAnyProfileData,
                  minHeight: 100,
                  // PHASE 9 — header shrinks to fit sparse profiles (no bio /
                  // no meta) instead of reserving empty space.
                  maxHeight: ProfileHeaderDelegate.computeMaxHeight(displayData),
                  onSettings: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen())),
                  onEditProfile: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => EditProfilePage()));
                  },
                  onCreatePost: () async {
                    final result = await Navigator.push<bool>(context,
                        MaterialPageRoute(builder: (_) => const CreatePostScreen()));
                    if (result == true && context.mounted) {
                      context.read<FeedProvider>().loadFeed(refresh: true);
                      provider.refreshPosts(userId);
                    }
                  },
                ),
              ),
              // Sticky tab bar
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyTabBar(
                  TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xFF177E85),
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: const Color(0xFF177E85),
                    tabs: const [
                      Tab(text: 'Posts'),
                      Tab(text: 'Saved'),
                      Tab(text: 'Earnings'),
                      Tab(text: 'About'),
                    ],
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,

              children: [
                // ── Posts tab (paginated + refresh) ──────────────────────
                ProfilePostsTab(
                  posts: provider.posts,
                  isLoading: provider.postsLoading,
                  isLoadingMore: provider.postsLoadingMore,
                  hasMore: provider.hasMorePosts,
                  onLoadMore: () => provider.loadMorePosts(userId),
                  onRefresh: _onRefresh,
                ),
                // ── Saved tab ─────────────────────────────────────────────
                _SavedTab(provider: provider, onRefresh: _onRefresh),
                // ── Earnings tab ──────────────────────────────────────────
                _EarningsTabWrapper(onRefresh: _onRefresh),
                // ── About tab ─────────────────────────────────────────────
                provider.profile != null
                    ? ProfileAboutTab(profile: provider.profile!, onRefresh: _onRefresh, isOwnProfile: true,)
                    : AboutPlaceholder(onRefresh: _onRefresh),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Saved tab
// ─────────────────────────────────────────────────────────────────────────────

class _SavedTab extends StatelessWidget {
  final MyProfileProvider provider;
  final Future<void> Function() onRefresh;
  const _SavedTab({required this.provider, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (provider.savedLoading) {

      return Padding(
        padding: const EdgeInsets.only(top: 13),
        child: const PostFeedShimmer(itemCount: 3),
      );
    }
    return RefreshIndicator(
      color: const Color(0xFF177E85),
      backgroundColor: const Color(0xFF1E293B),
      onRefresh: onRefresh,
      child: provider.savedPosts.isEmpty
          ? ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 60),
          Icon(Icons.bookmark_border, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Center(
              child: Text('No saved posts',
                  style: TextStyle(color: Colors.grey[400], fontSize: 16))),
        ],
      )
          : ListView.builder(
        padding: EdgeInsets.only(top: 5),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: provider.savedPosts.length,
        itemBuilder: (_, i) =>
            PostCard(post: provider.savedPosts[i], isInProfile: true),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Earnings tab wrapper
// ─────────────────────────────────────────────────────────────────────────────

class _EarningsTabWrapper extends StatelessWidget {
  final Future<void> Function() onRefresh;
  const _EarningsTabWrapper({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    // NOTE: import the existing _EarningsTab widget here or inline it.
    // Keep your existing _EarningsTab widget unchanged — just wrap with refresh.
    return RefreshIndicator(
      color: const Color(0xFF177E85),
      backgroundColor: const Color(0xFF1E293B),
      onRefresh: onRefresh,
      child: Consumer<RewardProvider>(
        builder: (ctx, reward, _) {
          // Your existing _EarningsTab content goes here.
          // Just replace the old _EarningsTab widget.
          return Center(
              child: EarningsTab(stats: reward.stats,)
          );
        },
      ),
    );
  }
}



// ─────────────────────────────────────────────────────────────────────────────
// About tab — reuse your existing _AboutTab widget, just add RefreshIndicator
// ─────────────────────────────────────────────────────────────────────────────

class _AboutTab extends StatelessWidget {
  final dynamic profile; // UserProfile
  final Future<void> Function() onRefresh;
  const _AboutTab({required this.profile, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: const Color(0xFF177E85),
      backgroundColor: const Color(0xFF1E293B),
      onRefresh: onRefresh,
      // ↓ Replace with your existing _AboutTab content
      child: const SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Center(
            child: Text('About tab content',
                style: TextStyle(color: Colors.white))),
      ),
    );
  }
}

class _StickyTabBar extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _StickyTabBar(this.tabBar);
  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      Container(color: const Color(0xFF1E293B), child: tabBar);
  @override
  bool shouldRebuild(_StickyTabBar o) => false;
}

