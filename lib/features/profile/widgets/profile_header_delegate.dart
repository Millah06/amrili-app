import 'package:cached_network_image/cached_network_image.dart';
import 'package:everywhere/features/profile/models/profile_display_data.dart';
import 'package:everywhere/features/social/widgets/verification_badge.dart';
import 'package:everywhere/shared/functions/shared_functions.dart';
import 'package:flutter/material.dart';

import '../../../constraints/vendor_theme.dart';
import '../../../core/auth/guest_helper.dart';
import '../../../core/constant/app_constants.dart';
import '../../social/screens/followers_screen.dart';
import '../../social/screens/gift_user_screen.dart';

/// Drop-in replacement for the old _ProfileHeaderDelegate.
/// Works for both MyProfileScreen (isOwnProfile: true)
/// and UserProfileScreen (isOwnProfile: false).
///
/// Accepts ProfileDisplayData? — null stats show "_" placeholder,
/// null display entirely shows skeleton.
class ProfileHeaderDelegate extends SliverPersistentHeaderDelegate {
  final ProfileDisplayData? display;
  final bool isOwnProfile;
  final bool isLoading;
  final double minHeight;
  final double maxHeight;

  // Own profile
  final VoidCallback? onSettings;
  final VoidCallback? onEditProfile;
  final VoidCallback? onShare;
  final VoidCallback? onCreatePost; // "+" button on avatar

  // Other user profile
  final VoidCallback? onBack;
  final VoidCallback? onFollow;
  final VoidCallback? onMessage;
  final VoidCallback? onGift;
  final bool isFollowing;

  const ProfileHeaderDelegate({
    required this.display,
    required this.isOwnProfile,
    this.isLoading = false,
    required this.minHeight,
    required this.maxHeight,
    this.onSettings,
    this.onEditProfile,
    this.onShare,
    this.onCreatePost,
    this.onBack,
    this.onFollow,
    this.onMessage,
    this.onGift,
    this.isFollowing = false,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  /// PHASE 9 — content-aware header height.
  ///
  /// The expanded header's only variable-height pieces are the bio block and
  /// the meta (country/location/email/website) row; everything else is fixed.
  /// So instead of always reserving the worst case (290), start from it and
  /// subtract the blocks that won't render. While data is still null
  /// (skeleton) we keep the full height — the skeleton draws all blocks.
  ///
  /// TUNING: _kBioBlock / _kMetaBlock are the measured heights of those two
  /// blocks including their bottom padding. If a device ever shows a sliver
  /// of leftover space (or a 1–2px overflow stripe), adjust these two numbers
  /// — nothing else.
  static const double _kFullHeight = 290;
  static const double _kBioBlock = 42;  // 2-line bio text + bottom padding
  static const double _kMetaBlock = 30; // meta Wrap single run + padding

  static double computeMaxHeight(ProfileDisplayData? d) {
    if (d == null) return _kFullHeight; // skeleton draws everything

    double h = _kFullHeight;
    final hasBio = d.bio != null && d.bio!.isNotEmpty;
    final hasMeta = d.country != null ||
        d.location != null ||
        (d.buzEmail != null && d.buzEmail!.isNotEmpty) ||
        d.website != null;

    if (!hasBio) h -= _kBioBlock;
    if (!hasMeta) h -= _kMetaBlock;
    return h;
  }

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final progress = (shrinkOffset / maxExtent).clamp(0.0, 1.0);
    final isCompressed = progress > 0.6;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Cover photo / gradient background ──────────────────────────────
        Positioned.fill(
          child: display?.coverImage != null
              ? CachedNetworkImage(
            imageUrl: display!.coverImage!,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => _gradientBg(),
          )
              : _gradientBg(),
        ),

        // ── Dark gradient overlay ──────────────────────────────────────────
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

        // ── Expanded / Compressed content ─────────────────────────────────
        AnimatedPositioned(
          duration: const Duration(milliseconds: 200),
          left: 16,
          right: 16,
          top: isCompressed ? 12 : null,
          bottom: isCompressed ? null : 16,
          child: isCompressed
              ? _CompressedHeader(display: display, isOwnProfile: isOwnProfile)
              : _ExpandedHeader(
            display: display,
            isOwnProfile: isOwnProfile,
            isLoading: isLoading,
            isFollowing: isFollowing,
            onEditProfile: onEditProfile,
            onShare: onShare,
            onFollow: onFollow,
            onMessage: onMessage,
            onGift: onGift,
            onCreatePost: onCreatePost,
          ),
        ),

        // ── Top bar: back or settings (always visible) ────────────────────
        Positioned(
          top: MediaQuery.of(context).padding.top + 4,
          left: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!isOwnProfile)
                  _TopBarButton(
                    icon: Icons.arrow_back,
                    onTap: onBack ?? () => Navigator.of(context).pop(),
                  )
                else
                  const SizedBox(width: 48),
                if (isOwnProfile)
                  _TopBarButton(icon: Icons.settings, onTap: onSettings)
                else
                  const SizedBox(width: 48),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _gradientBg() => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          const Color(0xFF177E85).withOpacity(0.4),
          const Color(0xFF1E293B),
        ],
      ),
    ),
  );

  @override
  bool shouldRebuild(ProfileHeaderDelegate old) =>
      display != old.display ||
          isOwnProfile != old.isOwnProfile ||
          isLoading != old.isLoading ||
          isFollowing != old.isFollowing;
}

