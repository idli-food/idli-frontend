import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/create_post_provider.dart';
import '../../resources/app_theme.dart';
import '../../resources/data.dart';
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

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia({required bool isPhoto}) async {
    final XFile? picked = isPhoto
        ? await _picker.pickImage(source: ImageSource.gallery)
        : await _picker.pickVideo(source: ImageSource.gallery);
    if (picked == null || !mounted) return;
    ref
        .read(createPostNotifierProvider.notifier)
        .setMedia(File(picked.path), isPhoto ? 'image' : 'video');
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
        Navigator.of(context).pop();
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
        _titleController.text.trim().isNotEmpty &&
        !state.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.dark),
          onPressed: state.isLoading ? null : () => Navigator.of(context).pop(),
        ),
        title: Text(
          AppData.createPostTitle,
          style: AppTextStyles.primary.copyWith(fontSize: context.sp(18)),
        ),
        actions: [
          TextButton(
            onPressed: canPost ? _submit : null,
            child: Text(
              AppData.createPostBtn,
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                fontSize: context.sp(15),
                color: canPost ? AppColors.primary : AppColors.grey,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: context.wp(4),
          vertical: context.hp(1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MediaZone(
              state: state,
              onPickPhoto: () => _pickMedia(isPhoto: true),
              onPickVideo: () => _pickMedia(isPhoto: false),
            ),
            SizedBox(height: context.hp(1.8)),
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
            SizedBox(height: context.hp(1.2)),
            const _LocationField(),
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
      ),
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
          Container(
            color: AppColors.dark,
            child: const Center(
              child: Icon(Icons.videocam_rounded, color: AppColors.white, size: 52),
            ),
          ),
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

class _LocationField extends StatelessWidget {
  const _LocationField();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.grey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.grey.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined, color: AppColors.grey, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppData.createPostLocationLabel,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppData.createPostLocationPlaceholder,
                  style: AppTextStyles.secondary.copyWith(
                    fontSize: context.sp(13),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.tagBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              AppData.createPostLocationBadge,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
