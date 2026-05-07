import 'package:flutter/material.dart';
import '../../resources/app_theme.dart';
import '../../resources/data.dart';
import '../../utils/responsive.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border_rounded,
                size: context.sp(64), color: AppColors.grey),
            SizedBox(height: context.hp(2)),
            Text(
              AppData.homeSavedPlaceholder,
              style: AppTextStyles.primary.copyWith(fontSize: context.sp(24)),
            ),
            SizedBox(height: context.hp(1)),
            Text(
              AppData.homeSavedSub,
              style:
                  AppTextStyles.secondary.copyWith(fontSize: context.sp(14)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
