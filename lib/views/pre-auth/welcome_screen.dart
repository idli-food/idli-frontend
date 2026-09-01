import 'package:flutter/material.dart';
import '../../resources/app_theme.dart';
import '../../resources/data.dart';
import '../../utils/responsive.dart';
import '../../utils/auth_mode.dart';
import '../../widgets/shared/app_gradient_button.dart';
import 'login_screen.dart';
import 'phone_number_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bH = constraints.maxHeight;
          final waveH = bH * 0.38;

          return Stack(
            children: [
              // Purple mascot wave at bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Image.asset(
                  'lib/assets/Vector.png',
                  width: double.infinity,
                  height: waveH,
                  fit: BoxFit.fill,
                ),
              ),

              // Logo + tagline centred in cream area
              Positioned(
                top: 0,
                left: context.wp(8),
                right: context.wp(8),
                bottom: waveH + context.hp(18),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'lib/assets/idli-icon.png',
                      height: context.hp(16),
                    ),
                    SizedBox(height: context.hp(2)),
                    Text(
                      AppData.welcomeTagline,
                      style: AppTextStyles.secondary.copyWith(
                        fontSize: context.sp(17),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // CTA buttons just above wave
              Positioned(
                bottom: waveH + context.hp(5),
                left: context.wp(8),
                right: context.wp(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppGradientButton(
                      label: AppData.welcomeRegister,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PhoneNumberScreen(mode: AuthMode.register),
                        ),
                      ),
                    ),
                    SizedBox(height: context.hp(1.5)),
                    AppGradientButton(
                      label: AppData.welcomeLogin,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      ),
                      outlined: true,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
