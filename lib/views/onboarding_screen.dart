import 'package:flutter/material.dart';
import '../resources/app_theme.dart';
import '../resources/data.dart';
import '../utils/responsive.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Content — centred in the cream area above the vector
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: context.hp(38),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'lib/assets/idli-icon.png',
                  height: context.hp(18),
                ),
                SizedBox(height: context.hp(3)),
                Text(
                  AppData.onboardingTitle,
                  style: AppTextStyles.primary.copyWith(
                    fontSize: context.sp(28),
                  ),
                ),
                SizedBox(height: context.hp(1)),
                Text(
                  AppData.onboardingSubtitle,
                  style: AppTextStyles.secondary.copyWith(
                    fontSize: context.sp(16),
                  ),
                ),
              ],
            ),
          ),

          // Purple curved footer using Vector asset
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'lib/assets/Vector.png',
              width: double.infinity,
              height: context.hp(40),
              fit: BoxFit.fill,
            ),
          ),
        ],
      ),
    );
  }
}
