import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../resources/app_theme.dart';
import '../../resources/data.dart';
import '../../utils/responsive.dart';
import '../../widgets/home/category_row.dart';
import '../../widgets/home/post_feed_item.dart';
import '../../widgets/shared/app_shimmer.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1600), () {
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
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: _loading
                    ? const _ShimmerFeed(key: ValueKey('shimmer'))
                    : const _LiveFeed(key: ValueKey('live')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Top app bar ──────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.wp(4),
          vertical: context.hp(1),
        ),
        child: Row(
          children: [
            // Brand logo — fixed left
            Image.asset(
              'lib/assets/idli-icon.png',
              height: context.sp(34),
              fit: BoxFit.contain,
            ),

            // Location pill — Expanded+Center gives all middle space while
            // keeping the pill at its natural intrinsic width
            Expanded(
              child: Center(child: _LocationPill()),
            ),

            // User avatar — fixed right
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.grey.withValues(alpha: 0.4),
              child: const Icon(
                Icons.person_outline_rounded,
                color: AppColors.greyDark,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.wp(3),
        vertical: context.hp(0.8),
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border:
            Border.all(color: AppColors.grey.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on_rounded,
              size: context.sp(14), color: AppColors.primary),
          SizedBox(width: context.wp(1)),
          Text(
            AppData.homeCity,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: context.sp(13),
              fontWeight: FontWeight.w600,
              color: AppColors.dark,
            ),
          ),
          SizedBox(width: context.wp(1)),
          Icon(Icons.keyboard_arrow_down_rounded,
              size: context.sp(18), color: AppColors.greyDark),
        ],
      ),
    );
  }
}

// ── Live feed ────────────────────────────────────────────────────────────────

class _LiveFeed extends StatelessWidget {
  const _LiveFeed({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(child: CategoryRow()),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            context.wp(4),
            context.hp(1),
            context.wp(4),
            context.hp(2),
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => PostFeedItem(
                post: AppData.placeholderPosts[
                    i % AppData.placeholderPosts.length],
                index: i,
              ),
              childCount: 9,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Shimmer skeleton feed ────────────────────────────────────────────────────

class _ShimmerFeed extends StatelessWidget {
  const _ShimmerFeed({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        context.wp(4),
        0,
        context.wp(4),
        context.hp(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ShimmerCategoryRow(),
          SizedBox(height: context.hp(1)),
          _ShimmerPostItem(),
        ],
      ),
    );
  }
}

class _ShimmerCategoryRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: context.hp(12),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        separatorBuilder: (_, __) => SizedBox(width: context.wp(3)),
        itemBuilder: (_, __) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppShimmer(
              width: context.wp(14),
              height: context.wp(14),
              borderRadius: BorderRadius.circular(context.wp(7)),
            ),
            SizedBox(height: context.hp(0.5)),
            AppShimmer(
              width: context.wp(13),
              height: context.sp(10),
            ),
          ],
        ),
      ),
    );
  }
}

// Uses LayoutBuilder so card height precisely matches the real PostCard aspect ratio.
class _ShimmerPostItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardHeight = constraints.maxWidth * (4 / 3);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card
            AppShimmer(
              width: double.infinity,
              height: cardHeight,
              borderRadius: BorderRadius.circular(20),
            ),
            SizedBox(height: context.hp(1.5)),

            // Actions row
            Row(
              children: [
                AppShimmer(
                  width: context.sp(28),
                  height: context.sp(28),
                  borderRadius: BorderRadius.circular(6),
                ),
                SizedBox(width: context.wp(4)),
                AppShimmer(
                  width: context.sp(28),
                  height: context.sp(28),
                  borderRadius: BorderRadius.circular(6),
                ),
                SizedBox(width: context.wp(4)),
                AppShimmer(
                  width: context.sp(28),
                  height: context.sp(28),
                  borderRadius: BorderRadius.circular(6),
                ),
                const Spacer(),
                AppShimmer(
                  width: context.wp(14),
                  height: context.sp(36),
                  borderRadius: BorderRadius.circular(10),
                ),
              ],
            ),
            SizedBox(height: context.hp(1.2)),

            // Dish name
            AppShimmer(
              width: context.wp(55),
              height: context.sp(18),
            ),
            SizedBox(height: context.hp(0.8)),

            // Description lines
            AppShimmer(width: double.infinity, height: context.sp(13)),
            SizedBox(height: context.hp(0.5)),
            AppShimmer(width: double.infinity, height: context.sp(13)),
            SizedBox(height: context.hp(0.5)),
            AppShimmer(width: context.wp(50), height: context.sp(13)),
            SizedBox(height: context.hp(1)),

            // Tag pill
            AppShimmer(
              width: context.wp(24),
              height: context.sp(26),
              borderRadius: BorderRadius.circular(14),
            ),
          ],
        );
      },
    );
  }
}
