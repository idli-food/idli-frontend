import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../../models/comment.dart';
import '../../models/feed_post.dart';
import '../../providers/profile_provider.dart';
import '../../resources/app_theme.dart';
import '../../services/post_service.dart';
import '../../utils/responsive.dart';

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
  late int? _myRating;
  bool _likeLoading = false;
  bool _saveLoading = false;
  bool _ratingLoading = false;
  final _service = PostService();

  @override
  void initState() {
    super.initState();
    _liked = widget.post.isLiked;
    _saved = widget.post.isSaved;
    _likeCount = widget.post.likeCount;
    _commentCount = widget.post.commentCount;
    _myRating = widget.post.myRating;
  }

  Future<void> _submitRating(int stars) async {
    if (_ratingLoading || _myRating != null) return;
    setState(() {
      _myRating = stars;
      _ratingLoading = true;
    });
    try {
      await _service.ratePost(widget.post.id, stars);
    } catch (_) {
      if (mounted) setState(() => _myRating = null);
    } finally {
      if (mounted) setState(() => _ratingLoading = false);
    }
  }

  Future<void> _deleteRating() async {
    if (_ratingLoading || _myRating == null) return;
    final previous = _myRating;
    setState(() {
      _myRating = null;
      _ratingLoading = true;
    });
    try {
      await _service.unratePost(widget.post.id);
    } catch (_) {
      if (mounted) setState(() => _myRating = previous);
    } finally {
      if (mounted) setState(() => _ratingLoading = false);
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

  Future<void> _openDirections() async {
    final lat = widget.post.latitude;
    final lon = widget.post.longitude;
    if (lat == null || lon == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No location available for this post')),
        );
      }
      return;
    }
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon&travelmode=driving',
    );
    if (!await canLaunchUrl(url)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps')),
        );
      }
      return;
    }
    await launchUrl(url, mode: LaunchMode.externalApplication);
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
              myRating: _myRating,
              onDeleteRating: _deleteRating),

          SizedBox(height: context.hp(1.5)),

          _ActionsRow(
            liked: _liked,
            saved: _saved,
            likeCount: _likeCount,
            commentCount: _commentCount,
            onLike: _toggleLike,
            onSave: _toggleSave,
            onComment: _openComments,
            onLocation: _openDirections,
          ),

          _RatingRow(myRating: _myRating, onRate: _submitRating),

          SizedBox(height: context.hp(1.2)),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  widget.post.title,
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
              _RatingBadge(
                  rating: widget.post.avgRating.toStringAsFixed(1)),
            ],
          ),

          SizedBox(height: context.hp(0.7)),

          Text(
            widget.post.description,
            style: AppTextStyles.secondary.copyWith(
              fontSize: context.sp(13),
              height: 1.5,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),

          SizedBox(height: context.hp(0.9)),

          _TagPill(tag: '#${widget.post.title.replaceAll(' ', '').toLowerCase()}'),
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
  final int? myRating;
  final VoidCallback onDeleteRating;

  const _PostCard(
      {required this.post,
      required this.gradientPair,
      required this.likeCount,
      required this.myRating,
      required this.onDeleteRating});

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
                      ? _VideoMedia(url: post.mediaUrl!)
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
                  myRating: myRating,
                  onDeleteRating: onDeleteRating,
                ),
              ),

              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _BottomOverlay(username: post.username, likeCount: likeCount),
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
  final int? myRating;
  final VoidCallback onDeleteRating;
  const _TopOverlay(
      {required this.post,
      required this.myRating,
      required this.onDeleteRating});

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
              ],
            ),
          ),
          if (myRating != null)
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: Colors.white.withValues(alpha: 0.9),
                size: context.sp(22),
              ),
              onSelected: (value) {
                if (value == 'delete_rating') onDeleteRating();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
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

// ── Rating row (tap to rate) ─────────────────────────────────────────────────

class _RatingRow extends StatelessWidget {
  final int? myRating;
  final ValueChanged<int> onRate;
  const _RatingRow({required this.myRating, required this.onRate});

  @override
  Widget build(BuildContext context) {
    final rated = myRating != null;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.hp(0.9)),
      child: Row(
        children: [
          Text(
            rated ? 'Your rating' : 'Tap to rate',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: context.sp(11),
              fontWeight: FontWeight.w500,
              color: AppColors.grey,
            ),
          ),
          SizedBox(width: context.wp(2)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (i) {
              final n = i + 1;
              final filled = n <= (myRating ?? 0);
              return GestureDetector(
                onTap: rated ? null : () => onRate(n),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.wp(0.3)),
                  child: Icon(
                    filled ? Icons.star_rounded : Icons.star_border_rounded,
                    size: context.sp(20),
                    color: filled ? AppColors.accent : AppColors.grey,
                  ),
                ),
              );
            }),
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

// ── Video media ───────────────────────────────────────────────────────────────

class _VideoMedia extends StatefulWidget {
  final String url;
  const _VideoMedia({required this.url});

  @override
  State<_VideoMedia> createState() => _VideoMediaState();
}

class _VideoMediaState extends State<_VideoMedia> {
  late final VideoPlayerController _controller;
  bool _initialized = false;

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
  }

  void _initController(String url) {
    _controller = VideoPlayerController.networkUrl(Uri.parse(url))
      ..setLooping(true)
      ..setVolume(0)
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _initialized = true);
          _controller.play();
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) return const SizedBox.shrink();
    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: _controller.value.size.width,
        height: _controller.value.size.height,
        child: VideoPlayer(_controller),
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
