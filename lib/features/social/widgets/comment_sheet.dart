
import 'package:everywhere/constraints/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/comment_model.dart';
import '../models/post_model.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../providers/feed_provider.dart';

class CommentSheet extends StatefulWidget {
  final Post post;

  const CommentSheet({super.key, required this.post});

  @override
  State<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<CommentSheet> {
  final TextEditingController _commentController = TextEditingController();

  bool _isPosting = false;



  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _postComment() async {
    final text = _commentController.text.trim();

    if (text.isEmpty) return;

    if (text.length > 300) {
      _showError('Comment too long (max 300 characters)');
      return;
    }

    setState(() => _isPosting = true);

    try {
      await context.read<FeedProvider>().addComment(widget.post.postId, text);
      _commentController.clear();

      FocusScope.of(context).unfocus();
    } catch (e) {
      _showError('Failed to post comment');
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200 &&
          !context.read<FeedProvider>().isLoadingCommentsFor(widget.post.postId) &&
          context.read<FeedProvider>().hasMoreCommentsFor(widget.post.postId))
      {
        context.read<FeedProvider>().fetchComments(widget.post.postId);
      }
    });
  }

  void _loadInitialData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeedProvider>().fetchComments(widget.post.postId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text(
                  'Comments',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${widget.post.commentCount})',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: Consumer<FeedProvider>(builder: (context, feed, _) {
              if (feed.isLoadingCommentsFor(widget.post.postId) &&
                  (feed.comments[widget.post.postId]?.isEmpty ?? true)) {
                return const  Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF177E85),
                  ),
                );
              }

              if (feed.comments[widget.post.postId]?.isEmpty ?? true ) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'No comments yet',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Be the first to comment!',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (feed.commentError != null && feed.commentError!.isNotEmpty  && feed.comments.isEmpty) {
                return Center(
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
                        onPressed: () => feed.fetchComments(widget.post.postId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF177E85),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: feed.comments[widget.post.postId]!.length + 1,
                separatorBuilder: (_, __) => const Divider(color: Colors.white38,),
                itemBuilder: (context, index) {
                  if (index < feed.comments[widget.post.postId]!.length) {
                    return _CommentItem(comment: feed.comments[widget.post.postId]![index]);
                  }

                  // 👇 loader at bottom
                  return feed.hasMoreCommentsFor(widget.post.postId)
                      ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                      : const SizedBox(); // no more data
                },
              );

            }),
          ),

          const Divider(height: 1),

          // Input
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: 12 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    maxLength: 300,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Write a comment...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: kButtonColor,
                  child: IconButton(
                    icon: _isPosting
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.black),
                      ),
                    )
                        : const Icon(Icons.send, color: Colors.black, size: 20),
                    onPressed: _isPosting ? null : _postComment,
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

class _CommentItem extends StatelessWidget {
  final Comment comment;

  const _CommentItem({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey[300],
            child: Text(
              comment.userName[0].toUpperCase(),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeago.format(comment.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.text,
                  style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}