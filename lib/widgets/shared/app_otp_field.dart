import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../resources/app_theme.dart';
import '../../utils/responsive.dart';

class AppOtpField extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final VoidCallback? onCompleted;

  const AppOtpField({
    super.key,
    required this.onChanged,
    this.onCompleted,
  });

  @override
  State<AppOtpField> createState() => AppOtpFieldState();
}

class AppOtpFieldState extends State<AppOtpField> {
  static const _length = 6;
  final _controllers = List.generate(_length, (_) => TextEditingController());
  final _focusNodes = List.generate(_length, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    for (final node in _focusNodes) {
      node.addListener(() {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get otp => _controllers.map((c) => c.text).join();

  void clear() {
    for (final c in _controllers) {
      c.clear();
    }
    if (mounted) {
      setState(() {});
      _focusNodes.first.requestFocus();
    }
    widget.onChanged('');
  }

  void _onChanged(int i, String value) {
    if (value.length == 1 && i < _length - 1) {
      _focusNodes[i + 1].requestFocus();
    }
    setState(() {});
    final current = otp;
    widget.onChanged(current);
    if (current.length == _length) {
      _focusNodes[i].unfocus();
      widget.onCompleted?.call();
    }
  }

  void _onKey(int i, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[i].text.isEmpty &&
        i > 0) {
      _controllers[i - 1].clear();
      _focusNodes[i - 1].requestFocus();
      setState(() {});
      widget.onChanged(otp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(_length, (i) => _buildBox(context, i)),
    );
  }

  Widget _buildBox(BuildContext context, int i) {
    final isFocused = _focusNodes[i].hasFocus;
    final isFilled = _controllers[i].text.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: context.wp(13),
      height: context.wp(14),
      decoration: BoxDecoration(
        color: isFilled
            ? AppColors.primary.withValues(alpha: 0.07)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isFocused || isFilled
              ? AppColors.primary
              : const Color(0xFFE0E0E0),
          width: isFocused ? 2.5 : (isFilled ? 2.0 : 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(
              alpha: isFocused ? 0.20 : (isFilled ? 0.10 : 0.04),
            ),
            blurRadius: isFocused ? 12 : 6,
            spreadRadius: isFocused ? 1 : 0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: KeyboardListener(
        focusNode: FocusNode(skipTraversal: true),
        onKeyEvent: (e) => _onKey(i, e),
        child: TextField(
          controller: _controllers[i],
          focusNode: _focusNodes[i],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          textAlignVertical: TextAlignVertical.center,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyle(
            fontSize: context.sp(22),
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            fontFamily: 'Inter',
          ),
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (v) => _onChanged(i, v),
        ),
      ),
    );
  }
}
