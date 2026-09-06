import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../../models/hotel.dart';
import '../../providers/create_post_provider.dart';
import '../../providers/location_provider.dart';
import '../../widgets/shared/app_gradient_button.dart';
import 'create_screen.dart';

/// Instant-post preview shown right after a video is recorded in the camera.
/// Loops the clip, overlays the auto-tagged hotel, and offers Retake / Done.
/// Done publishes immediately as an `instant`-type post.
///
/// If the location could not be fetched automatically or no nearby hotel was
/// found, this screen prompts the user for the place and opens the hotel picker.
class InstantPreviewScreen extends ConsumerStatefulWidget {
  final String description;

  const InstantPreviewScreen({super.key, required this.description});

  @override
  ConsumerState<InstantPreviewScreen> createState() =>
      _InstantPreviewScreenState();
}

class _InstantPreviewScreenState extends ConsumerState<InstantPreviewScreen> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _resolvingPlace = false;
  bool _needsPlace = false;

  @override
  void initState() {
    super.initState();
    final file = ref.read(createPostNotifierProvider).selectedFile;
    if (file != null) {
      _controller = VideoPlayerController.file(file)
        ..setLooping(true)
        ..setVolume(0)
        ..initialize().then((_) {
          if (mounted) {
            setState(() => _initialized = true);
            _controller?.play();
          }
        });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ensurePlace();
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  /// Best-effort fallback for when the camera screen's eager auto-tag didn't
  /// land a hotel: fetch location if we don't have it, retry the nearest-hotel
  /// lookup, and if there's still no hotel prompt the user to pick one.
  Future<void> _ensurePlace() async {
    if (ref.read(createPostNotifierProvider).selectedHotel != null) return;
    setState(() => _resolvingPlace = true);

    if (ref.read(locationNotifierProvider).selected == null) {
      await ref.read(locationNotifierProvider.notifier).fetchCurrent();
    }
    final loc = ref.read(locationNotifierProvider).selected;
    if (loc != null) {
      await ref
          .read(createPostNotifierProvider.notifier)
          .attemptAutoTagHotel(loc.latitude, loc.longitude);
    }

    if (!mounted) return;
    final stillNoHotel =
        ref.read(createPostNotifierProvider).selectedHotel == null;
    setState(() {
      _resolvingPlace = false;
      _needsPlace = stillNoHotel;
    });
    if (stillNoHotel) _openHotelPicker();
  }

  Future<void> _openHotelPicker() async {
    final hotel = await showModalBottomSheet<Hotel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const HotelPickerSheet(),
    );
    if (hotel != null && mounted) {
      ref.read(createPostNotifierProvider.notifier).setHotel(hotel);
      setState(() => _needsPlace = false);
    }
  }

  void _retake() {
    ref.read(createPostNotifierProvider.notifier).clearMedia();
    Navigator.of(context).pop();
  }

  void _done() {
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
    ref.read(createPostNotifierProvider.notifier).submit(
          description: widget.description,
          postType: 'instant',
        );
  }

  @override
  Widget build(BuildContext context) {
    // The camera screen's listener handles feed invalidation, state reset and
    // the "Posted!" snackbar. Here we only need to leave the preview.
    ref.listen(createPostNotifierProvider, (_, next) {
      if (next.stage == UploadStage.done && mounted) {
        Navigator.of(context).pop(true);
      }
    });

    final state = ref.watch(createPostNotifierProvider);
    final hotel = state.selectedHotel;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0D),
      body: Stack(
        fit: StackFit.expand,
        children: [
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
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          if (hotel != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 0,
              right: 0,
              child: Center(child: _HotelChip(name: hotel.name)),
            )
          else if (_resolvingPlace)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 0,
              right: 0,
              child: const Center(child: _FindingPlacePill()),
            )
          else if (_needsPlace)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 16,
              child: _PlacePromptBanner(onTap: _openHotelPicker),
            ),
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 24,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: state.isLoading ? null : _retake,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white70),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Retake'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppGradientButton(
                    label: state.isLoading ? 'Posting…' : 'Done',
                    onTap: state.isLoading ? null : _done,
                  ),
                ),
              ],
            ),
          ),
          if (state.isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.55),
              alignment: Alignment.center,
              child: const CircularProgressIndicator(color: Colors.white),
            ),
        ],
      ),
    );
  }
}

class _FindingPlacePill extends StatelessWidget {
  const _FindingPlacePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text(
            'Finding where you are…',
            style: TextStyle(
              fontFamily: 'Inter',
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlacePromptBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _PlacePromptBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        ),
        child: const Row(
          children: [
            Icon(Icons.location_on_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Where are you having this wonderful meal? Tap to tell us the place.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.white, size: 20),
          ],
        ),
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
