import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../resources/app_theme.dart';
import '../../resources/data.dart';
import '../../services/auth_service.dart';
import '../../utils/responsive.dart';
import '../../widgets/shared/app_gradient_button.dart';
import '../../widgets/shared/app_phone_field.dart';
import '../post-auth/main_shell_screen.dart';

class GoogleCompleteProfileScreen extends StatefulWidget {
  final String registrationToken;
  final String? name;
  final String? email;
  final String? picture;

  const GoogleCompleteProfileScreen({
    super.key,
    required this.registrationToken,
    this.name,
    this.email,
    this.picture,
  });

  @override
  State<GoogleCompleteProfileScreen> createState() => _GoogleCompleteProfileScreenState();
}

class _GoogleCompleteProfileScreenState extends State<GoogleCompleteProfileScreen> {
  final _usernameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _service = AuthService();
  String? _usernameError;
  String? _phoneError;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = _usernameCtrl.text.trim();
    final phone = _phoneCtrl.text.replaceAll(' ', '').trim();

    setState(() {
      _usernameError = username.isEmpty ? AppData.googleCompleteUsernameErrorEmpty : null;
      _phoneError = phone.isEmpty
          ? AppData.googleCompletePhoneErrorEmpty
          : (phone.length != 10 || !RegExp(r'^[6-9]\d{9}$').hasMatch(phone))
              ? AppData.googleCompletePhoneErrorInvalid
              : null;
    });

    if (_usernameError != null || _phoneError != null) return;

    setState(() => _isLoading = true);
    try {
      await _service.completeGoogleSignup(widget.registrationToken, username, '+91$phone');
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
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.wp(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: context.hp(1)),
            Text(
              AppData.googleCompleteTitle,
              style: AppTextStyles.primary.copyWith(fontSize: context.sp(30), height: 1.2),
            ),
            SizedBox(height: context.hp(1)),
            Text(
              AppData.googleCompleteSubtitle,
              style: AppTextStyles.secondary.copyWith(fontSize: context.sp(15)),
            ),
            SizedBox(height: context.hp(5)),
            _buildUsernameField(context),
            SizedBox(height: context.hp(2)),
            AppPhoneField(
              controller: _phoneCtrl,
              errorText: _phoneError,
              onChanged: (_) {
                if (_phoneError != null) setState(() => _phoneError = null);
              },
            ),
            const Spacer(),
            AppGradientButton(
              label: _isLoading ? 'Finishing…' : AppData.googleCompleteBtn,
              onTap: _isLoading ? null : _submit,
            ),
            SizedBox(height: context.hp(2) + MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildUsernameField(BuildContext context) {
    final hasError = _usernameError != null;
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
            controller: _usernameCtrl,
            enabled: !_isLoading,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
              LengthLimitingTextInputFormatter(20),
            ],
            onChanged: (_) {
              if (_usernameError != null) setState(() => _usernameError = null);
            },
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: context.sp(16),
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              labelText: AppData.googleCompleteUsernameLabel,
              labelStyle: TextStyle(
                fontFamily: 'Inter',
                color: AppColors.greyDark,
                fontSize: context.sp(13),
              ),
              hintText: AppData.googleCompleteUsernameHint,
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
              _usernameError!,
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
