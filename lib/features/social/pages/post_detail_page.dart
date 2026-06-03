// lib/features/social/pages/post_detail_page.dart
//
// PHASE 2 — SOCIAL DEEP LINKS
//
// Destination for `amril.app/post/{postId}`. A shared post must look exactly
// like it does in the feed, so this page loads the post via the public
// (optional-auth) `/web/post/:postId` endpoint and renders the EXISTING
// `PostCard` — identical likes/comments/gift UI, identical styling.
//
// `PostCard` reads `FeedProvider` (for like/save toggles); that provider lives
// at the app root above `MaterialApp.router`, so it's in the tree even for a
// cold-start deep link. Guests can view; like/comment route through the app's
// existing guest gating inside `PostCard`.
//
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../constraints/vendor_theme.dart';
import '../models/post_model.dart';
import '../services/social_api_service.dart';
import '../widgets/post_card.dart';

class PostDetailPage extends StatefulWidget {
  final String postId;
  const PostDetailPage({super.key, required this.postId});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

enum _S { loading, success, notFound, error }

class _PostDetailPageState extends State<PostDetailPage> {
  final SocialApiService _api = SocialApiService();
  _S _state = _S.loading;
  Post? _post;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = _S.loading);
    try {
      final json = await _api.getPostById(widget.postId);
      if (!mounted) return;
      if (json == null) {
        setState(() => _state = _S.notFound);
        return;
      }
      setState(() {
        _post = Post.fromJson(json);
        _state = _S.success;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = _S.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VendorTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: Text('Post',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700, fontSize: 18, color: Colors.white)),
      ),
      body: switch (_state) {
        _S.loading => const Center(
            child: CircularProgressIndicator(color: VendorTheme.primary)),
        _S.success => SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          // Reuse the real feed card so the post is pixel-identical to the feed.
          child: PostCard(post: _post!),
        ),
        _S.notFound => _Status(
          icon: Icons.article_outlined,
          title: 'Post not available',
          message: 'This post may have been deleted or made private.',
          onPrimary: () => context.go('/'),
        ),
        _S.error => _Status(
          icon: Icons.wifi_off_rounded,
          title: 'Couldn’t load this post',
          message: 'Check your connection and try again.',
          primaryLabel: 'Retry',
          onPrimary: _load,
          secondaryLabel: 'Go home',
          onSecondary: () => context.go('/'),
        ),
      },
    );
  }
}

class _Status extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const _Status({
    required this.icon,
    required this.title,
    required this.message,
    required this.onPrimary,
    this.primaryLabel = 'Go home',
    this.secondaryLabel,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: VendorTheme.textMuted),
            const SizedBox(height: 18),
            Text(title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 14, height: 1.5, color: Colors.white60)),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: VendorTheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
              onPressed: onPrimary,
              child: Text(primaryLabel,
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700, color: Colors.white)),
            ),
            if (secondaryLabel != null && onSecondary != null)
              TextButton(
                onPressed: onSecondary,
                child: Text(secondaryLabel!,
                    style: GoogleFonts.inter(color: VendorTheme.textMuted)),
              ),
          ],
        ),
      ),
    );
  }
}