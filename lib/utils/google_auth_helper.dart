import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/auth_service.dart';
import '../views/pre-auth/google_complete_profile_screen.dart';
import '../views/post-auth/main_shell_screen.dart';

Future<void> handleGoogleSignIn(BuildContext context, AuthService service) async {
  try {
    final googleSignIn = GoogleSignIn(
      serverClientId: dotenv.env['GOOGLE_SERVER_CLIENT_ID'],
    );
    final account = await googleSignIn.signIn();
    if (account == null) return;

    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null) throw Exception('Could not get Google ID token');

    final data = await service.loginWithGoogle(idToken);
    if (!context.mounted) return;

    if (data['is_new_user'] == true) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GoogleCompleteProfileScreen(
            registrationToken: data['registration_token'] as String,
            name: data['name'] as String?,
            email: data['email'] as String?,
            picture: data['picture'] as String?,
          ),
        ),
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainShellScreen()),
        (_) => false,
      );
    }
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 5),
      ),
    );
  }
}
