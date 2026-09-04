import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../../models/hotel.dart';
import '../../providers/create_post_provider.dart';
import '../../providers/feed_provider.dart';
import '../../resources/app_theme.dart';
import '../../resources/data.dart';
import '../../services/post_service.dart';
import '../../utils/media_utils.dart';
import '../../utils/responsive.dart';
import '../../widgets/shared/app_gradient_button.dart';

class CreateScreen extends ConsumerStatefulWidget {
  const CreateScreen({super.key});

  @override
  ConsumerState<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends ConsumerState<CreateScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _picker = ImagePicker();
  final _pageController = PageController();
  int _step = 0;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _goToStep(int i) {
    setState(() => _step = i);
    _pageController.animateToPage(
      i,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _pickMedia({required bool isPhoto}) async {
    final XFile? picked = isPhoto
        ? await _picker.pickImage(source: ImageSource.gallery)
        : await _picker.pickVideo(source: ImageSource.gallery);
    if (picked == null || !mounted) return;
    final contentType = picked.mimeType ?? contentTypeFromPath(picked.path);
    ref.read(createPostNotifierProvider.notifier).setMedia(
          File(picked.path),
          isPhoto ? 'image' : 'video',
          contentType,
        );
  }

  Future<void> _pickHotel() async {
    final hotel = await showModalBottomSheet<Hotel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _HotelPickerSheet(),
    );
    if (hotel != null) {
      ref.read(createPostNotifierProvider.notifier).setHotel(hotel);
    }
  }

  void _submit() {
    ref.read(createPostNotifierProvider.notifier).submit(
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(createPostNotifierProvider, (_, next) {
      if (next.stage == UploadStage.done) {
        ref.invalidate(feedProvider);
        Navigator.of(context).pop(true);
      } else if (next.stage == UploadStage.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error ?? AppData.createPostErrorGeneric),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 5),
          ),
        );
        ref.read(createPostNotifierProvider.notifier).clearError();
      }
    });

    final state = ref.watch(createPostNotifierProvider);
    final canPost = state.selectedFile != null &&
        state.selectedHotel != null &&
        _titleController.text.trim().isNotEmpty &&
        state.ratingsComplete &&
        !state.isLoading;

    final canGoDetails = _titleController.text.trim().isNotEmpty &&
        state.selectedHotel != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            _step == 0 ? Icons.close : Icons.arrow_back,
            color: AppColors.dark,
          ),
          onPressed: state.isLoading
              ? null
              : () {
                  if (_step == 0) {
                    Navigator.of(context).pop();
                  } else {
                    _goToStep(_step - 1);
                  }
                },
        ),
        title: Text(
          AppData.createPostTitle,
          style: AppTextStyles.primary.copyWith(fontSize: context.sp(18)),
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: context.hp(1)),
          _StepDots(step: _step),
          SizedBox(height: context.hp(1)),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _StepPage(
                  children: [
                    _MediaZone(
                      state: state,
                      onPickPhoto: () => _pickMedia(isPhoto: true),
                      onPickVideo: () => _pickMedia(isPhoto: false),
                    ),
                    SizedBox(height: context.hp(3.5)),
                    AppGradientButton(
                      label: AppData.createPostNext,
                      onTap: state.selectedFile != null
                          ? () => _goToStep(1)
                          : null,
                    ),
                    SizedBox(height: context.hp(3)),
                  ],
                ),
                _StepPage(
                  children: [
                    Text(
                      AppData.createPostStep2Title,
                      style: AppTextStyles.primary
                          .copyWith(fontSize: context.sp(20)),
                    ),
                    SizedBox(height: context.hp(2)),
                    _HotelField(
                      hotel: state.selectedHotel,
                      enabled: !state.isLoading,
                      onTap: _pickHotel,
                    ),
                    SizedBox(height: context.hp(1.2)),
                    _FormField(
                      label: AppData.createPostTitleLabel,
                      hint: AppData.createPostTitleHint,
                      controller: _titleController,
                      enabled: !state.isLoading,
                      onChanged: (_) => setState(() {}),
                    ),
                    SizedBox(height: context.hp(1.2)),
                    _FormField(
                      label: AppData.createPostDescLabel,
                      hint: AppData.createPostDescHint,
                      controller: _descController,
                      enabled: !state.isLoading,
                      maxLines: 4,
                    ),
                    SizedBox(height: context.hp(3.5)),
                    AppGradientButton(
                      label: AppData.createPostNext,
                      onTap: canGoDetails ? () => _goToStep(2) : null,
                    ),
                    SizedBox(height: context.hp(3)),
                  ],
                ),
                _StepPage(
                  children: [
                    Text(
                      AppData.createPostStep3Title,
                      style: AppTextStyles.primary
                          .copyWith(fontSize: context.sp(20)),
                    ),
                    SizedBox(height: context.hp(2)),
                    _RatingSection(enabled: !state.isLoading),
                    SizedBox(height: context.hp(3.5)),
                    AppGradientButton(
                      label: state.isLoading
                          ? AppData.createPostPosting
                          : AppData.createPostBtn,
                      onTap: canPost ? _submit : null,
                    ),
                    SizedBox(height: context.hp(3)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Wizard step scaffolding ──────────────────────────────────────────────────

class _StepPage extends StatelessWidget {
  final List<Widget> children;
  const _StepPage({required this.children});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: context.wp(4),
        vertical: context.hp(1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  final int step;
  const _StepDots({required this.step});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final active = i == step;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          height: 8,
          width: active ? 22 : 8,
          decoration: BoxDecoration(
            color: active
                ? AppColors.primary
                : AppColors.grey.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ─── Media zone ───────────────────────────────────────────────────────────────

class _MediaZone extends StatelessWidget {
  final CreatePostState state;
  final VoidCallback onPickPhoto;
  final VoidCallback onPickVideo;

  const _MediaZone({
    required this.state,
    required this.onPickPhoto,
    required this.onPickVideo,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: context.hp(30),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: state.selectedFile == null
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
          color: state.selectedFile == null ? AppColors.tagBackground : null,
        ),
        child: state.selectedFile == null
            ? _EmptyMedia(onPickPhoto: onPickPhoto, onPickVideo: onPickVideo)
            : _FilledMedia(
                state: state,
                onChangeMedia: onPickPhoto,
              ),
      ),
    );
  }
}

class _EmptyMedia extends StatelessWidget {
  final VoidCallback onPickPhoto;
  final VoidCallback onPickVideo;

  const _EmptyMedia({
    required this.onPickPhoto,
    required this.onPickVideo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: onPickPhoto,
          child: Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.camera_alt_outlined,
              color: AppColors.dark,
              size: 28,
            ),
          ),
        ),
        SizedBox(height: context.hp(1.2)),
        Text(
          AppData.createPostMediaLabel,
          style: AppTextStyles.primary.copyWith(fontSize: context.sp(14)),
        ),
        SizedBox(height: context.hp(1.2)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _MediaChip(
              label: AppData.createPostPhotoBtn,
              filled: true,
              onTap: onPickPhoto,
            ),
            const SizedBox(width: 8),
            _MediaChip(
              label: AppData.createPostVideoBtn,
              filled: false,
              onTap: onPickVideo,
            ),
          ],
        ),
      ],
    );
  }
}

