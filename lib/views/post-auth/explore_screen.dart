import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/feed_post.dart';
import '../../providers/location_provider.dart';
import '../../resources/app_theme.dart';
import '../../resources/data.dart';
import '../../services/post_service.dart';
import '../../utils/responsive.dart';
import '../../views/shared/location_picker_screen.dart';
import '../../widgets/home/post_feed_item.dart';
import '../../widgets/shared/app_shimmer.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  List<FeedPost>? _posts;
  String? _error;
  String _query = '';

  // track the last lat/lon we fetched so we don't re-fetch on unrelated rebuilds
  double? _fetchedLat;
  double? _fetchedLon;

  // inline feed overlay (opened when a thumbnail is tapped)
  List<FeedPost>? _feedPosts;
  int? _feedIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loc = ref.read(locationNotifierProvider);
      if (loc.selected == null && !loc.loading) {
        ref.read(locationNotifierProvider.notifier).fetchCurrent();
      } else if (loc.selected != null) {
        _fetchExplore('');
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => _fetchExplore(query),
    );
  }

  Future<void> _fetchExplore(String query) async {
    final loc = ref.read(locationNotifierProvider).selected;
    if (loc == null) return;
    _query = query.trim();
    _fetchedLat = loc.latitude;
    _fetchedLon = loc.longitude;
    setState(() {
      _posts = null;
      _error = null;
      _feedPosts = null;
      _feedIndex = null;
    });
    try {
      final posts = await PostService().getExploreFeed(
        lat: loc.latitude,
        lon: loc.longitude,
        query: _query,
      );
      posts.sort((a, b) => b.avgRating.compareTo(a.avgRating));
      if (mounted) setState(() => _posts = posts);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  void _openFeed(int index) =>
      setState(() { _feedPosts = _posts; _feedIndex = index; });

  void _closeFeed() => setState(() { _feedPosts = null; _feedIndex = null; });

  @override
  Widget build(BuildContext context) {
    // React to location becoming available / changing
    final locationState = ref.watch(locationNotifierProvider);
    final loc = locationState.selected;
    if (loc != null &&
        (loc.latitude != _fetchedLat || loc.longitude != _fetchedLon)) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _fetchExplore(_query),
      );
    }

    return PopScope(
      canPop: _feedIndex == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _feedIndex != null) _closeFeed();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: _feedIndex != null && _feedPosts != null
              ? _InlineFeed(
                  posts: _feedPosts!,
                  initialIndex: _feedIndex!,
                  onBack: _closeFeed,
                )
              : Column(
                  children: [
                    _TopBar(),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        context.wp(4),
                        context.hp(0.4),
                        context.wp(4),
                        context.hp(1.2),
                      ),
                      child: _SearchField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                      ),
                    ),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _buildGrid(locationState),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildGrid(LocationState locationState) {
    if (locationState.loading && _posts == null) {
      return const _ShimmerGrid(key: ValueKey('shimmer-loc'));
    }
    if (locationState.error != null && _posts == null) {
      return _ErrorState(
        key: const ValueKey('loc-error'),
        message: 'Could not get location',
        onRetry: () => ref.read(locationNotifierProvider.notifier).fetchCurrent(),
      );
    }
    if (_posts == null && _error == null) {
      return const _ShimmerGrid(key: ValueKey('shimmer'));
    }
    if (_error != null) {
      return _ErrorState(
        key: const ValueKey('error'),
        message: _error!,
        onRetry: () => _fetchExplore(_query),
      );
    }
    return _LiveGrid(
      key: const ValueKey('live'),
      posts: _posts!,
      query: _query,
      onPostTap: _openFeed,
      onRefresh: () => _fetchExplore(_query),
    );
  }
}

// ── Top app bar (matches feed screen) ────────────────────────────────────────

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
    final label = locationState.selected?.address ?? AppData.homeCity;

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

// ── Search field (food / hotel address) ──────────────────────────────────────

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: context.hp(6.2),
      decoration: BoxDecoration(
        color: const Color(0xFFE8E8E8),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        children: [
          SizedBox(width: context.wp(4)),
          Icon(
            Icons.search_rounded,
            color: AppColors.grey,
            size: context.sp(20),
          ),
          SizedBox(width: context.wp(2)),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: context.sp(13),
                color: AppColors.dark,
              ),
              decoration: InputDecoration(
                hintText: AppData.exploreSearchHint,
                hintStyle: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: context.sp(13),
                  color: AppColors.grey,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          SizedBox(width: context.wp(4)),
        ],
      ),
    );
  }
}

