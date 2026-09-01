import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/feed_post.dart';
import '../../providers/feed_provider.dart';
import '../../providers/location_provider.dart';
import '../../resources/app_theme.dart';
import '../../resources/data.dart';
import '../../utils/responsive.dart';
import '../../views/shared/location_picker_screen.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/home/post_feed_item.dart';
import '../../widgets/shared/app_shimmer.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch device location on first load if not already set
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(locationNotifierProvider).selected == null) {
        ref.read(locationNotifierProvider.notifier).fetchCurrent();
      }
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
            Expanded(child: _FeedBody()),
          ],
        ),
      ),
    );
  }
}

// ── Feed body — driven by feedProvider ───────────────────────────────────────

class _FeedBody extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(locationNotifierProvider);
    final feedAsync = ref.watch(feedProvider);

    // Show shimmer while fetching location or waiting for first feed response
    if (locationState.loading || (locationState.selected == null && !locationState.loading)) {
      if (locationState.error != null) {
        return _ErrorState(
          message: locationState.error!,
          onRetry: () =>
              ref.read(locationNotifierProvider.notifier).fetchCurrent(),
        );
      }
      return const _ShimmerFeed();
    }

    Future<void> doRefresh() async => ref.invalidate(feedProvider);

    return feedAsync.when(
      loading: () => const _ShimmerFeed(),
      error: (e, _) => _ErrorState(
        message: e.toString(),
        onRetry: () => ref.invalidate(feedProvider),
      ),
      data: (posts) => posts.isEmpty
          ? _EmptyFeed(onRefresh: doRefresh)
          : _LiveFeed(posts: posts, onRefresh: doRefresh),
    );
  }
}

// ── Top app bar ──────────────────────────────────────────────────────────────

class _TopBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.wp(4),
          vertical: context.hp(1),
        ),
        child: Row(
          children: [
            Image.asset(
              'lib/assets/idli-icon.png',
              height: context.sp(34),
              fit: BoxFit.contain,
            ),
            Expanded(
              child: Center(child: _LocationPill()),
            ),
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

class _LocationPill extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(locationNotifierProvider);
    final label =
        locationState.selected?.address ?? AppData.homeCity;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.wp(3),
          vertical: context.hp(0.8),
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
              color: AppColors.grey.withValues(alpha: 0.3), width: 1),
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
            locationState.loading
                ? SizedBox(
                    width: context.sp(14),
                    height: context.sp(14),
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: AppColors.primary,
                    ),
                  )
                : Icon(Icons.location_on_rounded,
                    size: context.sp(14), color: AppColors.primary),
            SizedBox(width: context.wp(1)),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: context.wp(35)),
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: context.sp(13),
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark,
                ),
              ),
            ),
            SizedBox(width: context.wp(1)),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: context.sp(18), color: AppColors.greyDark),
          ],
        ),
      ),
    );
  }
}

// ── Live feed ────────────────────────────────────────────────────────────────

class _LiveFeed extends StatelessWidget {
  final List<FeedPost> posts;
  final Future<void> Function() onRefresh;
  const _LiveFeed({required this.posts, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(child: _WelcomeCard()),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            context.wp(4),
            context.hp(1),
            context.wp(4),
            context.hp(2),
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => PostFeedItem(key: ValueKey(posts[i].id), post: posts[i], index: i),
              childCount: posts.length,
            ),
          ),
        ),
      ],
      ),
    );
  }
}

// ── Welcome card ─────────────────────────────────────────────────────────────

class _WelcomeCard extends ConsumerWidget {
  const _WelcomeCard();

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good Morning';
    if (hour >= 12 && hour < 17) return 'Good Afternoon';
    if (hour >= 17 && hour < 21) return 'Good Evening';
    return 'Good Night';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final firstName = profileAsync.whenOrNull(
      data: (p) {
        final name = p.name.isNotEmpty ? p.name : p.username;
        return name.split(' ').first;
      },
    ) ?? '';

    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.wp(4),
        context.hp(1),
        context.wp(4),
        context.hp(1),
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          context.wp(4.5),
          context.hp(2),
          0,
          context.hp(2),
        ),
        decoration: BoxDecoration(
          color: AppColors.tagBackground,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('👋', style: TextStyle(fontSize: context.sp(20))),
                      SizedBox(width: context.wp(2)),
                      Flexible(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: context.sp(16),
                              fontWeight: FontWeight.w700,
                              color: AppColors.dark,
                            ),
                            children: [
                              TextSpan(text: '${_greeting()}, '),
                              TextSpan(
                                text: firstName,
                                style: const TextStyle(color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.hp(0.6)),
                  Text(
                    '12 new dishes trending near you',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: context.sp(12),
                      color: AppColors.greyDark,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: context.wp(28),
              height: context.hp(10),
              child: Image.asset(
                'lib/assets/welcome_card_vector.png',
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyFeed extends StatelessWidget {
  final Future<void> Function() onRefresh;
  const _EmptyFeed({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: context.hp(70),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.restaurant_menu_rounded,
                    size: context.sp(52), color: AppColors.grey),
                SizedBox(height: context.hp(2)),
                Text(
                  'No posts near you yet',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: context.sp(16),
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark,
                  ),
                ),
                SizedBox(height: context.hp(0.8)),
                Text(
                  'Be the first to share food in your area!',
                  style: AppTextStyles.secondary.copyWith(fontSize: context.sp(13)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.wp(8)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded,
                size: context.sp(48), color: AppColors.grey),
            SizedBox(height: context.hp(2)),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: context.sp(16),
                fontWeight: FontWeight.w600,
                color: AppColors.dark,
              ),
            ),
            SizedBox(height: context.hp(0.8)),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.secondary.copyWith(fontSize: context.sp(12)),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: context.hp(2.5)),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.wp(6),
                  vertical: context.hp(1.2),
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Retry',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: context.sp(14),
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shimmer skeleton feed ────────────────────────────────────────────────────

class _ShimmerFeed extends StatelessWidget {
  const _ShimmerFeed();

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

class _ShimmerPostItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardHeight = constraints.maxWidth * (4 / 3);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppShimmer(
              width: double.infinity,
              height: cardHeight,
              borderRadius: BorderRadius.circular(20),
            ),
            SizedBox(height: context.hp(1.5)),
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
            AppShimmer(
              width: context.wp(55),
              height: context.sp(18),
            ),
            SizedBox(height: context.hp(0.8)),
            AppShimmer(width: double.infinity, height: context.sp(13)),
            SizedBox(height: context.hp(0.5)),
            AppShimmer(width: double.infinity, height: context.sp(13)),
            SizedBox(height: context.hp(0.5)),
            AppShimmer(width: context.wp(50), height: context.sp(13)),
            SizedBox(height: context.hp(1)),
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
