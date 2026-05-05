import 'package:flutter/animation.dart';

class SplashAnimation {
  SplashAnimation({
    required TickerProvider vsync,
    required VoidCallback onComplete,
  })  : _vsync = vsync,
        _onComplete = onComplete;

  final TickerProvider _vsync;
  final VoidCallback _onComplete;

  late final AnimationController controller;
  late final Animation<double> progress;

  void init() {
    controller = AnimationController(
      vsync: _vsync,
      duration: const Duration(milliseconds: 2500),
    );
    progress = CurvedAnimation(parent: controller, curve: Curves.easeInOut);
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) _onComplete();
    });
    controller.forward();
  }

  void dispose() => controller.dispose();
}
