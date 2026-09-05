import 'package:flutter/material.dart';
import '../../resources/app_theme.dart';
import '../../utils/responsive.dart';

class GoogleSignInButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const GoogleSignInButton({super.key, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: context.hp(6.5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'G',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w900,
                fontSize: context.sp(18),
                color: const Color(0xFF4285F4),
              ),
            ),
            SizedBox(width: context.wp(3)),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
                fontSize: context.sp(16),
                color: AppColors.dark,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
