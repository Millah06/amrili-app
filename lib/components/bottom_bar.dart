// lib/components/bottom_bar.dart
//
// PHASE 9 — Navigation restructure.
// ─────────────────────────────────────────────────────────────────────────────
// BEFORE: 5 tabs [Explore, Messages, Services(center), Wallet, Profile] on a
//         CurvedNavigationBar.
// AFTER:  4 tabs [Explore, Messages, Wallet, Profile] on a flat BottomAppBar,
//         with a floating SCANNER button docked in the center notch (the
//         X-style "pop"). The Services screen is no longer a tab — it lives on
//         as a pushed page reached from the Wallet hub's "Bills & Top-ups"
//         card (NG-tied users only).
//
// Design intent:
//  - Flat dark bar (app background 0xFF0F172A) with a 1px hairline top border
//    instead of a curved cutout — quieter, more professional, and it stops
//    fighting the content for attention.
//  - The scanner FAB is the ONE loud element: brand gradient (0xFF21D3ED →
//    0xFF177E85), soft teal glow. It is the app's universal verb (table QR,
//    store QR, product QR) and deliberately reachable by GUESTS — scans and
//    deep links bypass every gate (binding Phase 9 rule).
//  - Scroll-to-hide retained: FeedScreen reports scroll direction; the bar
//    collapses via AnimatedContainer (same Wrap trick as before, which avoids
//    overflow errors mid-animation) and the FAB scales away in sync.
//
// Guest gating: Wallet (2) and Profile (3) require auth → gate is now
// `index >= 2` (was `index > 2` when Services held the center slot).
// The old _bottomNavKey/UniqueKey reset hack existed only to force the curved
// bar to snap back after a blocked swipe; the flat bar renders purely from
// selectedIndex, so the hack is gone.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../constraints/app_theme.dart';
import '../core/adaptive/breakpoints.dart';
import '../core/analytics/analytics.dart';
import '../core/auth/guest_helper.dart';
import '../features/bottom_navigation/chat_screen.dart';
import '../features/bottom_navigation/feed_screen.dart';
import '../features/bottom_navigation/profile_screen.dart';
import '../features/bottom_navigation/wallet_screen.dart';
import '../services/brain.dart';
import '../shared/widgets/auth_gate_bottom_sheet.dart';

class BottomBar extends StatefulWidget {
  final Function(bool isScrollingDown)? onScrollDirectionChanged;

  const BottomBar({super.key, this.onScrollDirectionChanged});

