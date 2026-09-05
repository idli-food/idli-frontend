import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/hotel.dart';
import '../../providers/create_post_provider.dart';
import '../../providers/feed_provider.dart';
import '../../providers/location_provider.dart';
import '../../resources/app_theme.dart';
import '../../resources/data.dart';
import '../../utils/media_utils.dart';
import '../../utils/responsive.dart';
import '../../widgets/shared/app_gradient_button.dart';
import 'create_screen.dart';
import 'instant_preview_screen.dart';

enum _CaptureMode { photo, instant, video }

const _cameraBackground = Color(0xFF0A0A0D);
const _maxInstantDuration = Duration(seconds: 60);
const _minInstantDuration = Duration(seconds: 3);

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _initializing = true;
  String? _initError;
  _CaptureMode _mode = _CaptureMode.instant;
  bool _isRecordingInstant = false;
  Duration _recordElapsed = Duration.zero;
  Timer? _recordTimer;
  bool _autoTagged = false;
  bool _autoTagInFlight = false;
  final _instantDescController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Keep the location provider alive for this screen's lifetime so an
    // in-flight fetchCurrent() isn't torn down by autoDispose before the
    // auto-tag reads the result.
    ref.listenManual(locationNotifierProvider, (_, __) {});
    _initCamera();
    debugPrint('[CameraScreen] initState mode=$_mode');
    if (_mode == _CaptureMode.instant) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _attemptAutoTagHotel();
      });
    }
  }

  Future<void> _attemptAutoTagHotel() async {
    if (_autoTagged || _autoTagInFlight) return;
    if (ref.read(createPostNotifierProvider).selectedHotel != null) return;
    _autoTagInFlight = true;
    debugPrint('[CameraScreen] auto-tag: fetching current location');
    try {
      await ref.read(locationNotifierProvider.notifier).fetchCurrent();
      final loc = ref.read(locationNotifierProvider).selected;
      debugPrint('[CameraScreen] auto-tag: location = $loc');
      if (loc != null) {
        await ref.read(createPostNotifierProvider.notifier)
            .attemptAutoTagHotel(loc.latitude, loc.longitude);
      }
      _autoTagged =
          ref.read(createPostNotifierProvider).selectedHotel != null;
    } finally {
      _autoTagInFlight = false;
    }
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _controller?.dispose();
    _instantDescController.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw Exception('No camera available on this device');
      }
      final camera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );
      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: true,
      );
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _controller = controller;
        _initializing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initError = e.toString();
        _initializing = false;
      });
    }
  }

  Future<void> _openWizardWithPick(MediaPick pick) async {
    if (!mounted) return;
    final posted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CreateScreen(initialPick: pick)),
    );
    if (posted == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _startInstantRecording() async {
    final controller = _controller;
    if (_initializing || controller == null || !controller.value.isInitialized) {
      return;
    }
    if (_isRecordingInstant) return;

    final state = ref.read(createPostNotifierProvider);
    if (state.selectedHotel == null || !state.ratingsValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Tag a hotel before posting, and rate all 4 categories if you add a rating.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      await controller.startVideoRecording();
    } catch (_) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _isRecordingInstant = true;
      _recordElapsed = Duration.zero;
    });
    _recordTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted) return;
      setState(() {
        _recordElapsed += const Duration(milliseconds: 50);
      });
      if (_recordElapsed >= _maxInstantDuration) {
        _stopInstantRecording(keep: true);
      }
    });
  }

  Future<void> _stopInstantRecording({required bool keep}) async {
    if (!_isRecordingInstant) return;
    _isRecordingInstant = false;
    _recordTimer?.cancel();
    _recordTimer = null;
    final elapsed = _recordElapsed;

    XFile? file;
    try {
      file = await _controller?.stopVideoRecording();
    } catch (_) {
      file = null;
    }
    if (!mounted) return;
    setState(() {});

    final longEnough = keep && elapsed >= _minInstantDuration;
    if (file == null || !longEnough) {
      if (file != null) {
        try {
          File(file.path).deleteSync();
        } catch (_) {}
      }
      if (keep && !longEnough) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hold to record — 3s to 60s.')),
        );
      }
      return;
    }

    ref.read(createPostNotifierProvider.notifier).setMedia(
          File(file.path),
          'video',
          contentTypeFromPath(file.path),
        );
    final posted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => InstantPreviewScreen(
          description: _instantDescController.text.trim(),
        ),
      ),
    );
    if (posted == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _openHotelOverlay() async {
    final hotel = await showModalBottomSheet<Hotel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const HotelPickerSheet(),
    );
    if (hotel != null) {
      ref.read(createPostNotifierProvider.notifier).setHotel(hotel);
    }
  }

  Future<void> _openTextOverlay() async {
    final controller = TextEditingController(text: _instantDescController.text);
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppData.createPostDescLabel,
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                fontSize: context.sp(14),
                color: AppColors.dark,
              ),
            ),
            SizedBox(height: context.hp(1.2)),
            TextField(
              controller: controller,
              maxLines: 4,
              autofocus: true,
              style: TextStyle(fontFamily: 'Inter', fontSize: context.sp(14)),
              decoration: InputDecoration(
                hintText: AppData.createPostDescHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: context.hp(2)),
            AppGradientButton(
              label: 'Done',
              onTap: () => Navigator.pop(ctx, controller.text),
            ),
          ],
        ),
      ),
    );
    if (result != null) {
      _instantDescController.text = result;
    }
  }

  Future<void> _openRatingOverlay() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _InstantRatingSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(createPostNotifierProvider, (_, next) {
      if (next.stage == UploadStage.done) {
        ref.invalidate(feedProvider);
        ref.read(createPostNotifierProvider.notifier).reset();
        _instantDescController.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Posted!')),
          );
        }
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

    return Scaffold(
      backgroundColor: _cameraBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _CameraPreviewArea(
            initializing: _initializing,
            errorText: _initError,
            controller: _controller,
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),
          if (_mode == _CaptureMode.instant)
            Positioned(
              top: context.hp(240 / 844 * 100),
              right: context.wp(20 / 390 * 100),
              child: _InstantToolsPill(
                onRating: _openRatingOverlay,
                onText: _openTextOverlay,
                onTagHotel: _openHotelOverlay,
              ),
            ),
          if (_mode == _CaptureMode.instant && state.selectedHotel != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 60,
              right: 60,
              child: Center(
                child: _HotelChip(name: state.selectedHotel!.name),
              ),
            ),
          if (state.isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.55),
              alignment: Alignment.center,
              child: const CircularProgressIndicator(color: Colors.white),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomControlBar(
              mode: _mode,
              isRecordingInstant: _isRecordingInstant,
              recordProgress: _recordElapsed.inMilliseconds /
                  _maxInstantDuration.inMilliseconds,
              onModeSelected: (m) {
                if (_isRecordingInstant) return;
                switch (m) {
                  case _CaptureMode.photo:
                    _openWizardWithPick(MediaPick.photo);
                    return;
                  case _CaptureMode.video:
                    _openWizardWithPick(MediaPick.video);
                    return;
                  case _CaptureMode.instant:
                    setState(() => _mode = m);
                    _attemptAutoTagHotel();
                }
              },
              onRecordStart: _startInstantRecording,
              onRecordStop: () => _stopInstantRecording(keep: true),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Camera preview ─────────────────────────────────────────────────────────

class _CameraPreviewArea extends StatelessWidget {
  final bool initializing;
  final String? errorText;
  final CameraController? controller;

  const _CameraPreviewArea({
    required this.initializing,
    required this.errorText,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    if (initializing) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    if (errorText != null || controller == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            errorText ?? 'Camera unavailable',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontFamily: 'Inter'),
          ),
        ),
      );
    }
    final previewSize = controller!.value.previewSize;
    if (previewSize == null) return const SizedBox.shrink();
    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: previewSize.height,
            height: previewSize.width,
            child: CameraPreview(controller!),
          ),
        ),
      ),
    );
  }
}

