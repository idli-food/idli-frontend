import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../models/comment.dart';
import '../../models/feed_post.dart';
import '../../providers/feed_provider.dart';
import '../../providers/profile_provider.dart';
import '../../resources/app_theme.dart';
import '../../services/post_service.dart';
import '../../utils/responsive.dart';
import '../../views/post-auth/post_location_screen.dart';

const _cardGradients = [
  [Color(0xFF2C1B4E), Color(0xFF0D0820)],
  [Color(0xFF1A2744), Color(0xFF060D1C)],
  [Color(0xFF2C1B1B), Color(0xFF120808)],
];

class PostFeedItem extends ConsumerStatefulWidget {
  final FeedPost post;
  final int index;

  const PostFeedItem({super.key, required this.post, required this.index});

  @override
  ConsumerState<PostFeedItem> createState() => _PostFeedItemState();
}

class _PostFeedItemState extends ConsumerState<PostFeedItem> {
  late bool _liked;
  late bool _saved;
  late int _likeCount;
  late int _commentCount;
  bool _likeLoading = false;
  bool _saveLoading = false;
  bool _ratingLoading = false;
  bool _expanded = false;
  bool _muted = false;
  final _service = PostService();

  @override
  void initState() {
    super.initState();
    _liked = widget.post.isLiked;
    _saved = widget.post.isSaved;
    _likeCount = widget.post.likeCount;
    _commentCount = widget.post.commentCount;
  }

  Future<void> _deleteRating() async {
    if (_ratingLoading) return;
    setState(() => _ratingLoading = true);
    try {
      await _service.unratePost(widget.post.id);
      if (mounted) ref.invalidate(feedProvider);
    } catch (_) {
      // leave the feed as-is on failure
    } finally {
      if (mounted) setState(() => _ratingLoading = false);
    }
  }

  Future<void> _editPost() async {
    final descriptionController =
        TextEditingController(text: widget.post.description);

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit post'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved != true) return;

    try {
      await _service.updatePost(
        widget.post.id,
        description: descriptionController.text.trim(),
      );
      if (mounted) ref.invalidate(feedProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update post')),
        );
      }
    }
  }

  Future<void> _deletePost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete post'),
        content: const Text('This post will be deleted permanently.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.deletePost(widget.post.id);
      if (mounted) ref.invalidate(feedProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete post')),
        );
      }
    }
  }

  Future<void> _toggleLike() async {
    if (_likeLoading) return;
    final wasLiked = _liked;
    setState(() {
      _liked = !_liked;
      _likeCount += _liked ? 1 : -1;
      _likeLoading = true;
    });
    try {
      if (_liked) {
        await _service.likePost(widget.post.id);
      } else {
        await _service.unlikePost(widget.post.id);
      }
    } catch (_) {
      setState(() {
        _liked = wasLiked;
        _likeCount += wasLiked ? 1 : -1;
      });
    } finally {
      if (mounted) setState(() => _likeLoading = false);
    }
  }

  Future<void> _toggleSave() async {
    if (_saveLoading) return;
    final wasSaved = _saved;
    setState(() {
      _saved = !_saved;
      _saveLoading = true;
    });
    try {
      if (_saved) {
        await _service.savePost(widget.post.id);
      } else {
        await _service.unsavePost(widget.post.id);
      }
    } catch (_) {
      if (mounted) setState(() => _saved = wasSaved);
    } finally {
      if (mounted) setState(() => _saveLoading = false);
    }
  }

  void _showLocation() {
    final lat = widget.post.latitude;
    final lon = widget.post.longitude;
    if (lat == null || lon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No location available for this post')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PostLocationScreen(
          lat: lat,
          lon: lon,
          label: widget.post.hotelName ?? 'Location',
        ),
      ),
    );
  }

  void _openComments() {
    final currentUsername =
        ref.read(profileProvider).valueOrNull?.username ?? '';
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CommentSheet(
        postId: widget.post.id,
        service: _service,
        currentUsername: currentUsername,
        onCountChanged: (delta) {
          if (mounted) setState(() => _commentCount += delta);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gradientPair =
        _cardGradients[widget.index % _cardGradients.length];

    return Padding(
      padding: EdgeInsets.only(bottom: context.hp(2.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PostCard(
              post: widget.post,
              gradientPair: gradientPair,
              likeCount: _likeCount,
              showDeleteRating:
                  widget.post.isMine && widget.post.ratings.isNotEmpty,
              onDeleteRating: _deleteRating,
              onEditPost: _editPost,
              onDeletePost: _deletePost,
              muted: _muted,
              onToggleMute: () => setState(() => _muted = !_muted)),

          SizedBox(height: context.hp(1.5)),

          _ActionsRow(
            liked: _liked,
            saved: _saved,
            likeCount: _likeCount,
            commentCount: _commentCount,
            onLike: _toggleLike,
            onSave: _toggleSave,
            onComment: _openComments,
            onLocation: _showLocation,
          ),

          SizedBox(height: context.hp(1.2)),

          Align(
            alignment: Alignment.centerRight,
            child: _RatingBadge(
                rating: widget.post.avgRating.toStringAsFixed(1)),
          ),

          SizedBox(height: context.hp(0.7)),

          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _expanded = !_expanded),
            child: Text(
              widget.post.description,
              style: AppTextStyles.secondary.copyWith(
                fontSize: context.sp(13),
                height: 1.5,
              ),
              maxLines: _expanded ? null : 3,
              overflow: _expanded ? TextOverflow.clip : TextOverflow.ellipsis,
            ),
          ),

          SizedBox(height: context.hp(0.9)),

          if (_expanded && widget.post.ratings.isNotEmpty) ...[
            _RatingBreakdown(ratings: widget.post.ratings),
            SizedBox(height: context.hp(0.3)),
          ],
        ],
      ),
    );
  }
}

