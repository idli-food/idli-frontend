import 'package:flutter/material.dart';
import '../../resources/app_theme.dart';
import '../../resources/data.dart';
import '../../utils/responsive.dart';
import '../../utils/splash_animation.dart';
import '../../widgets/splash/splash_progress_bar.dart';
import '../pre-auth/welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final SplashAnimation _anim;

  @override
  void initState() {
    super.initState();
    _anim = SplashAnimation(vsync: this, onComplete: _goToOnboarding);
    _anim.init();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _goToOnboarding() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // LayoutBuilder gives the real body height (excludes status bar + nav bar),
      // so nothing gets clipped behind the system navigation.
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bH = constraints.maxHeight;
          final navInset = MediaQuery.of(context).padding.bottom;

          // Body splits 50/50: idli logo centred in the top half, Vector.png
          // (mascot + curve + purple) fills the bottom half. The mascot is
          // baked into the asset; the curve dips to ~30% of the image height
          // at centre, where solid purple begins.
          const vectorFraction = 0.50;
          const arcDipFraction = 0.30;

          final vectorH = bH * vectorFraction;
          final vectorTop = bH - vectorH;               // rim level in body coords
          final arcDipY = vectorTop + vectorH * arcDipFraction; // solid purple starts here
          final logoH = bH * 0.18;

          return Stack(
            children: [
              // Vector.png — concave bowl curve with mascot baked in
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Image.asset(
                  'lib/assets/Vector.png',
                  width: double.infinity,
                  height: vectorH,
                  fit: BoxFit.fill,
                ),
              ),

              // Idli logo — centred in the top half of the body
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: vectorTop,
                child: Center(
                  child: Image.asset(
                    'lib/assets/idli-icon.png',
                    height: logoH,
                  ),
                ),
              ),

              // Text + progress bar — kept above the system navigation bar
              Positioned(
                top: arcDipY,
                left: 0,
                right: 0,
                bottom: navInset,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppData.splashTagline,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                        fontSize: context.sp(19),
                        color: AppColors.accent,
                      ),
                    ),
                    SizedBox(height: bH * 0.008),
                    Text(
                      AppData.splashSubtitle,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.normal,
                        fontSize: context.sp(13),
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: bH * 0.024),
                    SplashProgressBar(animation: _anim.progress),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
