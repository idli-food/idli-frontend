import 'package:flutter/material.dart';
import '../../resources/app_theme.dart';
import '../../utils/responsive.dart';

class AppGradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool outlined;

  const AppGradientButton({
    super.key,
    required this.label,
    this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        height: context.hp(6.5),
        decoration: BoxDecoration(
          gradient: (!outlined && !disabled) ? AppColors.primaryGradient : null,
          color: outlined
              ? Colors.transparent
              : (disabled ? AppColors.grey.withValues(alpha: 0.35) : null),
          borderRadius: BorderRadius.circular(14),
          border: outlined
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.bold,
              fontSize: context.sp(16),
              color: outlined
                  ? AppColors.primary
                  : (disabled ? AppColors.greyDark : AppColors.accent),
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}
