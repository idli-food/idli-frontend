import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../../models/comment.dart';
import '../../models/feed_post.dart';
import '../../providers/instant_feed_provider.dart';
import '../../providers/profile_provider.dart';
import '../../resources/app_theme.dart';
import '../../services/post_service.dart';
import '../../utils/responsive.dart';

class InstantFeedScreen extends ConsumerWidget {
  const InstantFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final instantAsync = ref.watch(instantFeedProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            instantAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              error: (e, _) => _ErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(instantFeedProvider),
              ),
              data: (posts) => posts.isEmpty
                  ? const _EmptyState()
                  : _ReelsPager(posts: posts),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.wp(4),
                    vertical: context.hp(1),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Instant',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: context.sp(20),
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => ref.invalidate(instantFeedProvider),
                        child: Icon(
                          Icons.refresh_rounded,
                          color: Colors.white,
                          size: context.sp(24),
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
    );
  }
}

class _ReelsPager extends StatefulWidget {
  final List<FeedPost> posts;
  const _ReelsPager({required this.posts});

  @override
  State<_ReelsPager> createState() => _ReelsPagerState();
}

class _ReelsPagerState extends State<_ReelsPager> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      scrollDirection: Axis.vertical,
      itemCount: widget.posts.length,
      onPageChanged: (i) => setState(() => _current = i),
      itemBuilder: (_, i) => _InstantReel(
        key: ValueKey(widget.posts[i].id),
        post: widget.posts[i],
        isActive: i == _current,
      ),
    );
  }
}

class _InstantReel extends ConsumerStatefulWidget {
  final FeedPost post;
  final bool isActive;

  const _InstantReel({super.key, required this.post, required this.isActive});

  @override
  ConsumerState<_InstantReel> createState() => _InstantReelState();
}

class _InstantReelState extends ConsumerState<_InstantReel> {
  final _service = PostService();
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _muted = false;
  bool _expanded = false;

  late bool _liked = widget.post.isLiked;
  late bool _saved = widget.post.isSaved;
  late int _likeCount = widget.post.likeCount;
  late int _commentCount = widget.post.commentCount;
  bool _likeLoading = false;
  bool _saveLoading = false;

