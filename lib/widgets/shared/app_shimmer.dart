import 'package:flutter/material.dart';

class AppShimmer extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius borderRadius;

  const AppShimmer({
    super.key,
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );
  late final Animation<double> _shimmer =
      Tween<double>(begin: -1.5, end: 2.5).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
  );

  @override
  void initState() {
    super.initState();
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          gradient: LinearGradient(
            begin: Alignment(_shimmer.value - 1, 0),
            end: Alignment(_shimmer.value + 1, 0),
            colors: const [
              Color(0xFFE4E4E4),
              Color(0xFFF5F5F5),
              Color(0xFFE4E4E4),
            ],
          ),
        ),
      ),
    );
  }
}
