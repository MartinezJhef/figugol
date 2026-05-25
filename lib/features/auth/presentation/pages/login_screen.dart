import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/figugol_action_button.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AuthController>();
    final textTheme = Theme.of(context).textTheme;

    _showErrorIfNeeded(context, controller);

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A3D2D), Color(0xFFF3F8F1)],
            stops: [0, 0.72],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                const SizedBox(height: 28),
                const _FootballBadge(),
                const Spacer(),
                Text(
                  AppConstants.appName,
                  textAlign: TextAlign.center,
                  style: textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  AppConstants.appSlogan,
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(
                    color: const Color(0xFFEAF4E2),
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const Spacer(),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 22,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Entrá a tu álbum futbolero',
                        textAlign: TextAlign.center,
                        style: textTheme.titleMedium?.copyWith(
                          color: AppTheme.ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 14),
                      FigugolActionButton(
                        label: controller.isLoading
                            ? 'Ingresando...'
                            : 'Ingresar con Google',
                        icon: controller.isLoading
                            ? Icons.hourglass_top_rounded
                            : Icons.login_rounded,
                        onPressed: controller.isLoading
                            ? null
                            : controller.signInWithGoogle,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Colecciona, encuentra e intercambia figuritas de forma simple.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF375347),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showErrorIfNeeded(BuildContext context, AuthController controller) {
    final message = controller.errorMessage;
    if (message == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      controller.clearError();
    });
  }
}

class _FootballBadge extends StatelessWidget {
  const _FootballBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 128,
      height: 128,
      decoration: BoxDecoration(
        color: AppTheme.grassGreen,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.gold, width: 5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: const Icon(
        Icons.sports_soccer_rounded,
        color: Colors.white,
        size: 72,
      ),
    );
  }
}