// ═══════════════════════════════════════════════════════════════════════════
// EXPANDED HEADER
// ═══════════════════════════════════════════════════════════════════════════

class _ExpandedHeader extends StatelessWidget {
  final ProfileDisplayData? display;
  final bool isOwnProfile;
  final bool isLoading;
  final bool isFollowing;
  final VoidCallback? onEditProfile;
  final VoidCallback? onShare;
  final VoidCallback? onFollow;
  final VoidCallback? onMessage;
  final VoidCallback? onGift;
  final VoidCallback? onCreatePost;

  const _ExpandedHeader({
    required this.display,
    required this.isOwnProfile,
    required this.isLoading,
    required this.isFollowing,
    this.onEditProfile,
    this.onShare,
    this.onFollow,
    this.onMessage,
    this.onGift,
    this.onCreatePost,
  });

  @override
  Widget build(BuildContext context) {
    // Nothing at all yet — full skeleton
    if (isLoading && display == null) {
      return const _ExpandedSkeleton();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Avatar + name + stats ────────────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _ProfileAvatar(
              avatar: display?.avatar,
              userName: display?.userName ?? '',
              size: 90,
              isOwnProfile: isOwnProfile,
              onCreatePost: onCreatePost,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name
                  Row(
                    children: [
                      Flexible(
                        child: display?.userName.isNotEmpty == true
                            ? Text(
                          display!.userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        )
                            : const _SkeletonBox(width: 120, height: 18),
                      ),
                      if (display?.userId.isNotEmpty == true) ...[
                        const SizedBox(width: 4),
                        VerificationBadge(userId: display!.userId),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),

                  // Handle
                  if (display?.displayName != null)
                    Text(
                      '@${display!.displayName}',
                      style: TextStyle(color: Colors.grey[400], fontSize: 13),
                    )
                  else
                    const SizedBox(height: 14),

                  const SizedBox(height: 10),

                  // Stats — shows "_" when null (not yet loaded from server)
                  Row(
                    children: [
                      _MiniStat(
                        value: display?.formattedPosts ?? '_',
                        label: 'Posts',
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () {
                          if (display != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FollowersScreen(
                                  userId:      display!.userId,
                                  userName:    display!.userName,
                                  isFollowers: true,  // false for Following
                                ),
                              ),
                            );
                          }
                        },
                        child: _MiniStat(
                          value: display?.formattedFollowers ?? '_',
                          label: 'Followers',
                        ),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () {
                          if (display != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FollowersScreen(
                                  userId:      display!.userId,
                                  userName:    display!.userName,
                                  isFollowers: false,  // false for Following
                                ),
                              ),
                            );
                          }
                        },
                        child: _MiniStat(
                          value: display?.formattedFollowing ?? '_',
                          label: 'Following',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // ── Bio ──────────────────────────────────────────────────────────
        if (display?.bio != null && display!.bio!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              display!.bio!,
              style: TextStyle(
                  color: Colors.grey[300], fontSize: 14, height: 1.3),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

        // ── Country · location · business email · website ────────────────
        if (_hasMetaInfo(display))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 14,
              runSpacing: 4,
              children: [
                if (display?.country != null)
                  _MetaChip(
                    flagEmoji: _countryFlag(display!.country!),
                    label: _countryName(display!.country!),
                  ),
                if (display?.location != null)
                  _MetaChip(
                    icon: Icons.location_on,
                    label: display!.location!,
                  ),
                if (display?.buzEmail != null &&
                    display!.buzEmail!.isNotEmpty)
                  GestureDetector(
                    onTap: () =>
                        SharedFunctions.launchEmail(
                          'Hey I find your email from ${AppConstants.appName} app',
                      email: display!.buzEmail!,
                    ),
                    child: const _MetaChip(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      isLink: true,
                    ),
                  ),
                if (display?.website != null)
                  GestureDetector(
                    onTap: () =>
                        SharedFunctions.openUrl(display!.website!),
                    child: _MetaChip(
                      icon: Icons.link,
                      label: display!.website!,
                      isLink: true,
                    ),
                  ),
              ],
            ),
          ),

        // ── Action buttons ───────────────────────────────────────────────
        _ActionButtons(
          isOwnProfile: isOwnProfile,
          isFollowing: isFollowing,
          // Disable follow/message until full profile is loaded
          // (we need isPrivate, isFollowing etc.)
          actionsEnabled: display?.isFullyLoaded ?? false,
          onEditProfile: onEditProfile,
          onShare: onShare,
          onFollow: onFollow,
          onMessage: onMessage,
          onGift: onGift,
        ),
      ],
    );
  }

  static bool _hasMetaInfo(ProfileDisplayData? d) =>
      d?.country != null ||
          d?.location != null ||
          (d?.buzEmail != null && d!.buzEmail!.isNotEmpty) ||
          d?.website != null;

  // Converts ISO-3166-1 alpha-2 code to flag emoji
  static String _countryFlag(String iso) => iso
      .toUpperCase()
      .split('')
      .map((c) => String.fromCharCode(c.codeUnitAt(0) + 127397))
      .join();

  // Expand as your user base grows
  static String _countryName(String iso) {
    const names = {
      'NG': 'Nigeria',    'US': 'United States', 'GB': 'United Kingdom',
      'GH': 'Ghana',      'KE': 'Kenya',         'ZA': 'South Africa',
      'CA': 'Canada',     'AU': 'Australia',     'DE': 'Germany',
      'FR': 'France',     'IN': 'India',         'BR': 'Brazil',
      'UG': 'Uganda',     'TZ': 'Tanzania',      'ET': 'Ethiopia',
      'RW': 'Rwanda',     'SN': 'Senegal',       'CI': "Côte d'Ivoire",
      'CM': 'Cameroon',   'AO': 'Angola',        'EG': 'Egypt',
      'IT': 'Italy',      'ES': 'Spain',         'NL': 'Netherlands',
      'JP': 'Japan',      'CN': 'China',         'AE': 'UAE',
    };
    return names[iso.toUpperCase()] ?? iso;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// COMPRESSED HEADER (shown when scrolled past 60%)
// ═══════════════════════════════════════════════════════════════════════════

class _CompressedHeader extends StatelessWidget {
  final ProfileDisplayData? display;
  final bool isOwnProfile;

  const _CompressedHeader(
      {required this.display, required this.isOwnProfile});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 30,
        // Indent right to avoid overlapping the back-button on other profiles
        left: isOwnProfile ? 0 : 40,
      ),
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
            child: ClipOval(
              child: display?.avatar != null
                  ? CachedNetworkImage(
                imageUrl: display!.avatar!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _InitialsAvatar(
                  name: display?.userName ?? '',
                  size: 44,
                  fontSize: 16,
                ),
              )
                  : _InitialsAvatar(
                name: display?.userName ?? '',
                size: 44,
                fontSize: 16,
              ),
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
                      child: display?.userName.isNotEmpty == true
                          ? Text(
                        display!.userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      )
                          : const _SkeletonBox(width: 100, height: 14),
                    ),
                    if (display?.userId.isNotEmpty == true) ...[
                      const SizedBox(width: 4),
                      VerificationBadge(userId: display!.userId),
                    ],
                  ],
                ),
                if (display?.displayName != null)
                  Text(
                    '@${display!.displayName}',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SHARED SUB-WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

/// Avatar circle with optional "+" create-post button for own profile.
class _ProfileAvatar extends StatelessWidget {
  final String? avatar;
  final String userName;
  final double size;
  final bool isOwnProfile;
  final VoidCallback? onCreatePost;

  const _ProfileAvatar({
    required this.avatar,
    required this.userName,
    required this.size,
    required this.isOwnProfile,
    this.onCreatePost,
  });

  @override
  Widget build(BuildContext context) {
    final circle = Container(
      width: size,
      height: size,
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
      child: ClipOval(
        child: avatar != null
            ? CachedNetworkImage(
          imageUrl: avatar!,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) =>
              _InitialsAvatar(name: userName, size: size),
        )
            : _InitialsAvatar(name: userName, size: size),
      ),
    );

    if (!isOwnProfile) return circle;

    return Stack(
      children: [
        circle,
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: onCreatePost,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF177E85),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

/// Initials fallback shown when avatar URL is null or fails to load.
class _InitialsAvatar extends StatelessWidget {
  final String name;
  final double size;
  final double fontSize;

  const _InitialsAvatar({
    required this.name,
    required this.size,
    this.fontSize = 28,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: Colors.grey[800],
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Posts / Followers / Following count.
/// Shows the value dimmed when it's "_" (not yet loaded).
class _MiniStat extends StatelessWidget {
  final String value;
  final String label;

  const _MiniStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final isPlaceholder = value == '_';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: isPlaceholder ? Colors.grey[700] : Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey[500], fontSize: 11),
        ),
      ],
    );
  }
}

/// Location / country / website / email chip.
class _MetaChip extends StatelessWidget {
  final IconData? icon;
  final String? flagEmoji;
  final String label;
  final bool isLink;

  const _MetaChip({
    this.icon,
    this.flagEmoji,
    required this.label,
    this.isLink = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (flagEmoji != null)
          Text(flagEmoji!, style: const TextStyle(fontSize: 14))
        else if (icon != null)
          Icon(icon, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              color: isLink ? const Color(0xFF177E85) : Colors.grey[400],
              fontSize: 13,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Edit + Share (own) or Follow + Message (other user).
class _ActionButtons extends StatelessWidget {
  final bool isOwnProfile;
  final bool isFollowing;
  final bool actionsEnabled;
  final VoidCallback? onEditProfile;
  final VoidCallback? onShare;
  final VoidCallback? onFollow;
  final VoidCallback? onMessage;
  final VoidCallback? onGift;

  const _ActionButtons({
    required this.isOwnProfile,
    required this.isFollowing,
    required this.actionsEnabled,
    this.onEditProfile,
    this.onShare,
    this.onFollow,
    this.onMessage,
    this.onGift,
  });

  @override
  Widget build(BuildContext context) {
    if (isOwnProfile) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onEditProfile,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey[700]!),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: const Text('Edit Profile',
                  style: TextStyle(color: Colors.white, fontSize: 14)),
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: onShare,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey[700]!),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Icon(Icons.share, color: Colors.white, size: 18),
          ),
        ],
      );
    }

    // Other user — buttons disabled until full profile loads so we have
    // accurate isFollowing state and isPrivate info.
    return Row(
      children: [
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: SizedBox(
              width: double.infinity,
              key: ValueKey(isFollowing),
              child: ElevatedButton(
                onPressed: actionsEnabled ? onFollow : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFollowing
                      ? const Color(0xFF1E293B)
                      : const Color(0xFF177E85),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                  const Color(0xFF177E85).withOpacity(0.4),
                  side: isFollowing
                      ? BorderSide(color: Colors.grey[700]!)
                      : null,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: Text(
                  isFollowing ? 'Following' : 'Follow',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ),
        ),
        // in the "other user" Row, between the Follow Expanded and the Message button:
        const SizedBox(width: 10),
        OutlinedButton(
          onPressed: actionsEnabled ? onGift : null,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.grey[700]!),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          child: const Icon(Icons.card_giftcard_rounded, color: VendorTheme.gold, size: 18),
        ),
        const SizedBox(width: 10),
    // add to _ActionButtons fields + constructor:


        OutlinedButton(
          onPressed: actionsEnabled ? onMessage : null,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.grey[700]!),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          child: const Text('Message',
              style: TextStyle(color: Colors.white, fontSize: 14)),
        ),
      ],
    );
  }
}

