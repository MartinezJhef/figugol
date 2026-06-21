import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../offers/presentation/pages/nearby_offers_screen.dart';

class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          // Top curved section
          Container(
            height: size.height * 0.55,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              image: const DecorationImage(
                image: AssetImage('assets/images/tiendita_bg.png'),
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.elliptical(size.width, 80),
              ),
            ),
          ),

          // Bottom section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 32.0,
                vertical: 24.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        'Reserva intercambios\npor la tiendita',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: AppTheme.lightText,
                          fontWeight: FontWeight.w900,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Visualiza los intercambio a los cuales puedes ser participe.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF9CA3AF),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),

                  // Dots indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF6B7280).withValues(alpha: 0.3),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF6B7280).withValues(alpha: 0.3),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 20,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: AppTheme.primaryBrand,
                        ),
                      ),
                    ],
                  ),

                  // Bottom Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryBrand,
                        foregroundColor: AppTheme.bgDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => NearbyOffersScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Buscar ofertas para reservar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
