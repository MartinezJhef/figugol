import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/models/app_user.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/models/trade_offer.dart';
import '../../data/repositories/trade_offers_repository.dart';
import 'offer_detail_screen.dart';

class NearbyOffersScreen extends StatelessWidget {
  NearbyOffersScreen({super.key});

  final TradeOffersRepository _repository = TradeOffersRepository();

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthController, AppUser?>(
      (controller) => controller.user,
    );

    if (user == null || user.location == null) {
      return const Scaffold(
        body: _NearbyEmptyState(
          icon: Icons.location_off_rounded,
          title: 'Confirma tu ubicación para continuar',
          message: 'Necesitamos tu zona para mostrar intercambios cercanos.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Ofertas en Huancayo - 100 km')),
      body: SafeArea(
        child: StreamBuilder<List<TradeOffer>>(
          stream: _repository.watchNearbyActiveOffers(user: user),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const _NearbyEmptyState(
                icon: Icons.error_outline_rounded,
                title: 'No pudimos cargar las ofertas',
                message: 'Revisa tu conexión e inténtalo nuevamente.',
              );
            }

            final offers = snapshot.data ?? const <TradeOffer>[];
            if (offers.isEmpty) {
              return const _NearbyEmptyState(
                icon: Icons.travel_explore_rounded,
                title: 'No hay ofertas en tu radio',
                message:
                    'Mostramos intercambios de Huancayo hasta 100 km de tu ubicacion.',
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: offers.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final offer = offers[index];
                final distanceKm = _repository.distanceKm(
                  fromLatitude: user.location!.latitude,
                  fromLongitude: user.location!.longitude,
                  offer: offer,
                );
                return _NearbyOfferCard(
                  offer: offer,
                  distanceKm: distanceKm,
                  onViewOffer: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => OfferDetailScreen(offer: offer),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _NearbyEmptyState extends StatelessWidget {
  const _NearbyEmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTheme.grassGreen, size: 58),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF5D6F66),
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NearbyOfferCard extends StatelessWidget {
  const _NearbyOfferCard({
    required this.offer,
    required this.distanceKm,
    required this.onViewOffer,
  });

  final TradeOffer offer;
  final double distanceKm;
  final VoidCallback onViewOffer;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFEAF4E2),
                  backgroundImage: offer.ownerPhotoUrl == null
                      ? null
                      : NetworkImage(offer.ownerPhotoUrl!),
                  child: offer.ownerPhotoUrl == null
                      ? const Icon(Icons.person_rounded)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    offer.ownerName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _OfferMeta(
              icon: Icons.style_rounded,
              text: '${offer.offeredQuantity} figuritas ofrecidas',
            ),
            const SizedBox(height: 6),
            _OfferMeta(
              icon: Icons.near_me_rounded,
              text: '${distanceKm.toStringAsFixed(1)} km aprox.',
            ),
            const SizedBox(height: 6),
            _OfferMeta(
              icon: Icons.place_rounded,
              text: offer.exchangePoints.map((point) => point.name).join(', '),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: onViewOffer,
                icon: const Icon(Icons.visibility_rounded),
                label: const Text('Ver oferta'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfferMeta extends StatelessWidget {
  const _OfferMeta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.grassGreen),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF5D6F66),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
