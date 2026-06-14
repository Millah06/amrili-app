import 'package:everywhere/core/auth/guest_helper.dart';
import 'package:everywhere/features/profile/models/profile_display_data.dart';
import 'package:everywhere/features/profile/models/profile_initial_data.dart';
import 'package:everywhere/features/profile/providers/user_profile_provider.dart';
import 'package:everywhere/features/profile/widgets/profile_posts_tab.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../social/screens/gift_user_screen.dart';
import '../widgets/about_placeholder.dart';
import '../widgets/about_tab.dart';
import '../widgets/profile_header_delegate.dart';

/// Always wrap this in a scoped ChangeNotifierProvider when pushing:
///
///   Navigator.push(context, MaterialPageRoute(
///     builder: (_) => ChangeNotifierProvider(
///       create: (_) => UserProfileProvider(),
///       child: UserProfileScreen(userId: id, initialData: data),
///     ),
///   ));
class UserProfileScreen extends StatefulWidget {
  final String userId;
  final ProfileInitialData? initialData;

  const UserProfileScreen({
    super.key,
    required this.userId,
    this.initialData,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final provider = context.read<UserProfileProvider>();
    if (widget.initialData != null) {
      provider.setInitialData(widget.initialData!);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider.load(widget.userId);
    });
  }

  Future<void> _onRefresh() async {
    await context.read<UserProfileProvider>().refresh(widget.userId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProfileProvider>(
      builder: (context, provider, _) {
        // Build display data — profile > initialData
        final displayData = provider.profile != null
            ? ProfileDisplayData.fromProfile(provider.profile!)
            : widget.initialData != null
            ? ProfileDisplayData.fromInitial(widget.initialData!)
            : null;

        // Error state — only show full error if we have nothing to display
        if (provider.error != null && displayData == null) {
          return Scaffold(
            backgroundColor: const Color(0xFF0F172A),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('Could not load profile',
                      style: TextStyle(color: Colors.grey[400])),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.load(widget.userId),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF177E85)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final isPrivateLocked = provider.isPrivateAndNotFollowing;

        return Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          body: NestedScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            headerSliverBuilder: (ctx, _) => [
              SliverPersistentHeader(
                pinned: true,
                delegate: ProfileHeaderDelegate(
                  display: displayData,
                  isOwnProfile: false,
                  isLoading: provider.profileLoading && displayData == null,
                  minHeight: 100,
                  // PHASE 9 — header shrinks to fit sparse profiles (no bio /
                  // no meta) instead of reserving empty space.
                  maxHeight: ProfileHeaderDelegate.computeMaxHeight(displayData),
                  onBack: () => Navigator.pop(context),
                  onFollow: () => GuestHelper.guardAction(context,
                      action: () => provider.toggleFollow(),
                      reason: 'follow creators'),
                  isFollowing: provider.isFollowing,
                  onMessage: () {/* your existing message logic */},
                  onGift: () => GuestHelper.guardAction(context,
                      action: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => GiftUserScreen(
                          receiverId: displayData?.userId ?? provider.profile!.userId,        // or provider.profile!.userId
                          displayName: displayData?.userName ?? provider.profile!.userName,
                          avatarUrl: displayData?.avatar ?? provider.profile!.avatar,
                        ),
                      )),
                      reason: 'send a gift'),
                ),
              ),
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
                      Tab(text: 'About')
                    ],
                  ),
                ),
              ),
            ],
            body: isPrivateLocked
                ? _PrivateAccountView()
                : TabBarView(
              controller: _tabController,
              children: [
                // Posts tab — paginated + pull to refresh
                ProfilePostsTab(
                  posts: provider.posts,
                  isLoading: provider.postsLoading,
                  isLoadingMore: provider.postsLoadingMore,
                  hasMore: provider.hasMorePosts,
                  onLoadMore: () => provider.loadMorePosts(widget.userId),
                  onRefresh: _onRefresh,
                ),
                // About tab — pull to refresh
                provider.profile != null
                    ? ProfileAboutTab(profile: provider.profile!,
                  onRefresh: _onRefresh, isOwnProfile: false,)
                    : AboutPlaceholder(onRefresh: _onRefresh),
                // RefreshIndicator(
                //   color: const Color(0xFF177E85),
                //   backgroundColor: const Color(0xFF1E293B),
                //   onRefresh: _onRefresh,
                //   // ↓ Replace with your existing _AboutTab
                //   child: ListView(
                //     physics: const AlwaysScrollableScrollPhysics(),
                //     children: const [Text('About content')],
                //   ),
                // ),
              ],
            ),
          ),
        );
      },
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
  Widget build(BuildContext c, double shrinkOffset, bool overlapsContent) =>
      Container(color: const Color(0xFF1E293B), child: tabBar);
  @override
  bool shouldRebuild(_StickyTabBar o) => false;
}

class _PrivateAccountView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 80, color: Colors.grey[600]),
          const SizedBox(height: 24),
          Text('This account is private',
              style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Follow to see their posts',
              style: TextStyle(color: Colors.grey[500], fontSize: 14)),
        ],
      ),
    );
  }
}