// ── Card ─────────────────────────────────────────────────────────────────────

class _PostCard extends StatelessWidget {
  final FeedPost post;
  final List<Color> gradientPair;
  final int likeCount;
  final bool showDeleteRating;
  final VoidCallback onDeleteRating;
  final VoidCallback onEditPost;
  final VoidCallback onDeletePost;
  final bool muted;
  final VoidCallback onToggleMute;

  const _PostCard(
      {required this.post,
      required this.gradientPair,
      required this.likeCount,
      required this.showDeleteRating,
      required this.onDeleteRating,
      required this.onEditPost,
      required this.onDeletePost,
      required this.muted,
      required this.onToggleMute});

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
              // Gradient always visible — placeholder while image loads + fallback
              Positioned.fill(
                child: _GradientBackground(gradientPair: gradientPair),
              ),

              // Dot texture always present
              Positioned.fill(
                child: CustomPaint(painter: _DotTexturePainter()),
              ),

              // Media overlaid on top; gradient shows through while loading
              if (post.mediaUrl != null)
                Positioned.fill(
                  child: post.isVideo
                      ? _VideoMedia(
                          url: post.mediaUrl!,
                          muted: muted,
                          onToggleMute: onToggleMute,
                        )
                      : Image.network(
                          post.mediaUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (_, child, progress) =>
                              progress == null ? child : const SizedBox.shrink(),
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                ),

              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _TopOverlay(
                  post: post,
                  showDeleteRating: showDeleteRating,
                  onDeleteRating: onDeleteRating,
                  onEditPost: onEditPost,
                  onDeletePost: onDeletePost,
                ),
              ),

              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _BottomOverlay(username: post.username, likeCount: likeCount),
              ),

              if (post.isVideo)
                Positioned(
                  right: context.wp(3),
                  bottom: context.hp(2),
                  child: GestureDetector(
                    onTap: onToggleMute,
                    child: Container(
                      padding: EdgeInsets.all(context.wp(2)),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        muted
                            ? Icons.volume_off_rounded
                            : Icons.volume_up_rounded,
                        color: Colors.white,
                        size: context.sp(18),
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

class _GradientBackground extends StatelessWidget {
  final List<Color> gradientPair;
  const _GradientBackground({required this.gradientPair});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientPair,
        ),
      ),
    );
  }
}

