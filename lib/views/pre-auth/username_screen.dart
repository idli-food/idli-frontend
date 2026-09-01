import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../resources/app_theme.dart';
import '../../resources/data.dart';
import '../../services/auth_service.dart';
import '../../utils/responsive.dart';
import '../../widgets/shared/app_gradient_button.dart';
import '../post-auth/main_shell_screen.dart';

class UsernameScreen extends StatefulWidget {
  final String phone;
  final String password;

  const UsernameScreen({super.key, required this.phone, required this.password});

  @override
  State<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends State<UsernameScreen> {
  final _controller = TextEditingController();
  final _service = AuthService();
  String? _error;
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = _controller.text.trim();
    if (username.isEmpty) {
      setState(() => _error = AppData.usernameErrorEmpty);
      return;
    }
    if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9_]{2,19}$').hasMatch(username)) {
      setState(() => _error = AppData.usernameErrorFormat);
      return;
    }
    setState(() {
      _error = null;
      _isLoading = true;
    });

    try {
      await _service.createUser(widget.phone, username, widget.password);
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
              AppData.usernameTitle,
              style: AppTextStyles.primary.copyWith(
                fontSize: context.sp(30),
                height: 1.2,
              ),
            ),
            SizedBox(height: context.hp(1)),
            Text(
              AppData.usernameSubtitle,
              style: AppTextStyles.secondary.copyWith(fontSize: context.sp(15)),
            ),
            SizedBox(height: context.hp(5)),
            _buildUsernameField(context),
            const Spacer(),
            AppGradientButton(
              label: AppData.usernameFinish,
              onTap: _isLoading ? null : _submit,
            ),
            SizedBox(height: context.hp(2) + MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildUsernameField(BuildContext context) {
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
            enabled: !_isLoading,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
              LengthLimitingTextInputFormatter(20),
            ],
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: context.sp(16),
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              labelText: AppData.usernameLabel,
              labelStyle: TextStyle(
                fontFamily: 'Inter',
                color: AppColors.greyDark,
                fontSize: context.sp(13),
              ),
              hintText: AppData.usernameHint,
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
              prefixIcon: Padding(
                padding: EdgeInsets.only(left: context.wp(4), right: context.wp(1)),
                child: Text(
                  '@',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: context.sp(16),
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
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
