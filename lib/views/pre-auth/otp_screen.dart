import 'dart:async';
import 'package:flutter/material.dart';
import '../../resources/app_theme.dart';
import '../../resources/data.dart';
import '../../utils/responsive.dart';
import '../../utils/auth_mode.dart';
import '../../widgets/shared/app_gradient_button.dart';
import '../../widgets/shared/app_otp_field.dart';
import 'complete_profile_screen.dart';
import '../post-auth/main_shell_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  final AuthMode mode;

  const OtpScreen({super.key, required this.phone, required this.mode});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  String _otp = '';
  int _secondsLeft = 60;
  Timer? _timer;
  final _otpKey = GlobalKey<AppOtpFieldState>();

  String get _maskedPhone {
    if (widget.phone.length < 6) return widget.phone;
    final digits = widget.phone.replaceAll('+91', '');
    return '+91 ${digits.substring(0, 5)} XXXXX';
  }

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_secondsLeft == 0) {
        t.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _resend() {
    _otpKey.currentState?.clear();
    setState(() => _otp = '');
    _startTimer();
  }

  void _verify() {
    if (_otp.length != 6) return;
    if (widget.mode == AuthMode.register) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CompleteProfileScreen()),
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainShellScreen()),
        (_) => false,
      );
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
              AppData.otpTitle,
              style: AppTextStyles.primary.copyWith(
                fontSize: context.sp(30),
                height: 1.2,
              ),
            ),
            SizedBox(height: context.hp(1)),
            RichText(
              text: TextSpan(
                style: AppTextStyles.secondary
                    .copyWith(fontSize: context.sp(15)),
                children: [
                  const TextSpan(text: 'Sent to '),
                  TextSpan(
                    text: _maskedPhone,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: context.hp(5)),
            AppOtpField(
              key: _otpKey,
              onChanged: (v) => setState(() => _otp = v),
            ),
            SizedBox(height: context.hp(3)),
            Center(
              child: _secondsLeft > 0
                  ? RichText(
                      text: TextSpan(
                        style: AppTextStyles.secondary
                            .copyWith(fontSize: context.sp(14)),
                        children: [
                          TextSpan(text: AppData.otpResendIn),
                          TextSpan(
                            text: '${_secondsLeft}s',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  : GestureDetector(
                      onTap: _resend,
                      child: Text(
                        AppData.otpResend,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: context.sp(14),
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.primary,
                        ),
                      ),
                    ),
            ),
            const Spacer(),
            AppGradientButton(
              label: AppData.otpVerify,
              onTap: _otp.length == 6 ? _verify : null,
            ),
            SizedBox(height: context.hp(2) + MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}
