import 'package:flutter/material.dart';
import '../../resources/app_theme.dart';
import '../../resources/data.dart';
import '../../services/auth_service.dart';
import '../../utils/responsive.dart';
import '../../widgets/shared/app_gradient_button.dart';
import '../post-auth/main_shell_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _service = AuthService();
  bool _obscure = true;
  bool _isLoading = false;
  String? _identifierError;
  String? _passwordError;

  @override
  void dispose() {
    _identifierCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final identifier = _identifierCtrl.text.trim();
    final password = _passwordCtrl.text;

    setState(() {
      _identifierError = identifier.isEmpty ? AppData.loginErrorIdentifierEmpty : null;
      _passwordError = password.isEmpty ? AppData.loginErrorPasswordEmpty : null;
    });

    if (_identifierError != null || _passwordError != null) return;

    setState(() => _isLoading = true);
    try {
      await _service.login(identifier, password);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainShellScreen()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.wp(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: context.hp(1)),
            Text(
              AppData.loginTitle,
              style: AppTextStyles.primary.copyWith(
                fontSize: context.sp(30),
                height: 1.2,
              ),
            ),
            SizedBox(height: context.hp(1)),
            Text(
              AppData.loginSubtitle,
              style: AppTextStyles.secondary.copyWith(fontSize: context.sp(15)),
            ),
            SizedBox(height: context.hp(5)),
            _buildTextField(
              context,
              controller: _identifierCtrl,
              label: AppData.loginIdentifierLabel,
              hint: AppData.loginIdentifierHint,
              errorText: _identifierError,
              keyboardType: TextInputType.emailAddress,
              onChanged: (_) {
                if (_identifierError != null) setState(() => _identifierError = null);
              },
            ),
            SizedBox(height: context.hp(2)),
            _buildPasswordField(context),
            const Spacer(),
            AppGradientButton(
              label: _isLoading ? 'Signing in…' : AppData.loginBtn,
              onTap: _isLoading ? null : _submit,
            ),
            SizedBox(height: context.hp(2) + MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required String hint,
    String? errorText,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) {
    final hasError = errorText != null;
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
            controller: controller,
            keyboardType: keyboardType,
            enabled: !_isLoading,
            onChanged: onChanged,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: context.sp(16),
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                fontFamily: 'Inter',
                color: AppColors.greyDark,
                fontSize: context.sp(13),
              ),
              hintText: hint,
              hintStyle: TextStyle(
                fontFamily: 'Inter',
                color: AppColors.grey,
                fontSize: context.sp(14),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: context.wp(4),
                vertical: context.hp(1.9),
              ),
            ),
          ),
        ),
        if (hasError) ...[
          SizedBox(height: context.hp(0.6)),
          Padding(
            padding: EdgeInsets.only(left: context.wp(2)),
            child: Text(
              errorText,
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

  Widget _buildPasswordField(BuildContext context) {
    final hasError = _passwordError != null;
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
            controller: _passwordCtrl,
            obscureText: _obscure,
            enabled: !_isLoading,
            onChanged: (_) {
              if (_passwordError != null) setState(() => _passwordError = null);
            },
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: context.sp(16),
              color: Colors.black87,
              letterSpacing: 1.2,
            ),
            decoration: InputDecoration(
              labelText: AppData.loginPasswordLabel,
              labelStyle: TextStyle(
                fontFamily: 'Inter',
                color: AppColors.greyDark,
                fontSize: context.sp(13),
              ),
              hintText: AppData.loginPasswordHint,
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
              _passwordError!,
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
