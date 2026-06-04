import 'package:everywhere/core/auth/guest_helper.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../components/formatters.dart';
import '../../constraints/constants.dart';
import '../social/providers/feed_provider.dart';
import '../../providers/profile_provider.dart';
import '../social/providers/reward_provider.dart';
import '../../services/brain.dart';
import '../../shared/widgets/pull_to_reveal.dart';
import '../auth/security_step1_screen.dart';
import '../auth/security_step2_screen.dart';
import '../search/screens/search_screen.dart';
import '../social/widgets/compact_leaderboard.dart';
import '../social/widgets/loader_widget.dart';
import '../social/widgets/post_card.dart';
import '../social/widgets/search_widget.dart';
import '../social/screens/create_post_screen.dart';
import 'package:pull_to_reveal_flutter/pull_to_reveal_flutter.dart';

class FeedScreen extends StatefulWidget {

  final Function(bool isScrollingDown)? onScrollDirectionChanged;

  const FeedScreen({super.key, required this.onScrollDirectionChanged});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  double _lastOffset = 0;
  bool _showToggle = true;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
    _checkBuild();
  }

  void _checkBuild() {
    final pov = Provider.of<Brain>(context, listen: false);
    if (pov.buildNumberFromFireStore > AppLinkHandler.buildNumber) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        bool mandatory = pov.mandatory;
        List<String> newFeatures = pov.whatIsNew;
        showDialog(
          context: context,
          barrierDismissible: !mandatory,
          builder: (context) => AlertDialog(
            icon: Icon(Icons.upcoming_outlined, color: kErrorIconColor, size: 30,),
            actionsPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            title: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('NEW VERSION',  style: kAlertTitle.copyWith(fontSize: 16, fontWeight: FontWeight.w900)),
                      SizedBox(width: 5,),
                      Text('(${pov.versionName})', style: kAlertTitle.copyWith(color: Colors.white70, fontSize: 13),)
                    ],
                  ),
                  SizedBox(height: 10,),
                  Text('An Update ${mandatory ? 'Required' : 'Recommended'}', style: kAlertTitle,),
                ],
              ),
            ),
            backgroundColor: kCardColor,
            alignment: Alignment.center,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('What\'s new?',
                      style: kAlertContent.copyWith(fontWeight: FontWeight.w900)),
                  SizedBox(height: 10),
                  if (newFeatures.isNotEmpty)
                    ...List.generate(newFeatures.length, (index) {
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('${index + 1}. ${newFeatures[index]}',
                            style: GoogleFonts.raleway(fontSize: 12,  ), textAlign: TextAlign.center,),
                        ),
                      );
                    }),
                ],
              ),
            ),
            actions: [
              mandatory ? Center(
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      elevation: 4,
                      padding: EdgeInsets.symmetric(
                          vertical: 10, horizontal: 30),
                      side: BorderSide(
                          color: kButtonColor
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)
                      ),
                    ),
                    onPressed: ()  async {
                      AppLinkHandler.openInPlayStore();
                    },
                    child: Text('Update on play store', style: GoogleFonts.raleway(color: Colors.white, fontSize: 13),)
                ),
              ) :
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kButtonColor,
                          elevation: 4,
                          padding: EdgeInsets.symmetric(vertical:
                          10, horizontal: 30),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text('Not now', style: GoogleFonts.raleway(color: Colors.black, fontSize: 11),)
                    ),
                    SizedBox(height: 10,),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          elevation: 4,
                          padding: EdgeInsets.symmetric(
                              vertical: 10, horizontal: 30),
                          side: BorderSide(
                              color: kButtonColor
                          ),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)
                          ),
                        ),
                        onPressed: ()  async {
                          AppLinkHandler.openInPlayStore();
                        },
                        child: Text('Update on Play Store',
                          style: GoogleFonts.raleway(color: Colors.white, fontSize: 13),)
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      });

    }
  }

  void _loadInitialData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeedProvider>().loadFeed();
      context.read<RewardProvider>().loadLeaderboard();
      context.read<RewardProvider>().loadCreatorStats();
    });
  }

  void _onScroll() {

    final offset = _scrollController.offset;

    // ===== SCROLL DIRECTION (with threshold) =====
    if (offset > _lastOffset + 10) {
      // scrolling DOWN
      if (_showToggle) {
        setState(() => _showToggle = false);
        widget.onScrollDirectionChanged?.call(true); // 🔥 notify parent
      }
    } else if (offset < _lastOffset - 10) {
      // scrolling UP
      if (!_showToggle) {
        setState(() => _showToggle = true);
        widget.onScrollDirectionChanged?.call(false); // 🔥 notify parent
      }
    }

    _lastOffset = offset;

    // ===== PAGINATION =====
    final maxScroll = _scrollController.position.maxScrollExtent;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<FeedProvider>().loadFeed();
    }

  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final profile =  Provider.of<ProfileProvider>(context);
    return PullRevealOverlayWrapper(
      controller: PullToRevealController(),
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFF1E293B),
          title:    Text(
            'Feed',
            style: kTopAppbars.copyWith(
                fontFamily:  'DejaVu Sans', fontSize: 23),
          ),
          actions: [
            IconButton(onPressed: ( ) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => SearchScreen()));
            }, icon: Icon(Icons.search)),
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.plusCircle, color: Colors.white),
              onPressed: () async {

                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreatePostScreen(),
                  ),
                );

                if (result == true) {
                  context.read<FeedProvider>().loadFeed(refresh: true);
                }
              },
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              children: [
                // Feed Type Toggle
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _showToggle ? _FeedTypeToggle() : const SizedBox(),
                ),

                // Feed Content
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await context.read<FeedProvider>().forceRefresh();
                      await context.read<RewardProvider>().loadLeaderboard();
                    },
                    color: const Color(0xFF177E85),
                    backgroundColor: const Color(0xFF1E293B),
                    child: CustomScrollView(
                      controller: _scrollController,
                      slivers: [
                        // Compact Leaderboard
                        const SliverToBoxAdapter(
                          child: CompactLeaderboard(),
                        ),
                        // Posts List
                        Consumer<FeedProvider>(
                          builder: (context, feedProvider, _) {
                            if (feedProvider.isLoading && feedProvider.posts.isEmpty) {
                              return const SliverToBoxAdapter(
                                  child: PostFeedShimmer(itemCount: 4),
                                );
                            }
                            if (feedProvider.error != null && feedProvider.posts.isEmpty) {
                              return SliverFillRemaining(
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        size: 64,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Failed to load feed',
                                        style: TextStyle(color: Colors.grey[400]),
                                      ),
                                      const SizedBox(height: 8),
                                      ElevatedButton(
                                        onPressed: () => feedProvider.loadFeed(refresh: true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF177E85),
                                        ),
                                        child: const Text('Retry'),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            if (feedProvider.posts.isEmpty) {
                              return SliverFillRemaining(
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.feed_outlined,
                                        size: 64,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        feedProvider.currentFeedType == FeedType.following
                                            ? 'Follow users to see their posts'
                                            : 'No posts yet',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey[400],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        feedProvider.currentFeedType == FeedType.following
                                            ? 'Discover creators in For You'
                                            : 'Be the first to share something!',
                                        style: TextStyle(color: Colors.grey[500]),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            return SliverList(
                              delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                  if (index < feedProvider.posts.length) {
                                    return PostCard(post: feedProvider.posts[index]);
                                  } else if (feedProvider.hasMore) {
                                    return const Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: Color(0xFF177E85),
                                        ),
                                      ),
                                    );
                                  } else {
                                    return Padding(
                                      padding: const EdgeInsets.all(24.0),
                                      child: Center(
                                        child: Text(
                                          "You've reached the end",
                                          style: TextStyle(color: Colors.grey[500]),
                                        ),
                                      ),
                                    );
                                  }
                                },
                                childCount: feedProvider.posts.length +
                                    (feedProvider.hasMore ? 1 : 1),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
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

class _FeedTypeToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<FeedProvider>(
      builder: (context, feedProvider, _) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: _ToggleButton(
                  label: 'For You',
                  isSelected: feedProvider.currentFeedType == FeedType.forYou,
                  onTap: () => feedProvider.switchFeedType(FeedType.forYou),
                ),
              ),
              Expanded(
                child: _ToggleButton(
                  label: 'Following',
                  isSelected: feedProvider.currentFeedType == FeedType.following,
                  onTap: () => GuestHelper.guardAction(context, action: () => feedProvider.switchFeedType(FeedType.following),
                      reason: 'see post\'s of following users'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF177E85) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white38,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}