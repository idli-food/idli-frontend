import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/saved_post.dart';
import '../../models/saved_thumb.dart';
import '../../resources/app_theme.dart';
import '../../resources/data.dart';
import '../../services/post_service.dart';
import '../../utils/responsive.dart';
import '../../widgets/home/post_feed_item.dart';
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
  State<SavedScreen> createState() => SavedScreenState();
}

class SavedScreenState extends State<SavedScreen> {
  int _filterIndex = 0;
  List<SavedThumb>? _thumbs;
  String? _thumbError;

  // non-null while the inline feed view is open
  List<SavedPost>? _feedPosts;
  int? _feedIndex;
  bool _feedLoading = false;
  String? _feedError;

  @override
  void initState() {
    super.initState();
    _fetchThumbnails();
  }

  void refresh() => _fetchThumbnails();

  Future<void> _fetchThumbnails() async {
    setState(() { _thumbs = null; _thumbError = null; _feedPosts = null; _feedIndex = null; });
    try {
      final thumbs = await PostService().getSavedThumbnails();
      if (mounted) setState(() => _thumbs = thumbs);
    } catch (e) {
      if (mounted) setState(() => _thumbError = e.toString());
    }
  }

  Future<void> _openFeed(String tappedId) async {
    setState(() { _feedLoading = true; _feedError = null; });
    try {
      final posts = await PostService().getSavedFeed();
      final index = posts.indexWhere((p) => p.id == tappedId);
      if (mounted) {
        setState(() {
          _feedPosts = posts;
          _feedIndex = index < 0 ? 0 : index;
          _feedLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _feedLoading = false; _feedError = e.toString(); });
    }
  }

  void _closeFeed() => setState(() { _feedPosts = null; _feedIndex = null; _feedError = null; });

  @override
  Widget build(BuildContext context) {
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
              : Stack(
                  children: [
                    Column(
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
                            child: _thumbs == null && _thumbError == null
                                ? const _ShimmerGrid(key: ValueKey('shimmer'))
                                : _thumbError != null
                                    ? _ErrorState(
                                        key: const ValueKey('error'),
                                        message: _thumbError!,
                                        onRetry: _fetchThumbnails,
                                      )
                                    : _LiveGrid(
                                        key: const ValueKey('live'),
                                        thumbs: _thumbs!,
                                        onPostTap: _openFeed,
                                        onRefresh: _fetchThumbnails,
                                      ),
                          ),
                        ),
                      ],
                    ),
                    // loading overlay while fetching feed after tap
                    if (_feedLoading)
                      const Positioned.fill(
                        child: ColoredBox(
                          color: Color(0x55FFFFFF),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                    // error snackbar-style banner
                    if (_feedError != null)
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Material(
                          color: Colors.red.shade400,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Could not open post. Tap to retry.',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'Inter',
                                        fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Inline feed view ─────────────────────────────────────────────────────────

class _InlineFeed extends StatefulWidget {
  final List<SavedPost> posts;
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
            child: PostFeedItem(
              post: widget.posts[i].toFeedPost(),
              index: i,
            ),
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
  final List<SavedThumb> thumbs;
  final void Function(String id) onPostTap;
  final Future<void> Function() onRefresh;
  const _LiveGrid({super.key, required this.thumbs, required this.onPostTap, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (thumbs.isEmpty) {
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
                  Icon(Icons.bookmark_border_rounded,
                      size: context.sp(48), color: AppColors.grey),
                  SizedBox(height: context.hp(2)),
                  Text(
                    'Nothing saved yet',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: context.sp(16),
                      fontWeight: FontWeight.w600,
                      color: AppColors.dark,
                    ),
                  ),
                  SizedBox(height: context.hp(0.8)),
                  Text(
                    'Bookmark posts from your feed to see them here.',
                    style: AppTextStyles.secondary.copyWith(fontSize: context.sp(13)),
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
      child: GridView.builder(
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
        itemCount: thumbs.length,
        itemBuilder: (_, i) => _SavedCard(
          thumb: thumbs[i],
          index: i,
          onTap: () => onPostTap(thumbs[i].id),
        ),
      ),
    );
  }
}

class _SavedCard extends StatelessWidget {
  final SavedThumb thumb;
  final int index;
  final VoidCallback onTap;
  const _SavedCard({
    required this.thumb,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final gradientPair = _cardGradients[index % _cardGradients.length];

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            // Gradient background (always visible — shows while image loads)
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

            // Thumbnail image
            if (thumb.thumbnailUrl != null)
              Positioned.fill(
                child: Image.network(
                  thumb.thumbnailUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) =>
                      progress == null ? child : const SizedBox.shrink(),
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),

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

            // Video indicator — bottom-left
            if (thumb.isVideo)
              Positioned(
                bottom: context.hp(1.2),
                left: context.wp(2.5),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.wp(1.8),
                    vertical: context.hp(0.35),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    size: context.sp(14),
                    color: Colors.white,
                  ),
                ),
              ),
          ],
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
              'Could not load saved posts',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: context.sp(16),
                fontWeight: FontWeight.w600,
                color: AppColors.dark,
              ),
            ),
            SizedBox(height: context.hp(1)),
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
