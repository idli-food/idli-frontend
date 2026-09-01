import 'package:flutter/material.dart';
import '../../resources/app_theme.dart';
import '../../resources/data.dart';
import '../../services/auth_service.dart';
import '../../utils/responsive.dart';
import '../../utils/auth_mode.dart';
import '../../widgets/shared/app_gradient_button.dart';
import '../../widgets/shared/app_phone_field.dart';
import 'otp_screen.dart';

class PhoneNumberScreen extends StatefulWidget {
  final AuthMode mode;

  const PhoneNumberScreen({super.key, required this.mode});

  @override
  State<PhoneNumberScreen> createState() => _PhoneNumberScreenState();
}

class _PhoneNumberScreenState extends State<PhoneNumberScreen> {
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
    final phone = _controller.text.replaceAll(' ', '').trim();
    if (phone.isEmpty) {
      setState(() => _error = AppData.phoneErrorEmpty);
      return;
    }
    if (phone.length != 10 || !RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      setState(() => _error = AppData.phoneErrorInvalid);
      return;
    }
    setState(() {
      _error = null;
      _isLoading = true;
    });

    final fullPhone = '+91$phone';
    try {
      final requestId = await _service.getOtp(fullPhone);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpScreen(
            phone: fullPhone,
            mode: widget.mode,
            requestId: requestId,
          ),
        ),
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
              AppData.phoneTitle,
              style: AppTextStyles.primary.copyWith(
                fontSize: context.sp(30),
                height: 1.2,
              ),
            ),
            SizedBox(height: context.hp(1)),
            Text(
              AppData.phoneSubtitle,
              style: AppTextStyles.secondary.copyWith(
                fontSize: context.sp(15),
              ),
            ),
            SizedBox(height: context.hp(5)),
            AppPhoneField(
              controller: _controller,
              errorText: _error,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
            const Spacer(),
            AppGradientButton(
              label: _isLoading ? 'Sending…' : AppData.phoneSendOtp,
              onTap: _isLoading ? null : _submit,
            ),
            SizedBox(height: context.hp(2) + MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}
