import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../models/user_profile_model.dart';

/// Hybrid About tab.
///
/// Own profile  → Private section (email, phone, transferUID) + Account + Public.
/// Other user   → Info (member since, last seen) + Contact (buzEmail, website).
///
/// The private section only renders because the backend now only sends those
/// fields when the requester IS the owner. If they're null, nothing renders.
class ProfileAboutTab extends StatelessWidget {
  final UserProfile profile;
  final bool isOwnProfile;
  final Future<void> Function() onRefresh;

  const ProfileAboutTab({
    super.key,
    required this.profile,
    required this.isOwnProfile,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: const Color(0xFF177E85),
      backgroundColor: const Color(0xFF1E293B),
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: isOwnProfile
            ? _ownProfileSections(context)
            : _otherUserSections(context),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // OWN PROFILE
  // ─────────────────────────────────────────────────────────────────────────

  List<Widget> _ownProfileSections(BuildContext context) {
    final hasPrivate = profile.email != null ||
        profile.phoneNumber != null ||
        profile.transferUID != null;

    final hasPublic = (profile.buzEmail != null &&
        profile.buzEmail!.isNotEmpty) ||
        profile.website != null ||
        profile.location != null;

    return [
      // ── Private section ─────────────────────────────────────────────
      if (hasPrivate) ...[
        _SectionHeader(
          label: 'Private',
          icon: Icons.lock_outline,
          iconColor: Colors.amber[600]!,
          tooltip: 'Only visible to you',
        ),
        const SizedBox(height: 10),
        if (profile.email != null)
          _InfoRow(
            icon: Icons.email_outlined,
            title: 'Login Email',
            value: profile.email!,
            isPrivate: true,
          ),
        if (profile.phoneNumber != null)
          _MaskedRow(
            icon: Icons.phone_outlined,
            title: 'Phone',
            value: profile.phoneNumber!,
            maskChar: '*',
            // Show last 4 digits: +234 *** *** 1234
            visibleSuffix: 4,
          ),
        if (profile.transferUID != null)
          _CopyRow(
            icon: Icons.account_balance_outlined,
            title: 'Transfer ID',
            value: profile.transferUID!,
            // Show only first 4 + last 4 chars, mask the middle
            maskMiddle: true,
          ),
        const SizedBox(height: 24),
      ],

      // ── Account section ──────────────────────────────────────────────
      _SectionHeader(
        label: 'Account',
        icon: Icons.manage_accounts_outlined,
        iconColor: const Color(0xFF177E85),
      ),
      const SizedBox(height: 10),
      _InfoRow(
        icon: Icons.calendar_today_outlined,
        title: 'Member Since',
        value: _formatDate(profile.createdAt),
      ),
      _InfoRow(
        icon: profile.isPrivate ? Icons.lock_outline : Icons.public,
        title: 'Account Privacy',
        value: profile.isPrivate ? 'Private' : 'Public',
        valueColor: profile.isPrivate
            ? Colors.amber[600]
            : const Color(0xFF177E85),
      ),
      if (profile.isKycVerified)
        _InfoRow(
          icon: Icons.verified_outlined,
          title: 'Verification',
          value: 'Verified account',
          valueColor: const Color(0xFF177E85),
        ),
      const SizedBox(height: 24),

      // ── Public section ───────────────────────────────────────────────
      if (hasPublic) ...[
        _SectionHeader(
          label: 'Public Info',
          icon: Icons.public,
          iconColor: Colors.grey[400]!,
          tooltip: 'Visible to everyone',
        ),
        const SizedBox(height: 10),
        if (profile.buzEmail != null && profile.buzEmail!.isNotEmpty)
          _InfoRow(
            icon: Icons.alternate_email,
            title: 'Business Email',
            value: profile.buzEmail!,
          ),
        if (profile.website != null)
          _InfoRow(
            icon: Icons.link,
            title: 'Website',
            value: profile.website!,
            isLink: true,
          ),
        if (profile.location != null)
          _InfoRow(
            icon: Icons.location_on_outlined,
            title: 'Location',
            value: profile.location!,
          ),
      ],
    ];
  }

  // ─────────────────────────────────────────────────────────────────────────
  // OTHER USER
  // ─────────────────────────────────────────────────────────────────────────

  List<Widget> _otherUserSections(BuildContext context) {
    final hasContact = (profile.buzEmail != null &&
        profile.buzEmail!.isNotEmpty) ||
        profile.website != null;

    return [
      // ── Info section ─────────────────────────────────────────────────
      _SectionHeader(
        label: 'Info',
        icon: Icons.info_outline,
        iconColor: const Color(0xFF177E85),
      ),
      const SizedBox(height: 10),
      _InfoRow(
        icon: Icons.calendar_today_outlined,
        title: 'Member Since',
        value: _formatDate(profile.createdAt),
      ),
      _InfoRow(
        icon: Icons.access_time_outlined,
        title: 'Last Seen',
        value: timeago.format(profile.lastActiveAt),
      ),
      if (profile.isKycVerified)
        _InfoRow(
          icon: Icons.verified_outlined,
          title: 'Verification',
          value: 'Verified account',
          valueColor: const Color(0xFF177E85),
        ),

      // ── Contact section (only if they chose to share) ────────────────
      if (hasContact) ...[
        const SizedBox(height: 24),
        _SectionHeader(
          label: 'Contact',
          icon: Icons.contact_mail_outlined,
          iconColor: Colors.grey[400]!,
        ),
        const SizedBox(height: 10),
        if (profile.buzEmail != null && profile.buzEmail!.isNotEmpty)
          _InfoRow(
            icon: Icons.alternate_email,
            title: 'Business Email',
            value: profile.buzEmail!,
            isLink: true,
          ),
        if (profile.website != null)
          _InfoRow(
            icon: Icons.link,
            title: 'Website',
            value: profile.website!,
            isLink: true,
          ),
      ],
    ];
  }

  static String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SECTION HEADER
// ═══════════════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final String? tooltip;

  const _SectionHeader({
    required this.label,
    required this.icon,
    required this.iconColor,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: iconColor),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        if (tooltip != null) ...[
          const SizedBox(width: 6),
          Tooltip(
            message: tooltip!,
            child: Icon(Icons.help_outline, size: 13, color: Colors.grey[600]),
          ),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STANDARD INFO ROW
// ═══════════════════════════════════════════════════════════════════════════

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool isPrivate;
  final bool isLink;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
    this.isPrivate = false,
    this.isLink = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: isPrivate
              ? Border.all(color: Colors.amber.withOpacity(0.15), width: 1)
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF177E85), size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: TextStyle(
                      color: valueColor ??
                          (isLink
                              ? const Color(0xFF177E85)
                              : Colors.white),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            if (isPrivate)
              Icon(Icons.visibility_off_outlined,
                  size: 16, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MASKED ROW — phone number, shown as +234 *** *** 1234
// ═══════════════════════════════════════════════════════════════════════════

class _MaskedRow extends StatefulWidget {
  final IconData icon;
  final String title;
  final String value;
  final String maskChar;
  final int visibleSuffix;

  const _MaskedRow({
    required this.icon,
    required this.title,
    required this.value,
    this.maskChar = '*',
    this.visibleSuffix = 4,
  });

  @override
  State<_MaskedRow> createState() => _MaskedRowState();
}

class _MaskedRowState extends State<_MaskedRow> {
  bool _revealed = false;

  String get _display {
    if (_revealed) return widget.value;
    if (widget.value.length <= widget.visibleSuffix) return widget.value;
    final suffix = widget.value.substring(
        widget.value.length - widget.visibleSuffix);
    // Keep first 4 chars (e.g. +234), mask the rest except last 4
    final prefix = widget.value.length > widget.visibleSuffix + 4
        ? widget.value.substring(0, 4)
        : '';
    final middleLength =
        widget.value.length - widget.visibleSuffix - prefix.length;
    final middle = List.filled(middleLength, widget.maskChar).join();
    return '$prefix $middle $suffix';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border:
          Border.all(color: Colors.amber.withOpacity(0.15), width: 1),
        ),
        child: Row(
          children: [
            Icon(widget.icon, color: const Color(0xFF177E85), size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title,
                      style:
                      TextStyle(color: Colors.grey[500], fontSize: 11)),
                  const SizedBox(height: 3),
                  Text(
                    _display,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _revealed = !_revealed),
              child: Icon(
                _revealed
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// COPY ROW — Transfer ID with copy-to-clipboard button
// ═══════════════════════════════════════════════════════════════════════════

class _CopyRow extends StatefulWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool maskMiddle;

  const _CopyRow({
    required this.icon,
    required this.title,
    required this.value,
    this.maskMiddle = false,
  });

  @override
  State<_CopyRow> createState() => _CopyRowState();
}

class _CopyRowState extends State<_CopyRow> {
  bool _copied = false;

  String get _display {
    if (!widget.maskMiddle || widget.value.length <= 8) return widget.value;
    // EVW-XXXXXX → EVW-••••34
    final prefix = widget.value.substring(0, 4);
    final suffix = widget.value.substring(widget.value.length - 2);
    return '$prefix••••$suffix';
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.value));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border:
          Border.all(color: Colors.amber.withOpacity(0.15), width: 1),
        ),
        child: Row(
          children: [
            Icon(widget.icon, color: const Color(0xFF177E85), size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title,
                      style:
                      TextStyle(color: Colors.grey[500], fontSize: 11)),
                  const SizedBox(height: 3),
                  Text(_display,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontFamily: 'monospace')),
                ],
              ),
            ),
            // Copy button
            GestureDetector(
              onTap: _copy,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _copied
                    ? const Icon(Icons.check, size: 18, color: Color(0xFF177E85),
                    key: ValueKey('check'))
                    : Icon(Icons.copy_outlined,
                    size: 18,
                    color: Colors.grey[500],
                    key: const ValueKey('copy')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}