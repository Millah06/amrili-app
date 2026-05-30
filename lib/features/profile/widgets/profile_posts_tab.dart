import 'package:everywhere/features/social/models/post_model.dart';
import 'package:everywhere/features/social/widgets/loader_widget.dart';
import 'package:everywhere/features/social/widgets/post_card.dart';
import 'package:flutter/material.dart';

/// Paginated posts list used by BOTH MyProfileScreen and UserProfileScreen.
/// Handles pull-to-refresh and infinite scroll independently per tab.
/// The RefreshIndicator here is what fixes refresh inside NestedScrollView:
/// put it on the inner ListView, not on the NestedScrollView itself.
class ProfilePostsTab extends StatelessWidget {
  final List<Post> posts;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final VoidCallback onLoadMore;
  final Future<void> Function() onRefresh;

  const ProfilePostsTab({
    super.key,
    required this.posts,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.onLoadMore,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && posts.isEmpty) {
      return const PostFeedShimmer(itemCount: 4);
    }

    return RefreshIndicator(
      color: const Color(0xFF177E85),
      backgroundColor: const Color(0xFF1E293B),
      onRefresh: onRefresh,
      child: posts.isEmpty
          ? ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 60),
          Icon(Icons.grid_on, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Center(
            child: Text('No posts yet',
                style: TextStyle(color: Colors.grey[400], fontSize: 16)),
          ),
        ],
      )
          : NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          // Trigger pagination when 300px from the bottom
          if (notification is ScrollUpdateNotification) {
            final metrics = notification.metrics;
            if (metrics.pixels >= metrics.maxScrollExtent - 300) {
              onLoadMore();
            }
          }
          return false; // Let notifications bubble up to NestedScrollView
        },
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 5, bottom: 24),
          itemCount: posts.length + (isLoadingMore || hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < posts.length) {
              return PostCard(post: posts[index]);
            }
            // Footer: loading spinner or end-of-feed message
            if (isLoadingMore) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFF177E85)),
                ),
              );
            }
            if (!hasMore) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text("You've seen all posts",
                      style: TextStyle(color: Colors.grey[500])),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}