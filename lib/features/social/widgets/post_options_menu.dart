import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../providers/profile_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../services/image_processor_service.dart';
import '../services/social_api_service.dart';
import '../models/post_model.dart';
import '../providers/feed_provider.dart';
import 'boost_dialog.dart';
import 'report_dialog.dart';
import 'repost_dialog.dart';

class PostOptionsMenu extends StatefulWidget {
  final Post post;
  final Function(Post)? onPostUpdated; // ADD THIS

  const PostOptionsMenu({super.key, required this.post, this.onPostUpdated});

  @override
  State<PostOptionsMenu> createState() => _PostOptionsMenuState();
}

class _PostOptionsMenuState extends State<PostOptionsMenu> {
  @override
  Widget build(BuildContext context) {
    final pov = context.read<UserProvider>();
    final currentUserId =  pov.user!.userId;
    final isOwnPost = currentUserId == widget.post.userId;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Boost Post
            if (isOwnPost && !widget.post.isBoostActive)
              ListTile(
                leading: const Icon(Icons.rocket_launch, color: Colors.white),
                title: const Text(
                  'Boost Post',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => BoostDialog(post: widget.post),
                  );
                },
              ),

            // Save/ Unsaved
            ListTile(
              leading: Icon(
                widget.post.isSaved ? Icons.bookmark : Icons.bookmark_outline,
                color: Colors.white,
              ),
              title: Text(
                widget.post.isSaved ? 'Unsave' : 'Save',
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _toggleSave();
              },
            ),

            // Repost
            if (!isOwnPost)
              ListTile(
                leading: const Icon(Icons.repeat, color: Colors.white),
                title: const Text(
                  'Repost',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showRepostDialog();
                },
              ),

            // Share
            ListTile(
              leading: const Icon(Icons.share, color: Colors.white),
              title: const Text(
                'Share',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _sharePost();
              },
            ),

            // Download
            if (widget.post.images.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.download, color: Colors.white),
                title: const Text(
                  'Download',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _downloadPost();
                },
              ),

            // Copy link
            ListTile(
              leading: const Icon(Icons.link, color: Colors.white),
              title: const Text(
                'Copy link',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _copyLink();
              },
            ),

            // Delete (owner only)
            if (isOwnPost)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deletePost();
                },
              ),

            // Report (not owner)
            if (!isOwnPost)
              ListTile(
                leading: const Icon(Icons.flag, color: Colors.red),
                title: const Text(
                  'Report',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showReportDialog();
                },
              ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showRepostDialog() {

    if (!mounted) return;

    print(widget.post.userHandle);
    showDialog(
      context: context,
      builder: (context) => RepostDialog(post: widget.post),
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

  void _downloadPost() async {
    final messenger =  ScaffoldMessenger.of(context);
    if (!mounted) return;

    BuildContext? dialogContext;

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          dialogContext = context;
          return WillPopScope(
            onWillPop: () async => false,
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFF177E85)),
            ),
          );
        },
      );

      print('🔽 Starting download for post: ${widget.post.postId}');

      final apiService = SocialApiService();
      final response = await apiService.generatePostDownload(widget.post.postId);

      print('✅ Download response received');

      // Close loading dialog
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.of(dialogContext!).pop();
      }

      // Check if client-side processing is needed
      if (response['processOnClient'] == true) {
        print('📱 Processing on client side');

        // Use client-side processing
        final imageProcessor = ImageProcessorService();
        await imageProcessor.downloadProcessedImage(
          imageUrl: response['imageUrl'],
          caption: response['caption'] ?? widget.post.text,
          username: response['username'] ?? widget.post.userName,
        );

        messenger.showSnackBar(
          const SnackBar(
            content: Text('Image downloaded with watermark'),
            backgroundColor: Colors.green,
          ),
        );

      } else if (response['imageData'] != null) {
        print('💾 Saving server-processed image');

        // Server processed - save base64 image
        // TODO: Implement base64 to file save
        // For now, just show success
      }


    } catch (e) {
      print('❌ Download error: $e');

      // Close loading dialog if still open
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.of(dialogContext!).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _copyLink() {
    Clipboard.setData(
      ClipboardData(text: 'https://everywhere.app/post/${widget.post.postId}'),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link copied to clipboard'),
          backgroundColor: Color(0xFF177E85),
        ),
      );
    }
  }



  void _deletePost() async {

    if (!mounted) return;

    BuildContext? dialogLoadingContext;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Delete Post?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This action cannot be undone.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                Navigator.pop(context);
                // Show loading dialog
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) {
                    dialogLoadingContext = context;
                    return WillPopScope(
                      onWillPop: () async => false,
                      child: const Center(
                        child: CircularProgressIndicator(color: Color(0xFF177E85)),
                      ),
                    );
                  },
                );

                print('🔽 Starting delete for post: ${widget.post.postId}');
                final feedProvider = Provider.of<FeedProvider>(context, listen: false);
                final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

                final apiService = SocialApiService();
                final response = await apiService.deletePost(widget.post.postId, widget.post.isRepost);


                print('✅ Delete response received');

                feedProvider.removePost(widget.post.postId);
                profileProvider.removePostFromUserPosts(widget.post.postId);

                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Deleted Successfully'),
                    backgroundColor: Color(0xFF177E85),
                  ),
                );


                // Close loading dialog
                if (dialogLoadingContext != null && dialogLoadingContext!.mounted) {
                  Navigator.of(dialogLoadingContext!).pop();
                }


              } catch (e) {
                print('❌ Download error: $e');

                // Close loading dialog if still open
                if (dialogLoadingContext != null && dialogLoadingContext!.mounted) {
                  Navigator.of(dialogLoadingContext!).pop();
                }

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Download failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }

            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

  }

  void _showReportDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => ReportDialog(post: widget.post),
    );
  }

  void _toggleSave() async {
    if (!mounted) return;

    try {
      final apiService = SocialApiService();

      if (widget.post.isSaved) {
        await apiService.unsavePost(widget.post.postId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post removed from saved'),
              backgroundColor: Color(0xFF177E85),
            ),
          );
        }
      } else {
        await apiService.savePost(widget.post.postId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post saved'),
              backgroundColor: Color(0xFF177E85),
            ),
          );
        }
      }

      // Update post state
      final updatedPost = widget.post.copyWith(isSaved: !widget.post.isSaved);
      widget.onPostUpdated?.call(updatedPost);

      // Update providers
      if (mounted) {
        try {
          context.read<FeedProvider>().toggleSave(widget.post.postId);
        } catch (e) {}

        try {
          context.read<ProfileProvider>().updatePostInLists(
            widget.post.postId,
            updatedPost,
          );
        } catch (e) {}
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

}