// ── Inline feed view ──────────────────────────────────────────────────────────

class _InlineFeed extends StatefulWidget {
  final List<FeedPost> posts;
  final int initialIndex;
  final VoidCallback onBack;

  const _InlineFeed({
    required this.posts,
    required this.initialIndex,
    required this.onBack,
  });

  @override
  State<_InlineFeed> createState() => _InlineFeedState();
}

class _InlineFeedState extends State<_InlineFeed> {
  late final PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          controller: _controller,
          scrollDirection: Axis.vertical,
          itemCount: widget.posts.length,
          onPageChanged: (i) => setState(() => _currentIndex = i),
          itemBuilder: (_, i) => SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              context.wp(4),
              context.hp(8),
              context.wp(4),
              context.hp(2),
            ),
            child: PostFeedItem(post: widget.posts[i], index: i),
          ),
        ),

        // back button
        SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: context.wp(2),
              top: context.hp(0.5),
            ),
            child: GestureDetector(
              onTap: widget.onBack,
              child: Container(
                width: context.sp(40),
                height: context.sp(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.dark,
                  size: context.sp(20),
                ),
              ),
            ),
          ),
        ),

        // page counter
        SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: EdgeInsets.only(
                right: context.wp(4),
                top: context.hp(1.2),
              ),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.wp(3),
                  vertical: context.hp(0.6),
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '${_currentIndex + 1} / ${widget.posts.length}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: context.sp(12),
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Live grid ─────────────────────────────────────────────────────────────────

class _LiveGrid extends StatelessWidget {
  final List<FeedPost> posts;
  final String query;
  final void Function(int index) onPostTap;
  final Future<void> Function() onRefresh;
  const _LiveGrid({
    super.key,
    required this.posts,
    required this.query,
    required this.onPostTap,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      final searching = query.isNotEmpty;
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
                  Icon(Icons.explore_outlined,
                      size: context.sp(48), color: AppColors.grey),
                  SizedBox(height: context.hp(2)),
                  Text(
                    searching ? 'Nothing found' : 'Nothing nearby',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: context.sp(16),
                      fontWeight: FontWeight.w600,
                      color: AppColors.dark,
                    ),
                  ),
                  SizedBox(height: context.hp(0.8)),
                  Text(
                    searching
                        ? 'No posts match your search here. Try another term.'
                        : 'No posts found in your area. Try a larger radius.',
                    style: AppTextStyles.secondary
                        .copyWith(fontSize: context.sp(13)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: Container(
        color: const Color(0xFF555555),
        child: GridView.builder(
          padding: EdgeInsets.zero,
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 0.5,
            mainAxisSpacing: 0.5,
            childAspectRatio: 1.0,
          ),
          itemCount: posts.length,
          itemBuilder: (_, i) => _ThumbCell(
            post: posts[i],
            onTap: () => onPostTap(i),
          ),
        ),
      ),
    );
  }
}

class _ThumbCell extends StatelessWidget {
  final FeedPost post;
  final VoidCallback onTap;
  const _ThumbCell({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final url = post.thumbnailUrl ?? post.mediaUrl;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          url != null
              ? Image.network(
                  url,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : AppShimmer(borderRadius: BorderRadius.zero),
                  errorBuilder: (_, __, ___) =>
                      AppShimmer(borderRadius: BorderRadius.zero),
                )
              : AppShimmer(borderRadius: BorderRadius.zero),
          if (post.isVideo)
            Positioned(
              top: 4,
              right: 4,
              child: Icon(
                Icons.play_circle_fill_rounded,
                color: Colors.white.withValues(alpha: 0.9),
                size: context.sp(16),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Shimmer grid ──────────────────────────────────────────────────────────────

class _ShimmerGrid extends StatelessWidget {
  const _ShimmerGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF555555),
      child: GridView.builder(
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 0.5,
          mainAxisSpacing: 0.5,
          childAspectRatio: 1.0,
        ),
        itemCount: 36,
        itemBuilder: (_, __) => AppShimmer(borderRadius: BorderRadius.zero),
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({super.key, required this.message, required this.onRetry});

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
              message,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: context.sp(15),
                fontWeight: FontWeight.w600,
                color: AppColors.dark,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.hp(2)),
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
