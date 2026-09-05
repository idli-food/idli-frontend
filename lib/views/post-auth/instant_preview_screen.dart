import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../../providers/create_post_provider.dart';
import '../../widgets/shared/app_gradient_button.dart';

/// Instant-post preview shown right after a video is recorded in the camera.
/// Loops the clip, overlays the auto-tagged hotel, and offers Retake / Done.
/// Done publishes immediately as an `instant`-type post.
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
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
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
