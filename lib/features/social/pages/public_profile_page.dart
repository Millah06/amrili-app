// lib/features/social/pages/public_profile_page.dart
//
// PHASE 2 — SOCIAL DEEP LINKS
//
// Destination for `amril.app/u/{userHandle}`. A read-only public profile loaded
// via the optional-auth `/web/u/:userHandle` endpoint (handle == the unique
// `UserProfile.userName`). Kept self-contained (not the full in-app profile
// screen) because a deep link can arrive with an empty stack and a guest user;
// it shows the public header + an "Open in app" CTA.
//
import 'package:everywhere/shared/widgets/net_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../constraints/vendor_theme.dart';
import '../services/social_api_service.dart';

class PublicProfilePage extends StatefulWidget {
  final String userHandle;
  const PublicProfilePage({super.key, required this.userHandle});

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

enum _S { loading, success, notFound, error }

class _PublicProfilePageState extends State<PublicProfilePage> {
  final SocialApiService _api = SocialApiService();
  _S _state = _S.loading;
  Map<String, dynamic>? _p;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = _S.loading);
    try {
      final json = await _api.getPublicProfile(widget.userHandle);
      if (!mounted) return;
      if (json == null) {
        setState(() => _state = _S.notFound);
        return;
      }
      setState(() {
        _p = json;
        _state = _S.success;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = _S.error);
    }
  }

  String _count(num? n) {
    final v = (n ?? 0).toInt();
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return '$v';
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
        title: Text('@${widget.userHandle}',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700, fontSize: 18, color: Colors.white)),
      ),
      body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 640), child: switch (_state) {
        _S.loading => const Center(
            child: CircularProgressIndicator(color: VendorTheme.primary)),
        _S.success => _Body(p: _p!, count: _count),
        _S.notFound => _msg('Profile not found',
            'No one with that handle, or the profile is unavailable.'),
        _S.error => _msg('Couldn’t load profile', 'Please try again.'),
      })),
    );
  }

  Widget _msg(String title, String body) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_off_outlined,
              size: 64, color: VendorTheme.textMuted),
          const SizedBox(height: 18),
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 8),
          Text(body,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white60)),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: VendorTheme.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14))),
            onPressed: () => context.go('/'),
            child: Text('Go home',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    ),
  );
}

class _Body extends StatelessWidget {
  final Map<String, dynamic> p;
  final String Function(num?) count;
  const _Body({required this.p, required this.count});

  @override
  Widget build(BuildContext context) {
    final String name = (p['userName'] as String?) ?? 'User';
    final String? avatar = p['avatar'] as String?;
    final String? bio = p['bio'] as String?;
    final bool verified = p['isVerified'] == true;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          NetImage.circle(
            url: avatar ?? '',
            radius: 44,
            fallback: const CircleAvatar(
              radius: 44,
              backgroundColor: VendorTheme.surface,
              child: Icon(Icons.person, size: 40, color: VendorTheme.textMuted),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text('@$name',
                    style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
              if (verified) ...[
                const SizedBox(width: 6),
                const Icon(Icons.verified, color: VendorTheme.primary, size: 20),
              ],
            ],
          ),
          if (bio != null && bio.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(bio,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    color: Colors.white70, fontSize: 14, height: 1.5)),
          ],
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _stat(count(p['postCount'] as num?), 'Posts'),
              _stat(count(p['followersCount'] as num?), 'Followers'),
              _stat(count(p['followingCount'] as num?), 'Following'),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: VendorTheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
              onPressed: () => context.go('/'),
              child: Text('Open in app',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) => Column(
    children: [
      Text(value,
          style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white)),
      const SizedBox(height: 2),
      Text(label,
          style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
    ],
  );
}