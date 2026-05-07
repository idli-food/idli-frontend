import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../resources/app_theme.dart';
import '../../resources/data.dart';
import '../../utils/responsive.dart';
import '../../widgets/shared/app_shimmer.dart';

const _cardGradients = [
  [Color(0xFF2C1B4E), Color(0xFF0D0820)],
  [Color(0xFF1A2744), Color(0xFF060D1C)],
  [Color(0xFF2C1B1B), Color(0xFF120808)],
  [Color(0xFF1A3028), Color(0xFF060F0A)],
  [Color(0xFF2A1A2C), Color(0xFF100812)],
];

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  int _filterIndex = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            _TopBar(),
            SizedBox(height: context.hp(1.2)),
            _FilterRow(
              selected: _filterIndex,
              onSelect: (i) => setState(() => _filterIndex = i),
            ),
            SizedBox(height: context.hp(0.5)),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: _loading
                    ? const _ShimmerGrid(key: ValueKey('shimmer'))
                    : const _LiveGrid(key: ValueKey('live')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          context.wp(4),
          context.hp(2),
          context.wp(4),
          0,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppData.savedTitle,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: context.sp(26),
                      fontWeight: FontWeight.w800,
                      color: AppColors.dark,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: context.hp(0.3)),
                  Text(
                    AppData.savedSubtitle,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: context.sp(13),
                      color: AppColors.greyDark,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: Container(
                width: context.sp(42),
                height: context.sp(42),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.search_rounded,
                  color: AppColors.dark,
                  size: context.sp(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filter chips ──────────────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  const _FilterRow({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: context.hp(4.8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: context.wp(4)),
        physics: const BouncingScrollPhysics(),
        itemCount: AppData.savedFilters.length,
        separatorBuilder: (_, __) => SizedBox(width: context.wp(2.5)),
        itemBuilder: (_, i) => _FilterChip(
          label: AppData.savedFilters[i],
          isActive: selected == i,
          onTap: () => onSelect(i),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: context.wp(4.5),
          vertical: context.hp(0.8),
        ),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? AppColors.primary
                : AppColors.grey.withValues(alpha: 0.35),
            width: 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.28),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: context.sp(13),
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? Colors.white : AppColors.greyDark,
          ),
        ),
      ),
    );
  }
}

// ── Live grid ─────────────────────────────────────────────────────────────────

class _LiveGrid extends StatelessWidget {
  const _LiveGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final posts = AppData.placeholderPosts;
    final items = List.generate(8, (i) => posts[i % posts.length]);

    return GridView.builder(
      padding: EdgeInsets.fromLTRB(
        context.wp(4),
        context.hp(1),
        context.wp(4),
        context.hp(2),
      ),
      physics: const BouncingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: context.wp(3),
        mainAxisSpacing: context.hp(1.5),
        childAspectRatio: 0.72,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _SavedCard(post: items[i], index: i),
    );
  }
}

class _SavedCard extends StatelessWidget {
  final Map<String, String> post;
  final int index;
  const _SavedCard({required this.post, required this.index});

  @override
  Widget build(BuildContext context) {
    final gradientPair = _cardGradients[index % _cardGradients.length];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: gradientPair[0].withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // Gradient background
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

            // Dot texture
            Positioned.fill(child: CustomPaint(painter: _DotPainter())),

            // Bookmark badge — top-right
            Positioned(
              top: context.hp(1.2),
              right: context.wp(2.5),
              child: Container(
                width: context.sp(30),
                height: context.sp(30),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.bookmark_rounded,
                  color: AppColors.accent,
                  size: context.sp(17),
                ),
              ),
            ),

            // Rating badge — top-left
            Positioned(
              top: context.hp(1.2),
              left: context.wp(2.5),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.wp(1.8),
                  vertical: context.hp(0.35),
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded,
                        size: context.sp(11), color: AppColors.dark),
                    SizedBox(width: context.wp(0.8)),
                    Text(
                      post['rating']!,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: context.sp(10),
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  context.wp(3),
                  context.hp(4),
                  context.wp(3),
                  context.hp(1.8),
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.82),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      post['dish']!,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Colors.white,
                        fontSize: context.sp(12),
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: context.hp(0.3)),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          color: AppColors.accent,
                          size: context.sp(10),
                        ),
                        SizedBox(width: context.wp(0.8)),
                        Flexible(
                          child: Text(
                            post['restaurant']!,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: Colors.white.withValues(alpha: 0.72),
                              fontSize: context.sp(10),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shimmer grid ──────────────────────────────────────────────────────────────

class _ShimmerGrid extends StatelessWidget {
  const _ShimmerGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(
        context.wp(4),
        context.hp(1),
        context.wp(4),
        context.hp(2),
      ),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: context.wp(3),
        mainAxisSpacing: context.hp(1.5),
        childAspectRatio: 0.72,
      ),
      itemCount: 8,
      itemBuilder: (_, __) => AppShimmer(
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }
}

// ── Dot painter ───────────────────────────────────────────────────────────────

class _DotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;
    const spacing = 22.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotPainter _) => false;
}
