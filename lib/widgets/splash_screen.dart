import 'package:flutter/material.dart';
import 'package:siwes360/auth/login.dart';
import 'package:siwes360/screens/student/firstLoginSetup.dart';
import 'package:siwes360/theme/tokens.dart';
import 'package:siwes360/utils/request.dart';
import 'package:siwes360/utils/role_router.dart';
import 'package:siwes360/widgets/logo.dart';

/// Checks the saved session, then opens the right home screen or login.
/// Same paper background and mark as the login screen, so the hand-off is seamless.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    // Long enough to read the mark, short enough not to be in the way.
    final minimum = Future<void>.delayed(const Duration(milliseconds: 700));
    Widget next = const Login();
    try {
      await RequestService.loadAuthToken();
      final userData = await RequestService.loadUserData();
      final token = RequestService.authToken;
      if (token != null && token.isNotEmpty && userData != null && userData['role'] != null) {
        final profile = await RequestService.getProfile();
        if (profile != null && profile['status'] == 'success') {
          final roleData = userData['role_data'];
          final firstLogin = userData['role'] == 'student' &&
              roleData is Map &&
              (roleData['is_first_login'] == true || roleData['is_first_login'] == 1);
          next = firstLogin
              ? FirstLoginSetup(userData: Map<String, dynamic>.from(userData))
              : RoleRouter.getHomeScreen('${userData['role']}');
        } else {
          await RequestService.clearUserData();
        }
      }
    } catch (_) {
      await RequestService.clearUserData();
    }
    await minimum;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, _, _) => next,
        transitionsBuilder: (context, animation, _, child) => FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SiwesLogo(markSize: 72, tagline: 'The SIWES logbook'),
            const SizedBox(height: Space.xxl),
            const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          ],
        ),
      ),
    );
  }
}
