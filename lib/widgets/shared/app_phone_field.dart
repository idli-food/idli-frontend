import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../resources/app_theme.dart';
import '../../utils/responsive.dart';

class _PhoneSpaceFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length > 10) return oldValue;
    final formatted = digits.length <= 5
        ? digits
        : '${digits.substring(0, 5)} ${digits.substring(5)}';
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class AppPhoneField extends StatelessWidget {
  final TextEditingController controller;
  final String? errorText;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;

  const AppPhoneField({
    super.key,
    required this.controller,
    this.errorText,
    this.focusNode,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasError ? Colors.red.shade400 : const Color(0xFFE0E0E0),
              width: hasError ? 2 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.wp(4),
                  vertical: context.hp(1.9),
                ),
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🇮🇳', style: TextStyle(fontSize: context.sp(20))),
                    SizedBox(width: context.wp(2)),
                    Text(
                      '+91',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                        fontSize: context.sp(16),
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onChanged: onChanged,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [_PhoneSpaceFormatter()],
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: context.sp(18),
                    color: Colors.black87,
                    letterSpacing: 1.5,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: context.wp(4),
                      vertical: context.hp(1.9),
                    ),
                    hintText: '98765 43210',
                    hintStyle: TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.grey,
                      fontSize: context.sp(16),
                      letterSpacing: 2,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (hasError) ...[
          SizedBox(height: context.hp(0.6)),
          Padding(
            padding: EdgeInsets.only(left: context.wp(2)),
            child: Text(
              errorText!,
              style: TextStyle(
                fontFamily: 'Inter',
                color: Colors.red.shade400,
                fontSize: context.sp(12),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