class _MediaChip extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _MediaChip({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: filled ? null : Border.all(color: AppColors.primary, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: context.sp(12),
            color: filled ? AppColors.accent : AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _FilledMedia extends StatelessWidget {
  final CreatePostState state;
  final VoidCallback onChangeMedia;

  const _FilledMedia({required this.state, required this.onChangeMedia});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (state.mediaType == 'image')
          Image.file(state.selectedFile!, fit: BoxFit.cover)
        else
          _VideoPreview(file: state.selectedFile!),
        if (state.isLoading)
          _UploadOverlay(stage: state.stage)
        else
          Positioned(
            bottom: 12,
            right: 12,
            child: GestureDetector(
              onTap: onChangeMedia,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  AppData.createPostChangeMedia,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _VideoPreview extends StatefulWidget {
  final File file;
  const _VideoPreview({required this.file});

  @override
  State<_VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<_VideoPreview> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initController(widget.file);
  }

  @override
  void didUpdateWidget(_VideoPreview old) {
    super.didUpdateWidget(old);
    if (old.file.path != widget.file.path) {
      _controller.dispose();
      _initialized = false;
      _initController(widget.file);
    }
  }

  void _initController(File file) {
    _controller = VideoPlayerController.file(file)
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

  void _toggle() {
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return Container(
        color: AppColors.dark,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.white),
        ),
      );
    }
    return GestureDetector(
      onTap: _toggle,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: _controller.value.size.width,
              height: _controller.value.size.height,
              child: VideoPlayer(_controller),
            ),
          ),
          if (!_controller.value.isPlaying)
            const Center(
              child: Icon(Icons.play_circle_fill_rounded,
                  color: Colors.white70, size: 56),
            ),
        ],
      ),
    );
  }
}