/// Frosted icon button used in the top bar (back / settings).
class _TopBarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _TopBarButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SKELETON WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

/// Single shimmer placeholder box.
class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;

  const _SkeletonBox({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.09),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

/// Full expanded skeleton — shown only when there is zero data at all
/// (isLoading == true && display == null).
/// Once even initialData arrives, real data renders immediately instead.
class _ExpandedSkeleton extends StatelessWidget {
  const _ExpandedSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Skeleton avatar circle
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.09),
                border: Border.all(
                    color: Colors.white.withOpacity(0.15), width: 3),
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SkeletonBox(width: 130, height: 18),
                  SizedBox(height: 6),
                  _SkeletonBox(width: 90, height: 13),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      _SkeletonBox(width: 32, height: 28),
                      SizedBox(width: 20),
                      _SkeletonBox(width: 52, height: 28),
                      SizedBox(width: 20),
                      _SkeletonBox(width: 52, height: 28),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const _SkeletonBox(width: double.infinity, height: 13),
        const SizedBox(height: 6),
        const _SkeletonBox(width: 200, height: 13),
        const SizedBox(height: 16),
        const Row(
          children: [
            Expanded(child: _SkeletonBox(width: double.infinity, height: 38)),
            SizedBox(width: 10),
            _SkeletonBox(width: 48, height: 38),
          ],
        ),
      ],
    );
  }
}