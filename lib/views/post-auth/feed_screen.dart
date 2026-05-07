import 'package:flutter/material.dart';
import '../../resources/app_theme.dart';
import '../../utils/responsive.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('lib/assets/idli-icon.png', height: context.hp(12)),
            SizedBox(height: context.hp(3)),
            Text(
              'Welcome to Idli!',
              style: AppTextStyles.primary.copyWith(
                fontSize: context.sp(24),
              ),
            ),
            SizedBox(height: context.hp(1)),
            Text(
              'Feed coming soon',
              style: AppTextStyles.secondary.copyWith(
                fontSize: context.sp(15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
