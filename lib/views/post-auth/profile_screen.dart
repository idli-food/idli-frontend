import 'package:flutter/material.dart';
import '../../resources/app_theme.dart';
import '../../resources/data.dart';
import '../../utils/responsive.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_outline_rounded,
                size: context.sp(64), color: AppColors.grey),
            SizedBox(height: context.hp(2)),
            Text(
              AppData.homeProfilePlaceholder,
              style: AppTextStyles.primary.copyWith(fontSize: context.sp(24)),
            ),
            SizedBox(height: context.hp(1)),
            Text(
              AppData.homeProfileSub,
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
