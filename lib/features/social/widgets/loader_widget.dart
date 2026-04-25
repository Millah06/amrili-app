import 'package:flutter/material.dart';

class PostCardShimmer extends StatefulWidget {
  const PostCardShimmer({super.key});

  @override
  State<PostCardShimmer> createState() => _PostCardShimmerState();
}

class _PostCardShimmerState extends State<PostCardShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // One gradient sweeps diagonally across the ENTIRE card
            // spotX travels -1.5 → 1.5 (beyond both edges so sweep enters/exits cleanly)
            final spotX = -1.5 + _controller.value * 3.0;

            return ShaderMask(
              blendMode: BlendMode.srcATop,
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment(spotX - 1.0, -0.5),
                  end: Alignment(spotX + 1.0, 0.5),
                  colors: const [
                    Color(0xFF253555), // base — skeleton slot colour
                    Color(0xFF253555),
                    Color(0xFF4D7AB5), // glint — the bright travelling wave
                    Color(0xFF253555),
                    Color(0xFF253555),
                  ],
                  stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
                ).createShader(bounds);
              },
              child: child!,
            );
          },
          // child is built once — only the shader is rebuilt each frame
          child: _buildSkeleton(),
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar circle
              const _Bone(width: 40, height: 40, radius: 20),
              const SizedBox(width: 12),

              // Name + handle + timestamp
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + verification badge
                    Row(
                      children: const [
                        _Bone(width: 128, height: 14, radius: 5),
                        SizedBox(width: 8),
                        _Bone(width: 16, height: 16, radius: 8),
                      ],
                    ),
                    const SizedBox(height: 7),
                    // @handle
                    const _Bone(width: 82, height: 11, radius: 4),
                    const SizedBox(height: 6),
                    // timestamp
                    const _Bone(width: 50, height: 10, radius: 4),
                  ],
                ),
              ),

              // More icon + Follow pill
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  _Bone(width: 22, height: 22, radius: 5),
                  SizedBox(height: 10),
                  _Bone(width: 74, height: 28, radius: 14),
                ],
              ),
            ],
          ),
        ),

        // ── Optional subtitle ─────────────────────────────────────────────
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: _Bone(width: 144, height: 11, radius: 4),
        ),

        // ── Caption lines ─────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Bone(width: w, height: 13, radius: 4),
                  const SizedBox(height: 7),
                  _Bone(width: w, height: 13, radius: 4),
                  const SizedBox(height: 7),
                  // last line intentionally shorter — looks like real text
                  _Bone(width: w * 0.58, height: 13, radius: 4),
                ],
              );
            },
          ),
        ),

        // ── Image block ───────────────────────────────────────────────────
        const SizedBox(height: 14),
        const _Bone(width: double.infinity, height: 240, radius: 0),

        // ── Stats row ─────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: const [
              _Bone(width: 16, height: 16, radius: 4),
              SizedBox(width: 5),
              _Bone(width: 28, height: 11, radius: 4),
              SizedBox(width: 18),
              _Bone(width: 16, height: 16, radius: 4),
              SizedBox(width: 5),
              _Bone(width: 42, height: 11, radius: 4),
            ],
          ),
        ),

        // ── Divider ───────────────────────────────────────────────────────
        const _Bone(width: double.infinity, height: 1, radius: 0),

        // ── Action buttons ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              4,
                  (_) => Row(
                children: const [
                  _Bone(width: 18, height: 18, radius: 5),
                  SizedBox(width: 6),
                  _Bone(width: 32, height: 11, radius: 4),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// White container — ShaderMask paints the sweeping gradient over it.
/// Transparent gaps between bones let the card's dark background show through.
class _Bone extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _Bone({
    required this.width,
    required this.height,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width == double.infinity ? double.infinity : width,
      height: height,
      decoration: BoxDecoration(
        color: Color(0xFF177E85), // ShaderMask paints over this
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Drop-in for your feed while posts are loading.
/// Wrap in a SingleChildScrollView or use inside a Sliver.
class PostFeedShimmer extends StatelessWidget {
  final int itemCount;

  const PostFeedShimmer({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      itemBuilder: (_, __) => const PostCardShimmer(),
    );
  }
}