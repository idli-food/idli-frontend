import 'package:flutter/material.dart';
import '../../resources/app_theme.dart';
import '../../utils/responsive.dart';

const _cardGradients = [
  [Color(0xFF2C1B4E), Color(0xFF0D0820)],
  [Color(0xFF1A2744), Color(0xFF060D1C)],
  [Color(0xFF2C1B1B), Color(0xFF120808)],
];

class PostFeedItem extends StatefulWidget {
  final Map<String, String> post;
  final int index;

  const PostFeedItem({super.key, required this.post, required this.index});

  @override
  State<PostFeedItem> createState() => _PostFeedItemState();
}

class _PostFeedItemState extends State<PostFeedItem> {
  bool _liked = false;
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    final gradientPair =
        _cardGradients[widget.index % _cardGradients.length];

    return Padding(
      padding: EdgeInsets.only(bottom: context.hp(2.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card
          _PostCard(post: widget.post, gradientPair: gradientPair),

          SizedBox(height: context.hp(1.5)),

          // Actions
          _ActionsRow(
            liked: _liked,
            saved: _saved,
            onLike: () => setState(() => _liked = !_liked),
            onSave: () => setState(() => _saved = !_saved),
          ),

          SizedBox(height: context.hp(1.2)),

          // Dish name + rating
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  widget.post['dish']!,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: context.sp(17),
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                    height: 1.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
              SizedBox(width: context.wp(2)),
              _RatingBadge(rating: widget.post['rating']!),
            ],
          ),

          SizedBox(height: context.hp(0.7)),

          // Description
          Text(
            widget.post['description']!,
            style: AppTextStyles.secondary.copyWith(
              fontSize: context.sp(13),
              height: 1.5,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),

          SizedBox(height: context.hp(0.9)),

          // Tag
          _TagPill(tag: widget.post['tag']!),
        ],
      ),
    );
  }
}

// ── Card ─────────────────────────────────────────────────────────────────────

class _PostCard extends StatelessWidget {
  final Map<String, String> post;
  final List<Color> gradientPair;

  const _PostCard({required this.post, required this.gradientPair});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradientPair[0].withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AspectRatio(
          aspectRatio: 3 / 4,
          child: Stack(
            children: [
              // Gradient background (image placeholder)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradientPair,
                    ),
                  ),
                ),
              ),

              // Subtle dot texture
              Positioned.fill(
                child: CustomPaint(painter: _DotTexturePainter()),
              ),

              // Top overlay
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _TopOverlay(post: post),
              ),

              // Bottom overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _BottomOverlay(post: post),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopOverlay extends StatelessWidget {
  final Map<String, String> post;
  const _TopOverlay({required this.post});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        context.wp(3.5),
        context.hp(2),
        context.wp(2),
        context.hp(5),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.65),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.grey.withValues(alpha: 0.6),
            child: const Icon(Icons.person, color: Colors.white, size: 18),
          ),
          SizedBox(width: context.wp(2.5)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  post['username']!,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Colors.white,
                    fontSize: context.sp(14),
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  post['handle']!,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: context.sp(11),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          Icon(
            Icons.more_vert,
            color: Colors.white.withValues(alpha: 0.9),
            size: context.sp(22),
          ),
        ],
      ),
    );
  }
}

class _BottomOverlay extends StatelessWidget {
  final Map<String, String> post;
  const _BottomOverlay({required this.post});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        context.wp(3.5),
        context.hp(5),
        context.wp(3.5),
        context.hp(2),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.75),
            Colors.transparent,
          ],
        ),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.wp(2.5),
          vertical: context.hp(0.7),
        ),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on,
                color: AppColors.accent, size: context.sp(14)),
            SizedBox(width: context.wp(1.2)),
            // Flexible prevents the text column from overflowing the card width
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    post['restaurant']!,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Colors.white,
                      fontSize: context.sp(13),
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Text(
                    post['area']!,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: context.sp(11),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
        ),  // closes Align
      ),
    );
  }
}

// ── Actions row ──────────────────────────────────────────────────────────────

class _ActionsRow extends StatelessWidget {
  final bool liked;
  final bool saved;
  final VoidCallback onLike;
  final VoidCallback onSave;

  const _ActionsRow({
    required this.liked,
    required this.saved,
    required this.onLike,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ActionIcon(
          icon: liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: liked ? Colors.red.shade400 : AppColors.dark,
          onTap: onLike,
        ),
        SizedBox(width: context.wp(4.5)),
        _ActionIcon(
          icon: Icons.chat_bubble_outline_rounded,
          color: AppColors.dark,
          onTap: () {},
        ),
        SizedBox(width: context.wp(4.5)),
        _ActionIcon(
          icon: Icons.near_me_outlined,
          color: AppColors.dark,
          onTap: () {},
        ),
        const Spacer(),
        GestureDetector(
          onTap: onSave,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: context.wp(3),
              vertical: context.hp(0.9),
            ),
            decoration: BoxDecoration(
              color: saved ? AppColors.primary : AppColors.accent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: saved ? Colors.white : AppColors.dark,
              size: context.sp(20),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionIcon(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: color, size: context.sp(24)),
    );
  }
}

// ── Rating badge ─────────────────────────────────────────────────────────────

class _RatingBadge extends StatelessWidget {
  final String rating;
  const _RatingBadge({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.wp(2),
        vertical: context.hp(0.4),
      ),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded,
              size: context.sp(13), color: AppColors.dark),
          SizedBox(width: context.wp(0.8)),
          Text(
            rating,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: context.sp(12),
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tag pill ─────────────────────────────────────────────────────────────────

class _TagPill extends StatelessWidget {
  final String tag;
  const _TagPill({required this.tag});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.wp(3),
        vertical: context.hp(0.5),
      ),
      decoration: BoxDecoration(
        color: AppColors.tagBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        tag,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: context.sp(12),
          fontWeight: FontWeight.w500,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

// ── Dot texture ───────────────────────────────────────────────────────────────

class _DotTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;
    const spacing = 28.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotTexturePainter _) => false;
}
