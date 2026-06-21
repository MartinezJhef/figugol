import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../profile/presentation/pages/complete_profile_screen.dart';
import '../../../profile/presentation/pages/main_navigation_screen.dart';
import '../controllers/auth_controller.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.select<AuthController, AuthFlowStatus>(
      (controller) => controller.status,
    );

    return switch (status) {
      AuthFlowStatus.checking => const _LoadingSessionScreen(),
      AuthFlowStatus.signedOut => const LoginScreen(),
      AuthFlowStatus.profileIncomplete => const CompleteProfileScreen(),
      AuthFlowStatus.signedIn => const MainNavigationScreen(),
    };
  }
}

class _LoadingSessionScreen extends StatelessWidget {
  const _LoadingSessionScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image(
              image: AssetImage('assets/images/app_bg.png'),
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: SizedBox.square(
              dimension: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