class _TopOverlay extends StatelessWidget {
  final FeedPost post;
  final bool showDeleteRating;
  final VoidCallback onDeleteRating;
  final VoidCallback onEditPost;
  final VoidCallback onDeletePost;
  const _TopOverlay(
      {required this.post,
      required this.showDeleteRating,
      required this.onDeleteRating,
      required this.onEditPost,
      required this.onDeletePost});

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
          post.avatarUrl != null
              ? CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage(post.avatarUrl!),
                )
              : CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.grey.withValues(alpha: 0.6),
                  child:
                      const Icon(Icons.person, color: Colors.white, size: 18),
                ),
          SizedBox(width: context.wp(2.5)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  post.username,
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
                  '@${post.username}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: context.sp(11),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                if (post.hotelName != null &&
                    post.hotelName != post.username) ...[
                  SizedBox(height: context.hp(0.3)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: context.sp(11),
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                      SizedBox(width: context.wp(1)),
                      Flexible(
                        child: Text(
                          post.hotelName!,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: context.sp(11),
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (post.isMine)
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: Colors.white.withValues(alpha: 0.9),
                size: context.sp(22),
              ),
              onSelected: (value) {
                switch (value) {
                  case 'delete_rating':
                    onDeleteRating();
                  case 'edit_post':
                    onEditPost();
                  case 'delete_post':
                    onDeletePost();
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit_post',
                  child: Text('Edit post'),
                ),
                const PopupMenuItem(
                  value: 'delete_post',
                  child: Text('Delete post'),
                ),
                if (showDeleteRating)
                  const PopupMenuItem(
                    value: 'delete_rating',
                    child: Text('Delete rating'),
                  ),
              ],
            )
          else
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
  final String username;
  final int likeCount;
  const _BottomOverlay({required this.username, required this.likeCount});

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
              Icon(Icons.favorite_rounded,
                  color: AppColors.accent, size: context.sp(14)),
              SizedBox(width: context.wp(1.2)),
              Text(
                likeCount.toString(),
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Colors.white,
                  fontSize: context.sp(13),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Actions row ──────────────────────────────────────────────────────────────

class _ActionsRow extends StatelessWidget {
  final bool liked;
  final bool saved;
  final int likeCount;
  final int commentCount;
  final VoidCallback onLike;
  final VoidCallback onSave;
  final VoidCallback onComment;
  final VoidCallback onLocation;

  const _ActionsRow({
    required this.liked,
    required this.saved,
    required this.likeCount,
    required this.commentCount,
    required this.onLike,
    required this.onSave,
    required this.onComment,
    required this.onLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onLike,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: liked ? Colors.red.shade400 : AppColors.dark,
                size: context.sp(24),
              ),
              SizedBox(width: context.wp(1.2)),
              Text(
                likeCount.toString(),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: context.sp(14),
                  fontWeight: FontWeight.w600,
                  color: liked ? Colors.red.shade400 : AppColors.dark,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: context.wp(4.5)),
        GestureDetector(
          onTap: onComment,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppColors.dark,
                size: context.sp(24),
              ),
              SizedBox(width: context.wp(1.2)),
              Text(
                commentCount.toString(),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: context.sp(14),
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: context.wp(4.5)),
        _ActionIcon(
          icon: Icons.near_me_outlined,
          color: AppColors.dark,
          onTap: onLocation,
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
        vertical: context.hp(0.3),
      ),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        rating,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: context.sp(12),
          fontWeight: FontWeight.w700,
          color: AppColors.dark,
        ),
      ),
    );
  }
}

// ── Rating breakdown (per-category scores + reviews) ─────────────────────────

const _ratingCategoryLabels = {
  'food': 'Food',
  'service': 'Service',
  'cleanliness': 'Cleanliness',
  'value': 'Value',
};

class _RatingBreakdown extends StatelessWidget {
  final List<PostRating> ratings;
  const _RatingBreakdown({required this.ratings});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.hp(0.9)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final r in ratings) ...[
            Row(
              children: [
                SizedBox(
                  width: context.wp(24),
                  child: Text(
                    _ratingCategoryLabels[r.category] ?? r.category,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: context.sp(11),
                      fontWeight: FontWeight.w600,
                      color: AppColors.dark,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (i) {
                    final filled = (i + 1) <= r.score;
                    return Icon(
                      filled ? Icons.star_rounded : Icons.star_border_rounded,
                      size: context.sp(15),
                      color: filled ? AppColors.accent : AppColors.grey,
                    );
                  }),
                ),
              ],
            ),
            if (r.review.trim().isNotEmpty)
              Padding(
                padding: EdgeInsets.only(
                    left: context.wp(24), bottom: context.hp(0.6)),
                child: Text(
                  r.review,
                  style: AppTextStyles.secondary.copyWith(
                    fontSize: context.sp(11),
                    height: 1.3,
                  ),
                ),
              )
            else
              SizedBox(height: context.hp(0.6)),
          ],
        ],
      ),
    );
  }
}

// ── Dot texture ───────────────────────────────────────────────────────────────

// ── Video media ───────────────────────────────────────────────────────────────

class _VideoMedia extends StatefulWidget {
  final String url;
  final bool muted;
  final VoidCallback onToggleMute;
  const _VideoMedia({
    required this.url,
    required this.muted,
    required this.onToggleMute,
  });

  @override
  State<_VideoMedia> createState() => _VideoMediaState();
}

class _VideoMediaState extends State<_VideoMedia> {
  late final VideoPlayerController _controller;
  bool _initialized = false;
  double _visibleFraction = 0;

  @override
  void initState() {
    super.initState();
    _initController(widget.url);
  }