  @override
  void initState() {
    super.initState();
    final url = widget.post.mediaUrl;
    if (url != null) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(url))
        ..setLooping(true)
        ..initialize().then((_) {
          if (!mounted) return;
          setState(() => _initialized = true);
          if (widget.isActive) _controller?.play();
        });
    }
  }

  @override
  void didUpdateWidget(_InstantReel old) {
    super.didUpdateWidget(old);
    if (old.isActive != widget.isActive && _initialized) {
      if (widget.isActive) {
        _controller?.play();
      } else {
        _controller?.pause();
        _controller?.seekTo(Duration.zero);
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    _controller?.setVolume(_muted ? 0 : 1);
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
      if (mounted) {
        setState(() {
          _liked = wasLiked;
          _likeCount += wasLiked ? 1 : -1;
        });
      }
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

  void _openComments() {
    final currentUsername =
        ref.read(profileProvider).valueOrNull?.username ?? '';
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InstantCommentSheet(
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
    final post = widget.post;

    return GestureDetector(
      onTap: _toggleMute,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video
          if (_initialized && _controller != null)
            FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: _controller!.value.size.width,
                height: _controller!.value.size.height,
                child: VideoPlayer(_controller!),
              ),
            )
          else
            Container(color: Colors.black),

          // Top gradient + author
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                context.wp(4),
                context.hp(7),
                context.wp(4),
                context.hp(5),
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  post.avatarUrl != null
                      ? CircleAvatar(
                          radius: 18,
                          backgroundImage: NetworkImage(post.avatarUrl!),
                        )
                      : CircleAvatar(
                          radius: 18,
                          backgroundColor:
                              AppColors.grey.withValues(alpha: 0.6),
                          child: const Icon(Icons.person,
                              color: Colors.white, size: 18),
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
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        if (post.hotelName != null &&
                            post.hotelName != post.username)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_on_rounded,
                                  size: context.sp(11),
                                  color: Colors.white
                                      .withValues(alpha: 0.75)),
                              SizedBox(width: context.wp(1)),
                              Flexible(
                                child: Text(
                                  post.hotelName!,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    color: Colors.white
                                        .withValues(alpha: 0.75),
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
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Mute indicator
          if (_muted)
            Center(
              child: Container(
                padding: EdgeInsets.all(context.wp(3)),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.volume_off_rounded,
                    color: Colors.white, size: context.sp(28)),
              ),
            ),

          // Right action rail
          Positioned(
            right: context.wp(3.5),
            bottom: context.hp(14),
            child: Column(
              children: [
                _RailAction(
                  icon: _liked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: _liked ? Colors.red.shade400 : Colors.white,
                  label: _likeCount.toString(),
                  onTap: _toggleLike,
                ),
                SizedBox(height: context.hp(2.5)),
                _RailAction(
                  icon: Icons.chat_bubble_outline_rounded,
                  color: Colors.white,
                  label: _commentCount.toString(),
                  onTap: _openComments,
                ),
                SizedBox(height: context.hp(2.5)),
                _RailAction(
                  icon: _saved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: _saved ? AppColors.accent : Colors.white,
                  onTap: _toggleSave,
                ),
              ],
            ),
          ),

          // Bottom gradient + description
          if (post.description.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  context.wp(4),
                  context.hp(6),
                  context.wp(18),
                  context.hp(4),
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Text(
                    post.description,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Colors.white,
                      fontSize: context.sp(13),
                      height: 1.4,
                    ),
                    maxLines: _expanded ? null : 2,
                    overflow: _expanded
                        ? TextOverflow.clip
                        : TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RailAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String? label;
  final VoidCallback onTap;

  const _RailAction({
    required this.icon,
    required this.color,
    this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: context.sp(30)),
          if (label != null) ...[
            SizedBox(height: context.hp(0.4)),
            Text(
              label!,
              style: TextStyle(
                fontFamily: 'Inter',
                color: Colors.white,
                fontSize: context.sp(12),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, size: context.sp(52), color: Colors.white54),
          SizedBox(height: context.hp(2)),
          Text(
            'No instant clips right now',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: context.sp(15),
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

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
                size: context.sp(48), color: Colors.white54),
            SizedBox(height: context.hp(2)),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: context.sp(16),
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            SizedBox(height: context.hp(0.8)),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: context.sp(12),
                color: Colors.white70,
              ),
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

// ── Comment sheet ────────────────────────────────────────────────────────────

class _InstantCommentSheet extends StatefulWidget {
  final String postId;
  final PostService service;
  final String currentUsername;
  final void Function(int delta) onCountChanged;

  const _InstantCommentSheet({
    required this.postId,
    required this.service,
    required this.currentUsername,
    required this.onCountChanged,
  });

  @override
  State<_InstantCommentSheet> createState() => _InstantCommentSheetState();
}

class _InstantCommentSheetState extends State<_InstantCommentSheet> {
  final _controller = TextEditingController();
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
    super.dispose();
  }

  Future<void> _loadComments() async {
    try {
      final comments = await widget.service.getComments(widget.postId);
      if (mounted) {
        setState(() {
          _comments = comments;
          _loading = false;
        });
      }
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
      if (mounted) FocusScope.of(context).unfocus();
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
          Flexible(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                    ? Padding(
                        padding: EdgeInsets.symmetric(vertical: context.hp(3)),
                        child: Text(
                          'No comments yet. Be the first!',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: context.sp(13),
                            color: AppColors.greyDark,
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: _comments.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: AppColors.grey.withValues(alpha: 0.15),
                        ),
                        itemBuilder: (_, i) {
                          final c = _comments[i];
                          return Padding(
                            padding:
                                EdgeInsets.symmetric(vertical: context.hp(1)),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                c.avatar != null
                                    ? CircleAvatar(
                                        radius: 16,
                                        backgroundImage:
                                            NetworkImage(c.avatar!),
                                      )
                                    : CircleAvatar(
                                        radius: 16,
                                        backgroundColor: AppColors.grey
                                            .withValues(alpha: 0.3),
                                        child: const Icon(Icons.person,
                                            size: 16, color: Colors.white),
                                      ),
                                SizedBox(width: context.wp(2.5)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c.username,
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: context.sp(13),
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.dark,
                                        ),
                                      ),
                                      SizedBox(height: context.hp(0.4)),
                                      Text(
                                        c.content,
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
                        },
                      ),
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: AppColors.grey.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
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
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
              ),
              SizedBox(width: context.wp(3)),
              GestureDetector(
                onTap: _submit,
                child: Container(
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
