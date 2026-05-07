import 'package:flutter/material.dart';
import '../../resources/app_theme.dart';
import '../../resources/data.dart';
import '../../utils/responsive.dart';

class CreateScreen extends StatelessWidget {
  const CreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.dark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          AppData.homeCreatePlaceholder,
          style: AppTextStyles.primary.copyWith(fontSize: context.sp(18)),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_a_photo_outlined,
                  size: 36, color: AppColors.dark),
            ),
            SizedBox(height: context.hp(2)),
            Text(
              AppData.homeCreatePlaceholder,
              style: AppTextStyles.primary.copyWith(fontSize: context.sp(22)),
            ),
            SizedBox(height: context.hp(1)),
            Text(
              AppData.homeCreateSub,
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
