// lib/features/search/screens/search_screen.dart
//
// Full search screen:  idle → suggesting → results
// Tabs: Top | People | Posts | Tags
// Reuses existing PostCard widget

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constraints/vendor_theme.dart';
import '../models/search_model.dart';
import '../providers/search_provider.dart';
import '../widgets/search_tiles.dart';
import '../../social/widgets/post_card.dart';   // ← your existing PostCard

// ─────────────────────────────────────────────────────────────────────────────
// Entry point — wrap with ChangeNotifierProvider at nav level or here
// ─────────────────────────────────────────────────────────────────────────────

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SearchProvider(),
      child: const _SearchScreenBody(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SearchScreenBody extends StatefulWidget {
  const _SearchScreenBody();

  @override
  State<_SearchScreenBody> createState() => _SearchScreenBodyState();
}

class _SearchScreenBodyState extends State<_SearchScreenBody>
    with SingleTickerProviderStateMixin {
  final _focusNode  = FocusNode();
  final _controller = TextEditingController();
  late  TabController _tabController;

  static const _tabs = SearchTab.values;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this)
      ..addListener(_onTabChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SearchProvider>()
        .onQueryChanged(''); // trigger trending load
    });
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    context.read<SearchProvider>().switchTab(_tabs[_tabController.index]);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VendorTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _SearchBar(
              controller: _controller,
              focusNode:  _focusNode,
              onClear:    _clearSearch,
            ),
            Expanded(
              child: Consumer<SearchProvider>(
                builder: (context, p, _) {
                  switch (p.phase) {
                    case SearchPhase.idle:
                      return _IdleView();
                    case SearchPhase.suggesting:
                      return _SuggestionsView(
                        controller: _controller,
                        focusNode:  _focusNode,
                      );
                    case SearchPhase.results:
                      return _ResultsView(tabController: _tabController);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _clearSearch() {
    _controller.clear();
    _focusNode.unfocus();
    context.read<SearchProvider>().clearSearch();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search Bar
// ─────────────────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SearchProvider>();
    final isActive = p.phase != SearchPhase.idle;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.fromLTRB(isActive ? 8 : 16, 12, 16, 10),
      child: Row(
        children: [
          // Back button (visible only when active)
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: isActive
                ? GestureDetector(
              onTap: onClear,
              child: const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
              ),
            )
                : const SizedBox.shrink(),
          ),

          // Text field
          Expanded(
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: focusNode.hasFocus
                      ? const Color(0xFF177E85).withOpacity(0.5)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: TextField(
                controller:   controller,
                focusNode:    focusNode,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                keyboardType: TextInputType.webSearch,
                textInputAction: TextInputAction.search,
                onChanged: (v) => context.read<SearchProvider>().onQueryChanged(v),
                onSubmitted: (v) {
                  if (v.trim().isNotEmpty) {
                    focusNode.unfocus();
                    context.read<SearchProvider>().submitSearch(v.trim());
                  }
                },
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  hintText: 'Search people, posts, tags…',
                  hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[600], size: 20),
                  suffixIcon: controller.text.isNotEmpty
                      ? GestureDetector(
                    onTap: onClear,
                    child: Icon(Icons.cancel, color: Colors.grey[600], size: 18),
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
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Idle view — trending + suggested users
// ─────────────────────────────────────────────────────────────────────────────

class _IdleView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SearchProvider>(builder: (context, p, _) {
      if (!p.trendingLoaded) {
        return const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF177E85), strokeWidth: 2,
          ),
        );
      }

      // Loaded but nothing to show — don't leave user staring at blank screen
      final hasContent = p.recentSearches.isNotEmpty ||
          p.trendingHashtags.isNotEmpty ||
          p.suggestedUsers.isNotEmpty;

      if (!hasContent) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_rounded, size: 52, color: Colors.grey[700]),
              const SizedBox(height: 14),
              const Text(
                'Search people, posts & tags',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Start typing to explore',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            ],
          ),
        );
      }

      return CustomScrollView(
        slivers: [
          // Recent searches
          if (p.recentSearches.isNotEmpty) ...[
            _SliverHeader(
              title: 'Recent',
              action: 'Clear all',
              onAction: () => context.read<SearchProvider>().clearHistory(),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                    (_, i) {
                  final item = p.recentSearches[i];
                  return SearchHistoryTile(
                    item: item,
                    onTap: () {
                      // Re-run search from history
                      final provider = context.read<SearchProvider>();
                      provider.submitSearch(item.label);
                    },
                    onDelete: () =>
                        context.read<SearchProvider>().deleteHistoryItem(item.id),
                  );
                },
                childCount: p.recentSearches.length,
              ),
            ),
            const _Divider(),
          ],

          // Trending hashtags
          if (p.trendingHashtags.isNotEmpty) ...[
            const _SliverHeader(title: 'Trending'),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                    (_, i) => HashtagTile(hashtag: p.trendingHashtags[i]),
                childCount: p.trendingHashtags.length.clamp(0, 8),
              ),
            ),
            const _Divider(),
          ],

          // Suggested users
          if (p.suggestedUsers.isNotEmpty) ...[
            const _SliverHeader(title: 'Suggested for you'),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                    (_, i) => UserSearchTile(user: p.suggestedUsers[i]),
                childCount: p.suggestedUsers.length,
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Suggestions dropdown while typing
// ─────────────────────────────────────────────────────────────────────────────

class _SuggestionsView extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;

  const _SuggestionsView({required this.controller, required this.focusNode});

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchProvider>(builder: (context, p, _) {
      final all = p.suggestions;
      if (all.isEmpty) {
        return const Center(
          child: Text('Type to search…',
              style: TextStyle(color: Colors.grey, fontSize: 14)),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.only(top: 4),
        itemCount: all.length,
        itemBuilder: (_, i) {
          final s = all[i];
          return SuggestionTile(
            suggestion: s,
            onTap: () {
              controller.text = s.label;
              focusNode.unfocus();
              context.read<SearchProvider>().submitSearch(s.label);
            },
          );
        },
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Results view with tabs
// ─────────────────────────────────────────────────────────────────────────────

class _ResultsView extends StatelessWidget {
  final TabController tabController;
  static const _tabs = SearchTab.values;

  const _ResultsView({required this.tabController});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab bar
        Container(
          color: VendorTheme.background,
          child: TabBar(
            controller:   tabController,
            isScrollable: false,
            labelColor:   const Color(0xFF177E85),
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            indicatorColor:   const Color(0xFF177E85),
            indicatorWeight:  2.5,
            indicatorSize:    TabBarIndicatorSize.label,
            dividerColor: const Color(0xFF1E293B),
            tabs: _tabs.map((t) => Tab(text: t.label)).toList(),
          ),
        ),

        // Tab bodies
        Expanded(
          child: TabBarView(
            controller: tabController,
            children:   _tabs.map((t) => _TabBody(tab: t)).toList(),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual tab body
// ─────────────────────────────────────────────────────────────────────────────

class _TabBody extends StatefulWidget {
  final SearchTab tab;
  const _TabBody({required this.tab});

  @override
  State<_TabBody> createState() => _TabBodyState();
}

class _TabBodyState extends State<_TabBody>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Consumer<SearchProvider>(builder: (context, p, _) {
      final state = p.loadState(widget.tab);
      final error = p.error(widget.tab);

      // Initial loading
      if (state == LoadState.loading) {
        return _buildShimmer();
      }

      // Error
      if (state == LoadState.error && _isEmpty(p)) {
        return _ErrorState(
          message: error ?? 'Something went wrong',
          onRetry:  p.refresh,
        );
      }

      // Empty results
      if (_isEmpty(p) && state == LoadState.idle) {
        return _EmptyState(tab: widget.tab, query: p.query);
      }

      return RefreshIndicator(
        color: const Color(0xFF177E85),
        backgroundColor: const Color(0xFF1E293B),
        onRefresh: p.refresh,
        child: _buildList(p),
      );
    });
  }

  Widget _buildList(SearchProvider p) {
    switch (widget.tab) {
      case SearchTab.top:      return _TopList(result: p.topResult!);
      case SearchTab.users:    return _UserList(users: p.userResults, provider: p);
      case SearchTab.posts:    return _PostList(posts: p.postResults, provider: p);
      case SearchTab.hashtags: return _HashtagList(hashtags: p.hashtagResults, provider: p);
    }
  }

  Widget _buildShimmer() {
    switch (widget.tab) {
      case SearchTab.users:
      case SearchTab.top:
        return const SearchUserShimmer();
      case SearchTab.hashtags:
        return const SearchHashtagShimmer();
      case SearchTab.posts:
        return const SearchUserShimmer(); // generic skeleton
    }
  }

  bool _isEmpty(SearchProvider p) {
    switch (widget.tab) {
      case SearchTab.top:      return p.topResult == null;
      case SearchTab.users:    return p.userResults.isEmpty;
      case SearchTab.posts:    return p.postResults.isEmpty;
      case SearchTab.hashtags: return p.hashtagResults.isEmpty;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top tab — mixed users, hashtags, posts
// ─────────────────────────────────────────────────────────────────────────────

class _TopList extends StatelessWidget {
  final TopResult result;
  const _TopList({required this.result});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        if (result.users.isNotEmpty) ...[
          const _SliverHeader(title: 'People'),
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (_, i) => UserSearchTile(user: result.users[i]),
              childCount: result.users.length,
            ),
          ),
          const _Divider(),
        ],

        if (result.hashtags.isNotEmpty) ...[
          const _SliverHeader(title: 'Tags'),
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (_, i) => HashtagTile(hashtag: result.hashtags[i]),
              childCount: result.hashtags.length,
            ),
          ),
          const _Divider(),
        ],

        if (result.posts.isNotEmpty) ...[
          const _SliverHeader(title: 'Posts'),
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (_, i) => PostCard(post: result.posts[i]),  // ← reuse your existing PostCard
              childCount: result.posts.length,
            ),
          ),
        ],

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Users tab
// ─────────────────────────────────────────────────────────────────────────────

class _UserList extends StatefulWidget {
  final List<UserResult> users;
  final SearchProvider provider;
  const _UserList({required this.users, required this.provider});

  @override
  State<_UserList> createState() => _UserListState();
}

class _UserListState extends State<_UserList> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
        widget.provider.loadMore();
      }
    });
  }

  @override
  void dispose() { _scroll.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final loadingMore = widget.provider.loadState(SearchTab.users) == LoadState.loadingMore;

    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.only(top: 4, bottom: 80),
      itemCount: widget.users.length + (loadingMore ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == widget.users.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(
                color: Color(0xFF177E85), strokeWidth: 2)),
          );
        }
        return UserSearchTile(user: widget.users[i]);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Posts tab — reuses PostCard
// ─────────────────────────────────────────────────────────────────────────────

class _PostList extends StatefulWidget {
  final List posts;
  final SearchProvider provider;
  const _PostList({required this.posts, required this.provider});

  @override
  State<_PostList> createState() => _PostListState();
}

class _PostListState extends State<_PostList> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400) {
        widget.provider.loadMore();
      }
    });
  }

  @override
  void dispose() { _scroll.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final loadingMore = widget.provider.loadState(SearchTab.posts) == LoadState.loadingMore;

    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.only(top: 4, bottom: 80),
      itemCount: widget.posts.length + (loadingMore ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == widget.posts.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(
                color: Color(0xFF177E85), strokeWidth: 2)),
          );
        }
        // ← Directly reuse your existing PostCard widget
        return PostCard(post: widget.posts[i]);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hashtags tab