// ─── Instant mode floating tools pill ───────────────────────────────────────

class _InstantToolsPill extends StatelessWidget {
  final VoidCallback onRating;
  final VoidCallback onText;
  final VoidCallback onTagHotel;

  const _InstantToolsPill({
    required this.onRating,
    required this.onText,
    required this.onTagHotel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _InstantIconButton(
            icon: Icons.star_rounded,
            label: 'Rating',
            onTap: onRating,
          ),
          const SizedBox(height: 16),
          _InstantIconButton(
            textIcon: 'Aa',
            label: 'Text',
            onTap: onText,
          ),
          const SizedBox(height: 16),
          _InstantIconButton(
            icon: Icons.storefront_rounded,
            label: 'Tag Hotel',
            onTap: onTagHotel,
          ),
        ],
      ),
    );
  }
}

class _InstantIconButton extends StatelessWidget {
  final IconData? icon;
  final String? textIcon;
  final String label;
  final VoidCallback onTap;

  const _InstantIconButton({
    this.icon,
    this.textIcon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: icon != null
                  ? Icon(icon, color: AppColors.primary, size: 20)
                  : Text(
                      textIcon!,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.primary,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom control bar ──────────────────────────────────────────────────────

class _BottomControlBar extends StatelessWidget {
  final _CaptureMode mode;
  final bool isRecordingInstant;
  final double recordProgress;
  final ValueChanged<_CaptureMode> onModeSelected;
  final VoidCallback onRecordStart;
  final VoidCallback onRecordStop;

  const _BottomControlBar({
    required this.mode,
    required this.isRecordingInstant,
    required this.recordProgress,
    required this.onModeSelected,
    required this.onRecordStart,
    required this.onRecordStop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: context.hp(170 / 844 * 100),
      padding: EdgeInsets.only(bottom: context.hp(2)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ModeTab(
                label: 'Photo',
                selected: mode == _CaptureMode.photo,
                onTap: () => onModeSelected(_CaptureMode.photo),
              ),
              const SizedBox(width: 24),
              _ModeTab(
                label: 'Instant',
                selected: mode == _CaptureMode.instant,
                onTap: () => onModeSelected(_CaptureMode.instant),
              ),
              const SizedBox(width: 24),
              _ModeTab(
                label: 'Video',
                selected: mode == _CaptureMode.video,
                onTap: () => onModeSelected(_CaptureMode.video),
              ),
            ],
          ),
          SizedBox(height: context.hp(2.2)),
          GestureDetector(
            onTapDown: (_) => onRecordStart(),
            onTapUp: (_) => onRecordStop(),
            onTapCancel: onRecordStop,
            child: SizedBox(
              width: 78,
              height: 78,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (isRecordingInstant)
                    SizedBox(
                      width: 78,
                      height: 78,
                      child: CircularProgressIndicator(
                        value: recordProgress.clamp(0.0, 1.0),
                        strokeWidth: 4,
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  Container(
                    width: isRecordingInstant ? 58 : 78,
                    height: isRecordingInstant ? 58 : 78,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                      border: isRecordingInstant
                          ? null
                          : Border.all(color: Colors.white, width: 4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HotelChip extends StatelessWidget {
  final String name;

  const _HotelChip({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          color: selected
              ? Colors.white
              : Colors.white.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}

// ─── Instant mode rating overlay ─────────────────────────────────────────────

class _InstantRatingSheet extends ConsumerStatefulWidget {
  const _InstantRatingSheet();

  @override
  ConsumerState<_InstantRatingSheet> createState() =>
      _InstantRatingSheetState();
}

class _InstantRatingSheetState extends ConsumerState<_InstantRatingSheet> {
  final _controllers = {
    for (final c in ratingCategories) c: TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    final reviews = ref.read(createPostNotifierProvider).reviews;
    for (final c in ratingCategories) {
      _controllers[c]!.text = reviews[c] ?? '';
    }
  }

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
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppData.createPostRatingSectionLabel,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppColors.dark,
              ),
            ),
            SizedBox(height: context.hp(1.5)),
            for (final category in ratingCategories) ...[
              RatingCategoryRow(
                label: AppData.createPostRatingLabels[category]!,
                score: state.scores[category] ?? 0,
                controller: _controllers[category]!,
                enabled: true,
                onRate: (n) => notifier.setScore(category, n),
                onReview: (v) => notifier.setReview(category, v),
              ),
              SizedBox(height: context.hp(1.2)),
            ],
            SizedBox(height: context.hp(1)),
            AppGradientButton(
              label: 'Done',
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
