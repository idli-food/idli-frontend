import 'package:flutter/material.dart';
import '../../resources/app_theme.dart';
import '../../resources/data.dart';
import '../../utils/responsive.dart';
import '../../widgets/shared/app_gradient_button.dart';
import 'username_screen.dart';

class PasswordScreen extends StatefulWidget {
  final String phone;

  const PasswordScreen({super.key, required this.phone});

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final _controller = TextEditingController();
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final password = _controller.text;
    if (password.isEmpty) {
      setState(() => _error = AppData.passwordErrorEmpty);
      return;
    }
    if (password.length < 8) {
      setState(() => _error = AppData.passwordErrorShort);
      return;
    }
    setState(() => _error = null);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UsernameScreen(phone: widget.phone, password: password),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.wp(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: context.hp(1)),
            Text(
              AppData.passwordTitle,
              style: AppTextStyles.primary.copyWith(
                fontSize: context.sp(30),
                height: 1.2,
              ),
            ),
            SizedBox(height: context.hp(1)),
            Text(
              AppData.passwordSubtitle,
              style: AppTextStyles.secondary.copyWith(fontSize: context.sp(15)),
            ),
            SizedBox(height: context.hp(5)),
            _buildPasswordField(context),
            const Spacer(),
            AppGradientButton(
              label: AppData.passwordContinue,
              onTap: _submit,
            ),
            SizedBox(height: context.hp(2) + MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField(BuildContext context) {
    final hasError = _error != null;
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
          child: TextField(
            controller: _controller,
            obscureText: _obscure,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: context.sp(16),
              color: Colors.black87,
              letterSpacing: 1.2,
            ),
            decoration: InputDecoration(
              labelText: AppData.passwordLabel,
              labelStyle: TextStyle(
                fontFamily: 'Inter',
                color: AppColors.greyDark,
                fontSize: context.sp(13),
              ),
              hintText: AppData.passwordHint,
              hintStyle: TextStyle(
                fontFamily: 'Inter',
                color: AppColors.grey,
                fontSize: context.sp(14),
                letterSpacing: 0,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: context.wp(4),
                vertical: context.hp(1.9),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: AppColors.grey,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
        ),
        if (hasError) ...[
          SizedBox(height: context.hp(0.6)),
          Padding(
            padding: EdgeInsets.only(left: context.wp(2)),
            child: Text(
              _error!,
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