// ─────────────────────────────────────────────────────────────────────────────

class _HashtagList extends StatefulWidget {
  final List<HashtagResult> hashtags;
  final SearchProvider provider;
  const _HashtagList({required this.hashtags, required this.provider});

  @override
  State<_HashtagList> createState() => _HashtagListState();
}

class _HashtagListState extends State<_HashtagList> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
        widget.provider.loadMore();
      }
    });
  }

  @override
  void dispose() { _scroll.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final loadingMore = widget.provider.loadState(SearchTab.hashtags) == LoadState.loadingMore;

    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.only(top: 4, bottom: 80),
      itemCount: widget.hashtags.length + (loadingMore ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == widget.hashtags.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(
                color: Color(0xFF177E85), strokeWidth: 2)),
          );
        }
        return HashtagTile(hashtag: widget.hashtags[i]);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared small widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SliverHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const _SliverHeader({required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                )),
            if (action != null)
              GestureDetector(
                onTap: onAction,
                child: Text(
                  action!,
                  style: const TextStyle(
                    color: Color(0xFF177E85),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      const SliverToBoxAdapter(child: Divider(height: 1, color: Color(0xFF1E293B)));
}

class _EmptyState extends StatelessWidget {
  final SearchTab tab;
  final String query;
  const _EmptyState({required this.tab, required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 52, color: Colors.grey[700]),
          const SizedBox(height: 16),
          Text(
            'No ${tab.label.toLowerCase()} found',
            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'for "$query"',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
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
          const SizedBox(height: 16),
          Text('Something went wrong',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          const SizedBox(height: 20),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF177E85).withOpacity(0.15),
              foregroundColor: const Color(0xFF177E85),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}