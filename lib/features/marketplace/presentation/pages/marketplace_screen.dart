import 'package:flutter/material.dart';

import '../../../offers/presentation/pages/nearby_offers_screen.dart';

class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tiendita')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.storefront_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 48,
              ),
              const SizedBox(height: 18),
              Text(
                'Reserva intercambios por la tiendita',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF10231B),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'El pago es simulado y solo sirve para ensayar el flujo visual de comisión.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF5D6F66),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => NearbyOffersScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.travel_explore_rounded),
                label: const Text('Buscar ofertas para reservar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
