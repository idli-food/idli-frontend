import 'package:flutter/material.dart';
import '../../resources/app_theme.dart';
import '../../utils/responsive.dart';

class SplashProgressBar extends StatelessWidget {
  const SplashProgressBar({super.key, required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return SizedBox(
          width: context.wp(46),
          height: context.hp(0.65),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(color: Colors.white.withValues(alpha: 0.25)),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: animation.value,
                    child: Container(color: AppColors.accent),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