  @override
  State<BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> {
  late List<Widget> screens;

  final PageController _pageController = PageController();

  bool _isBottomBarVisible = true;

  int selectedIndex = 0;
  int lastAllowedIndex = 0;

  // ── Scroll-to-hide (unchanged behavior, debounced) ────────────────────────
  Timer? _scrollDebounce;

  void _onScrollChange(bool isScrollingDown) {
    _scrollDebounce?.cancel();
    _scrollDebounce = Timer(const Duration(milliseconds: 100), () {
      if (isScrollingDown) {
        if (_isBottomBarVisible) setState(() => _isBottomBarVisible = false);
      } else {
        if (!_isBottomBarVisible) setState(() => _isBottomBarVisible = true);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // PHASE 9: 4 pages. HomeScreen (Services) is OUT of the shell — it is now
    // pushed from the Wallet hub's "Bills & Top-ups" card.
    screens = [
      FeedScreen(onScrollDirectionChanged: _onScrollChange),
      const Messages(),
      const WalletScreen(),
      const ProfileScreen(),
    ];
    // Defer Brain (utility bonus rates + service config) to after first frame
    // so it doesn't compete with the critical /users/me call at startup.
    // Guests skip this entirely — they can't reach utility screens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !GuestHelper.isGuest) {
        context.read<Brain>().getData();
      }
    });
  }

  @override
  void dispose() {
    _scrollDebounce?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // ── Guest gating ───────────────────────────────────────────────────────────
  // New index map: 0 Explore · 1 Messages · 2 Wallet · 3 Profile.
  // Wallet + Profile remain auth-only → gate at index >= 2.

  String buildReason(int index) {
    switch (index) {
      case 1:
        return 'messages';
      case 2:
        return 'wallet';
      case 3:
        return 'profile';
      default:
        return 'explore';
    }
  }

  bool _blockForGuest(int index) {
    if (index >= 2 && GuestHelper.isGuest) {
      AuthGateBottomSheet.show(
        context,
        reason: 'access ${buildReason(index)}',
      );
      return true;
    }
    return false;
  }

  void _onPageChange(int index) {
    if (_blockForGuest(index)) {
      // Snap back instantly — the flat bar re-renders purely from
      // selectedIndex, so no key-reset hack is needed.
      _pageController.jumpToPage(lastAllowedIndex);
      setState(() => selectedIndex = lastAllowedIndex);
      return;
    }
    setState(() {
      selectedIndex = index;
      lastAllowedIndex = index;
      if (!_isBottomBarVisible) _isBottomBarVisible = true;
    });
    Analytics.I.logTabView(buildReason(index));
  }

  void _onItemTapped(int index) {
    if (_blockForGuest(index)) {
      setState(() => selectedIndex = lastAllowedIndex);
      return;
    }
    setState(() {
      selectedIndex = index;
      lastAllowedIndex = index;
    });
    _pageController.jumpToPage(index);
    Analytics.I.logTabView(buildReason(index));
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  // On mobile/tablet (<1024 px): flat bottom bar + floating scanner FAB.
  // On desktop (≥1024 px): compact side NavigationRail, same destinations.
  // The PageView and all 4 screens are shared between both layouts — the
  // PageController still drives navigation in both cases.

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AmrilBreakpoints.tablet) {
          return _buildDesktopShell(context);
        }
        return _buildMobileShell(context);
      },
    );
  }

  // ── Mobile shell ────────────────────────────────────────────────────────────
  // Unchanged from the Phase 9 design: flat BottomAppBar + docked scanner FAB.
  Widget _buildMobileShell(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChange,
        physics: const BouncingScrollPhysics(),
        children: screens,
      ),
      floatingActionButtonLocation: const _LoweredCenterDocked(8),
      floatingActionButton: _ScanFab(
        visible: _isBottomBarVisible,
        onTap: () {
          Analytics.I.logScanOpen();
          context.push('/scan');
        },
      ),
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: _isBottomBarVisible ? 62 : 0,
        child: Wrap(
          children: [if (_isBottomBarVisible) _flatBar()],
        ),
      ),
    );
  }

  // ── Desktop shell ──────────────────────────────────────────────────────────
  // A compact 80 px side rail replaces the bottom bar. The same PageController
  // drives tab switching; swipe is disabled because mouse drag on a PageView
  // conflicts with horizontal scrolling inside child pages.
  Widget _buildDesktopShell(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _DesktopRail(
            selectedIndex: selectedIndex,
            onItemTapped: _onItemTapped,
            onScanTapped: () {
              Analytics.I.logScanOpen();
              context.push('/scan');
            },
          ),
          // 1 px hairline divider — same style as the mobile bar's top border.
          const VerticalDivider(
            width: 1,
            thickness: 1,
            color: Color(0x1AFFFFFF),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChange,
              // No swipe on desktop — rail items are the only nav mechanism.
              physics: const NeverScrollableScrollPhysics(),
              children: screens,
            ),
          ),
        ],
      ),
    );
  }

  /// Flat 4-item bar with a notched gap for the docked scanner.
  Widget _flatBar() {
    return BottomAppBar(
      color: const Color(0xFF0F172A),
      elevation: 0,
      height: 62,
      padding: EdgeInsets.zero,
      // The notch hugs the FAB circle; 6px margin — tight, machined seam.
      shape: const CircularNotchedRectangle(),
      notchMargin: 6,
      child: Container(
        // Hairline top border = the entire "design" of the bar. Flat, quiet,
        // professional — the FAB carries the brand color, not the bar.
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0x0FFFFFFF), width: 1),
          ),
        ),
        child: Row(
          children: [
            _NavItem(
              icon: FontAwesomeIcons.compass,
              label: 'Explore',
              selected: selectedIndex == 0,
              onTap: () => _onItemTapped(0),
            ),
            _NavItem(
              icon: FontAwesomeIcons.message,
              label: 'Messages',
              selected: selectedIndex == 1,
              onTap: () => _onItemTapped(1),
            ),
            // Center gap: real layout space for the docked FAB, so the four
            // items split 2 | 2 around the scanner instead of crowding it.
            const SizedBox(width: 72),
            _NavItem(
              icon: FontAwesomeIcons.wallet,
              label: 'Wallet',
              selected: selectedIndex == 2,
              onTap: () => _onItemTapped(2),
            ),
            _NavItem(
              icon: FontAwesomeIcons.circleUser,
              label: 'Profile',
              selected: selectedIndex == 3,
              onTap: () => _onItemTapped(3),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single nav item. Expanded so the four items share the remaining width
// equally; HitTestBehavior.opaque makes the WHOLE cell tappable, keeping the
// effective tap target ≥48dp tall for accessibility.
// ─────────────────────────────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final FaIconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Subtle scale on selection — motion confirms the tap without
              // the bar jumping around like the old curved cutout did.
              AnimatedScale(
                scale: selected ? 1.0 : 0.9,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                child: FaIcon(
                  icon,
                  size: 20,
                  color: selected ? const Color(0xFF21D3ED) : Colors.white38,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: selected ? Colors.white : Colors.white60,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom FAB location: stock centerDocked, sunk [lower] px. The stock dock
// floats the button half-above the bar, which read as "towering"; sinking it
// keeps the pop without the periscope effect. The notch follows the FAB's
// real geometry automatically, so the seam stays perfect.
// ─────────────────────────────────────────────────────────────────────────────
class _LoweredCenterDocked extends FloatingActionButtonLocation {
  final double lower;
  const _LoweredCenterDocked(this.lower);

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry geometry) {
    final base = FloatingActionButtonLocation.centerDocked.getOffset(geometry);
    return Offset(base.dx, base.dy + lower);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// The floating scanner — the app's universal entry verb (table QR, store QR,
// product QR). v2 design:
//   · 52px core inside a 60px dark ring — the ring matches the scaffold
//     background, so the button looks MACHINED into the notch instead of
//     pasted over it (this is what made v1 feel "plain": gradient met notch
//     edge with no seam).
//   · top-left white sheen overlay → reads as a physical convex button.
//   · corner-bracket "viewfinder" frame around the QR glyph — says *scanner*,
//     not just "a QR code exists".
//   · tactile: scales to .88 while pressed (Listener, no extra state mgmt).
//   · tight glow (blur 10) instead of v1's wide halo.
// Scales away in sync with the bar's scroll-to-hide.
// ─────────────────────────────────────────────────────────────────────────────
class _ScanFab extends StatefulWidget {
  final bool visible;
  final VoidCallback onTap;

  const _ScanFab({required this.visible, required this.onTap});

  @override
  State<_ScanFab> createState() => _ScanFabState();
}

class _ScanFabState extends State<_ScanFab> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      // Hide with the bar; while visible, dip on press for tactility.
      scale: !widget.visible ? 0.0 : (_pressed ? 0.88 : 1.0),
      duration: Duration(milliseconds: _pressed ? 80 : 220),
      curve: _pressed ? Curves.easeOut : Curves.easeOutBack,
      child: Semantics(
        button: true,
        label: 'Scan QR code',
        child: Listener(
          onPointerDown: (_) => setState(() => _pressed = true),
          onPointerUp: (_) => setState(() => _pressed = false),
          onPointerCancel: (_) => setState(() => _pressed = false),
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              width: 55,
              height: 55,
              // The dark seam ring — same color as the scaffold so the notch
              // gap reads as intentional negative space.
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF0F172A),
              ),
              padding: const EdgeInsets.all(4),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF21D3ED), Color(0xFF177E85)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF21D3ED).withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Convex sheen: a soft white wash on the upper-left makes
                    // the surface read as curved glass instead of flat fill.
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.center,
                          colors: [
                            Colors.white.withValues(alpha: 0.28),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                    // Viewfinder brackets + glyph — the "scanner" identity.
                    CustomPaint(
                      size: const Size(25, 25),
                      painter: _ViewfinderPainter(),
                    ),
                    const FaIcon(
                      FontAwesomeIcons.qrcode,
                      size: 15,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _DesktopRail — 92 px side navigation column shown on wide screens.
//
// Scroll arrows (▲ / ▼) flank the nav-item list so that if the rail grows
// (more destinations added later) it never overflows. The arrows fade when
// there is nothing to scroll in that direction.
// ─────────────────────────────────────────────────────────────────────────────
class _DesktopRail extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;
  final VoidCallback onScanTapped;

  const _DesktopRail({
    required this.selectedIndex,
    required this.onItemTapped,
    required this.onScanTapped,
  });

  @override
  State<_DesktopRail> createState() => _DesktopRailState();
}

class _DesktopRailState extends State<_DesktopRail> {
  final ScrollController _scroll = ScrollController();
  bool _canUp = false;
  bool _canDown = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    // Defer until after first layout so maxScrollExtent is valid.
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final at = _scroll.offset;
    final max = _scroll.position.maxScrollExtent;
    setState(() {
      _canUp = at > 1;
      _canDown = at < max - 1;
    });
  }

  void _scrollBy(double delta) {
    _scroll.animateTo(
      (_scroll.offset + delta).clamp(0, _scroll.position.maxScrollExtent),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      color: AppTheme.background,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _RailScanButton(onTap: widget.onScanTapped),
            const SizedBox(height: 6),
            const Divider(
              color: Color(0x1AFFFFFF),
              indent: 14,
              endIndent: 14,
              height: 14,
            ),

            // ▲ Up arrow — fades when already at the top.
            _RailScrollArrow(
              icon: Icons.keyboard_arrow_up_rounded,
              active: _canUp,
              onTap: () => _scrollBy(-56),
            ),

            // Scrollable nav items.
            Expanded(
              child: ListView(
                controller: _scroll,
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.zero,
                children: [
                  _RailItem(
                    icon: FontAwesomeIcons.compass,
                    label: 'Explore',
                    selected: widget.selectedIndex == 0,
                    onTap: () => widget.onItemTapped(0),
                  ),
                  _RailItem(
                    icon: FontAwesomeIcons.message,
                    label: 'Messages',
                    selected: widget.selectedIndex == 1,
                    onTap: () => widget.onItemTapped(1),
                  ),
                  _RailItem(
                    icon: FontAwesomeIcons.wallet,
                    label: 'Wallet',
                    selected: widget.selectedIndex == 2,
                    onTap: () => widget.onItemTapped(2),
                  ),
                  _RailItem(
                    icon: FontAwesomeIcons.circleUser,
                    label: 'Profile',
                    selected: widget.selectedIndex == 3,
                    onTap: () => widget.onItemTapped(3),
                  ),
                ],
              ),
            ),

            // ▼ Down arrow — fades when already at the bottom.
            _RailScrollArrow(
              icon: Icons.keyboard_arrow_down_rounded,
              active: _canDown,
              onTap: () => _scrollBy(56),
            ),

            // Brand credit.
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                'Amril',
                style: GoogleFonts.poppins(
                  color: Colors.white24,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Small arrow button that sits above/below the scrollable item list.
// Fades out (pointer-events disabled) when there is nothing to scroll.
class _RailScrollArrow extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _RailScrollArrow({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: active ? 0.55 : 0.18,
      duration: const Duration(milliseconds: 180),
      child: IgnorePointer(
        ignoring: !active,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            height: 22,
            width: double.infinity,
            child: Icon(icon, size: 20, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

// ── Scanner button for the desktop rail ───────────────────────────────────────
// Same gradient and glow as the mobile FAB — the scanner identity is consistent
// across both form factors.
class _RailScanButton extends StatelessWidget {
  final VoidCallback onTap;
  const _RailScanButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Scan QR code',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.primary, AppTheme.primaryDark],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Center(
            child: FaIcon(
              FontAwesomeIcons.qrcode,
              size: 22,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Single destination tile for the desktop rail ───────────────────────────
// Full-width tappable cell so the 80 px rail doesn't force icon-only targets.
// Selected state uses a subtle cyan tint instead of a heavy highlight.
class _RailItem extends StatelessWidget {
  final FaIconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RailItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: selected ? 1.0 : 0.85,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                child: FaIcon(
                  icon,
                  size: 22,
                  color: selected ? AppTheme.primary : Colors.white38,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : Colors.white54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Four corner brackets, 2px rounded strokes — the universal "viewfinder"
/// mark. Drawn instead of using an icon so the brackets can frame the qrcode
/// glyph at exactly the right inset.
class _ViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const len = 7.0; // arm length of each bracket
    final w = size.width, h = size.height;

    // Top-left
    canvas.drawLine(const Offset(0, len), Offset.zero, paint);
    canvas.drawLine(Offset.zero, const Offset(len, 0), paint);
    // Top-right
    canvas.drawLine(Offset(w - len, 0), Offset(w, 0), paint);
    canvas.drawLine(Offset(w, 0), Offset(w, len), paint);
    // Bottom-left
    canvas.drawLine(Offset(0, h - len), Offset(0, h), paint);
    canvas.drawLine(Offset(0, h), Offset(len, h), paint);
    // Bottom-right
    canvas.drawLine(Offset(w - len, h), Offset(w, h), paint);
    canvas.drawLine(Offset(w, h), Offset(w, h - len), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}