  @override
  void didUpdateWidget(_VideoMedia old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) {
      _controller.dispose();
      _initialized = false;
      _initController(widget.url);
    }
    if (old.muted != widget.muted) {
      _controller.setVolume(widget.muted ? 0 : 1);
    }
  }

  void _initController(String url) {
    _controller = VideoPlayerController.networkUrl(Uri.parse(url))
      ..setLooping(true)
      ..setVolume(widget.muted ? 0 : 1)
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _initialized = true);
          // Only start if the post is already mostly on screen.
          _applyVisibility(_visibleFraction);
        }
      });
  }

  // Play only while the post is mostly visible; pause and rewind once it has
  // scrolled mostly out of view so returning to it replays from the start.
  void _applyVisibility(double fraction) {
    _visibleFraction = fraction;
    if (!_initialized) return;
    if (fraction >= 0.6) {
      if (!_controller.value.isPlaying) _controller.play();
    } else if (fraction < 0.3) {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _controller.seekTo(Duration.zero);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: ValueKey('video-${widget.url}'),
      onVisibilityChanged: (info) {
        if (mounted) _applyVisibility(info.visibleFraction);
      },
      child: !_initialized
          ? const SizedBox.shrink()
          : GestureDetector(
              onTap: widget.onToggleMute,
              child: FittedBox(
                fit: BoxFit.cover,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            ),
    );
  }
}

// ── Comment sheet ─────────────────────────────────────────────────────────────

class _CommentSheet extends StatefulWidget {
  final String postId;
  final PostService service;
  final String currentUsername;
  final void Function(int delta) onCountChanged;

  const _CommentSheet({
    required this.postId,
    required this.service,
    required this.currentUsername,
    required this.onCountChanged,
  });

  @override
  State<_CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<_CommentSheet> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  List<Comment> _comments = [];
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    try {
      final comments = await widget.service.getComments(widget.postId);
      if (mounted) setState(() { _comments = comments; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await widget.service.addComment(widget.postId, text);
      _controller.clear();
      widget.onCountChanged(1);
      await _loadComments();
      if (mounted) {
        FocusScope.of(context).unfocus();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post comment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _deleteComment(Comment comment) async {
    setState(() => _comments.remove(comment));
    widget.onCountChanged(-1);
    try {
      await widget.service.deleteComment(widget.postId, comment.id);
    } catch (e) {
      if (mounted) {
        setState(() => _comments.insert(0, comment));
        widget.onCountChanged(1);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete comment: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: context.hp(1.5)),
          Text(
            'Comments',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: context.sp(16),
              fontWeight: FontWeight.w600,
              color: AppColors.dark,
            ),
          ),
          SizedBox(height: context.hp(1.5)),

          // comment list
          Flexible(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                    ? Padding(
                        padding: EdgeInsets.symmetric(vertical: context.hp(3)),
                        child: Text(
                          'No comments yet. Be the first!',
                          style: AppTextStyles.secondary
                              .copyWith(fontSize: context.sp(13)),
                        ),
                      )
                    : ListView.separated(
                        controller: _scrollController,
                        shrinkWrap: true,
                        itemCount: _comments.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: AppColors.grey.withValues(alpha: 0.15),
                        ),
                        itemBuilder: (_, i) {
                          final c = _comments[i];
                          final isOwn = c.username == widget.currentUsername;
                          return Dismissible(
                            key: ValueKey(c.id),
                            direction: isOwn
                                ? DismissDirection.endToStart
                                : DismissDirection.none,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 16),
                              color: Colors.red.shade50,
                              child: Icon(Icons.delete_outline_rounded,
                                  color: Colors.red.shade400),
                            ),
                            onDismissed: (_) => _deleteComment(c),
                            child: _CommentTile(comment: c),
                          );
                        },
                      ),
          ),

          const SizedBox(height: 12),
          Divider(height: 1, color: AppColors.grey.withValues(alpha: 0.2)),
          const SizedBox(height: 12),

          // input row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  maxLength: 2000,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _submit(),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: context.sp(14),
                    color: AppColors.dark,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Write something…',
                    counterText: '',
                    hintStyle: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: context.sp(14),
                      color: AppColors.grey,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: AppColors.grey.withValues(alpha: 0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: AppColors.grey.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
              ),
              SizedBox(width: context.wp(3)),
              GestureDetector(
                onTap: _submit,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _sending ? AppColors.grey : AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: _sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final Comment comment;
  const _CommentTile({required this.comment});

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.hp(1)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          comment.avatar != null
              ? CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(comment.avatar!),
                )
              : CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.grey.withValues(alpha: 0.3),
                  child: const Icon(Icons.person, size: 16, color: Colors.white),
                ),
          SizedBox(width: context.wp(2.5)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.username,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: context.sp(13),
                        fontWeight: FontWeight.w600,
                        color: AppColors.dark,
                      ),
                    ),
                    SizedBox(width: context.wp(2)),
                    Text(
                      _timeAgo(comment.createdAt),
                      style: AppTextStyles.secondary
                          .copyWith(fontSize: context.sp(11)),
                    ),
                  ],
                ),
                SizedBox(height: context.hp(0.4)),
                Text(
                  comment.content,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: context.sp(13),
                    color: AppColors.dark,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