class _UploadOverlay extends StatelessWidget {
  final UploadStage stage;

  const _UploadOverlay({required this.stage});

  String get _label {
    switch (stage) {
      case UploadStage.gettingUrl:
        return AppData.createPostGettingUrl;
      case UploadStage.uploadingMedia:
        return AppData.createPostUploadingMedia;
      case UploadStage.creatingPost:
        return AppData.createPostPublishing;
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUploading = stage == UploadStage.gettingUrl ||
        stage == UploadStage.uploadingMedia;

    return Container(
      color: AppColors.primary.withValues(alpha: 0.78),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_upload_outlined, color: AppColors.white, size: 38),
          SizedBox(height: context.hp(1.2)),
          Text(
            _label,
            style: TextStyle(
              fontFamily: 'Inter',
              color: AppColors.white,
              fontWeight: FontWeight.w700,
              fontSize: context.sp(14),
            ),
          ),
          SizedBox(height: context.hp(2)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StageChip(
                label: AppData.createPostStageUploading,
                active: isUploading,
              ),
              const SizedBox(width: 8),
              _StageChip(
                label: AppData.createPostStagePublishing,
                active: stage == UploadStage.creatingPost,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StageChip extends StatelessWidget {
  final String label;
  final bool active;

  const _StageChip({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: active
            ? AppColors.accent.withValues(alpha: 0.2)
            : Colors.white24,
        borderRadius: BorderRadius.circular(20),
        border: active ? Border.all(color: AppColors.accent) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? AppColors.accent : Colors.white54,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              color: active ? AppColors.accent : Colors.white54,
              fontWeight: FontWeight.w700,
              fontSize: context.sp(11),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hotel field + picker ─────────────────────────────────────────────────────

class _HotelField extends StatelessWidget {
  final Hotel? hotel;
  final bool enabled;
  final VoidCallback onTap;

  const _HotelField({
    required this.hotel,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = hotel != null;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.white
              : AppColors.grey.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.grey.withValues(alpha: 0.3),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(
              selected ? Icons.storefront_rounded : Icons.storefront_outlined,
              color: selected ? AppColors.primary : AppColors.grey,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppData.createPostHotelLabel,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: selected ? AppColors.primary : AppColors.grey,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selected
                        ? '${hotel!.name} — ${hotel!.city}'
                        : AppData.createPostHotelPlaceholder,
                    style: AppTextStyles.secondary.copyWith(
                      fontSize: context.sp(13),
                      color: selected ? AppColors.dark : AppColors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.grey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _HotelPickerSheet extends StatefulWidget {
  const _HotelPickerSheet();

  @override
  State<_HotelPickerSheet> createState() => _HotelPickerSheetState();
}

class _HotelPickerSheetState extends State<_HotelPickerSheet> {
  final _searchController = TextEditingController();
  List<Hotel> _hotels = [];
  bool _loading = true;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final hotels = await PostService().getHotels();
      if (mounted) setState(() { _hotels = hotels; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<Hotel> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _hotels;
    return _hotels.where((h) {
      return h.name.toLowerCase().contains(q) ||
          h.address.toLowerCase().contains(q) ||
          h.city.toLowerCase().contains(q);
    }).toList();
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
        maxHeight: MediaQuery.of(context).size.height * 0.8,
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
            AppData.createPostHotelSheetTitle,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: context.sp(16),
              fontWeight: FontWeight.w600,
              color: AppColors.dark,
            ),
          ),
          SizedBox(height: context.hp(1.5)),
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _query = v),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: context.sp(14),
              color: AppColors.dark,
            ),
            decoration: InputDecoration(
              hintText: AppData.createPostHotelSearchHint,
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.grey),
              hintStyle: TextStyle(
                fontFamily: 'Inter',
                fontSize: context.sp(14),
                color: AppColors.grey,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: AppColors.grey.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: AppColors.grey.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          SizedBox(height: context.hp(1.5)),
          Flexible(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: context.hp(3)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Could not load hotels',
              style: AppTextStyles.secondary.copyWith(fontSize: context.sp(13)),
            ),
            SizedBox(height: context.hp(1.5)),
            GestureDetector(
              onTap: _load,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    final list = _filtered;
    if (list.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: context.hp(3)),
        child: Text(
          'No hotels found',
          style: AppTextStyles.secondary.copyWith(fontSize: context.sp(13)),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      itemCount: list.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color: AppColors.grey.withValues(alpha: 0.15),
      ),
      itemBuilder: (_, i) {
        final h = list[i];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            h.name,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: context.sp(14),
              fontWeight: FontWeight.w600,
              color: AppColors.dark,
            ),
          ),
          subtitle: Text(
            [h.address, h.city].where((s) => s.isNotEmpty).join(', '),
            style: AppTextStyles.secondary.copyWith(fontSize: context.sp(12)),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          onTap: () => Navigator.pop(context, h),
        );
      },
    );
  }
}

// ─── Rating section ───────────────────────────────────────────────────────────

class _RatingSection extends ConsumerStatefulWidget {
  final bool enabled;
  const _RatingSection({required this.enabled});

  @override
  ConsumerState<_RatingSection> createState() => _RatingSectionState();
}

class _RatingSectionState extends ConsumerState<_RatingSection> {
  final _controllers = {
    for (final c in ratingCategories) c: TextEditingController(),
  };

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createPostNotifierProvider);
    final notifier = ref.read(createPostNotifierProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppData.createPostRatingSectionLabel,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: context.hp(1)),
        for (final category in ratingCategories) ...[
          _RatingCategoryRow(
            label: AppData.createPostRatingLabels[category]!,
            score: state.scores[category] ?? 0,
            controller: _controllers[category]!,
            enabled: widget.enabled,
            onRate: (n) => notifier.setScore(category, n),
            onReview: (v) => notifier.setReview(category, v),
          ),
          SizedBox(height: context.hp(1.2)),
        ],
      ],
    );
  }
}

class _RatingCategoryRow extends StatelessWidget {
  final String label;
  final int score;
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<int> onRate;
  final ValueChanged<String> onReview;

  const _RatingCategoryRow({
    required this.label,
    required this.score,
    required this.controller,
    required this.enabled,
    required this.onRate,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? AppColors.white : AppColors.grey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: score > 0
              ? AppColors.primary
              : AppColors.grey.withValues(alpha: 0.4),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTextStyles.primary.copyWith(fontSize: context.sp(13)),
              ),
              Row(
                children: List.generate(5, (i) {
                  final n = i + 1;
                  final filled = n <= score;
                  return GestureDetector(
                    onTap: enabled ? () => onRate(n) : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Icon(
                        filled ? Icons.star_rounded : Icons.star_border_rounded,
                        size: context.sp(22),
                        color: filled ? AppColors.accent : AppColors.grey,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            enabled: enabled,
            maxLength: 100,
            onChanged: onReview,
            style: AppTextStyles.secondary.copyWith(
              fontSize: context.sp(13),
              color: AppColors.dark,
            ),
            decoration: InputDecoration(
              isDense: true,
              counterText: '',
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              hintText: AppData.createPostReviewHint,
              hintStyle: AppTextStyles.secondary.copyWith(
                fontSize: context.sp(12),
                color: AppColors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Form fields ──────────────────────────────────────────────────────────────

class _FormField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool enabled;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  const _FormField({
    required this.label,
    required this.hint,
    required this.controller,
    this.enabled = true,
    this.maxLines = 1,
    this.onChanged,
  });

  @override
  State<_FormField> createState() => _FormFieldState();
}

class _FormFieldState extends State<_FormField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filled = widget.controller.text.isNotEmpty;
    final activeColor = widget.enabled && filled ? AppColors.primary : AppColors.grey;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: widget.enabled ? AppColors.white : AppColors.grey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.enabled && filled
              ? AppColors.primary
              : AppColors.grey.withValues(alpha: 0.4),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: activeColor,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 5),
          TextField(
            controller: widget.controller,
            enabled: widget.enabled,
            maxLines: widget.maxLines,
            onChanged: widget.onChanged,
            style: AppTextStyles.secondary.copyWith(
              fontSize: context.sp(14),
              color: AppColors.dark,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              hintText: widget.hint,
              hintStyle: AppTextStyles.secondary.copyWith(
                fontSize: context.sp(13),
                color: AppColors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
