import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../auth/data/models/app_user.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../offers/data/models/trade_offer.dart';
import '../../../offers/data/repositories/trade_offers_repository.dart';
import '../../data/models/offer_qr_payload.dart';

class GenerateOfferQrScreen extends StatelessWidget {
  const GenerateOfferQrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthController, AppUser?>(
      (controller) => controller.user,
    );

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Inicia sesión para generar un QR.')),
      );
    }

    final repository = TradeOffersRepository();

    return Scaffold(
      appBar: AppBar(title: const Text('Generar QR')),
      body: SafeArea(
        child: StreamBuilder<List<TradeOffer>>(
          stream: repository.watchMyActiveOffers(user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final offers = snapshot.data ?? const <TradeOffer>[];
            if (offers.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No tienes ofertas activas para generar un QR.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: offers.length,
              separatorBuilder: (_, _) => const SizedBox(height: 18),
              itemBuilder: (context, index) {
                return _OfferQrCard(offer: offers[index]);
              },
            );
          },
        ),
      ),
    );
  }
}

class _OfferQrCard extends StatelessWidget {
  const _OfferQrCard({required this.offer});

  final TradeOffer offer;

  @override
  Widget build(BuildContext context) {
    final payload = OfferQrPayload(
      offerId: offer.id,
      ownerId: offer.ownerId,
      createdAt: DateTime.now(),
    ).encode();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD5DDD6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${offer.offeredQuantity} figuritas ofrecidas',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF10231B),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: QrImageView(
              data: payload,
              version: QrVersions.auto,
              size: 220,
              backgroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
