import 'package:flutter/material.dart';
import '../../resources/app_theme.dart';
import '../../resources/data.dart';
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
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final phone = _controller.text.replaceAll(' ', '').trim();
    if (phone.isEmpty) {
      setState(() => _error = AppData.phoneErrorEmpty);
      return;
    }
    if (phone.length != 10 || !RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      setState(() => _error = AppData.phoneErrorInvalid);
      return;
    }
    setState(() => _error = null);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtpScreen(
          phone: '+91$phone',
          mode: widget.mode,
        ),
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
          icon:
              Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary),
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
              label: AppData.phoneSendOtp,
              onTap: _submit,
            ),
            SizedBox(height: context.hp(2) + MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}
