import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/figugol_action_button.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF9FAFB), Color(0xFFF3F4F6)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                const Spacer(),
                _FootballBadge(color: colorScheme.primary),
                const SizedBox(height: 28),
                Text(
                  AppConstants.appName,
                  textAlign: TextAlign.center,
                  style: textTheme.displaySmall?.copyWith(
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  AppConstants.appSlogan,
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF4B5563),
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 36),
                FigugolActionButton(
                  label: 'Ingresar con Google',
                  icon: Icons.login_rounded,
                  onPressed: () {},
                ),
                const SizedBox(height: 12),
                FigugolActionButton(
                  label: 'Explorar demo',
                  icon: Icons.explore_rounded,
                  style: FigugolActionButtonStyle.secondary,
                  onPressed: () {},
                ),
                const Spacer(),
                Text(
                  'Colecciona, encuentra e intercambia de forma simple.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FootballBadge extends StatelessWidget {
  const _FootballBadge({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      height: 132,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.24),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
          ),
          const Icon(
            Icons.sports_soccer_rounded,
            color: Colors.white,
            size: 70,
          ),
          Positioned(
            bottom: 18,
            child: Container(
              width: 68,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFF0A369D),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
