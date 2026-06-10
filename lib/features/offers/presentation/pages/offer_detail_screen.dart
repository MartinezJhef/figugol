import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/models/app_user.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../marketplace/presentation/pages/marketplace_checkout_screen.dart';
import '../../../qr_exchange/presentation/pages/scan_offer_qr_screen.dart';
import '../../data/models/trade_offer.dart';
import '../../data/repositories/trade_offers_repository.dart';
import 'propose_trade_screen.dart';

class OfferDetailScreen extends StatefulWidget {
  const OfferDetailScreen({required this.offer, super.key});

  final TradeOffer offer;

  @override
  State<OfferDetailScreen> createState() => _OfferDetailScreenState();
}

class _OfferDetailScreenState extends State<OfferDetailScreen> {
  final _repository = TradeOffersRepository();
  late Future<OfferCompatibility> _compatibilityFuture;

  @override
  void initState() {
    super.initState();
    final userId = context.read<AuthController>().user?.uid;
    _compatibilityFuture = userId == null
        ? Future.value(
            const OfferCompatibility(
              missingFromOffer: [],
              possibleToOffer: [],
              myDuplicates: [],
              hasEnoughDataForFullCompatibility: false,
            ),
          )
        : _repository.loadOfferCompatibility(
            userId: userId,
            offer: widget.offer,
          );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthController>().user;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de oferta')),
      body: SafeArea(
        child: FutureBuilder<OfferCompatibility>(
          future: _compatibilityFuture,
          builder: (context, snapshot) {
            final compatibility = snapshot.data;
            final missingIds =
                compatibility?.missingFromOffer
                    .map((item) => item.sticker.id)
                    .toSet() ??
                const <String>{};

            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _OwnerHeader(offer: widget.offer, currentUser: currentUser),
                const SizedBox(height: 24),
                Text(
                  'Figuritas que ofrece',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                ...widget.offer.stickersOffered.map(
                  (item) => _OfferedStickerTile(
                    item: item,
                    isMissingForMe: missingIds.contains(item.sticker.id),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Figuritas que podrías ofrecer',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  if (compatibility?.hasEnoughDataForFullCompatibility == false)
                    const _InfoBox(
                      message:
                          'No hay suficientes datos para calcular compatibilidad completa.',
                    ),
                  if (compatibility?.possibleToOffer.isEmpty ?? true)
                    const _InfoBox(
                      message:
                          'No encontramos duplicadas tuyas que coincidan con lo que busca esta oferta.',
                    )
                  else
                    ...compatibility!.possibleToOffer.map(
                      (sticker) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(child: Text(sticker.catalogCode)),
                        title: Text(sticker.name),
                        subtitle: Text(sticker.team),
                      ),
                    ),
                ],
                const SizedBox(height: 26),
                FilledButton.icon(
                  onPressed: compatibility == null
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ProposeTradeScreen(
                                offer: widget.offer,
                                compatibility: compatibility,
                              ),
                            ),
                          );
                        },
                  icon: const Icon(Icons.handshake_rounded),
                  label: const Text('Proponer intercambio'),
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: widget.offer.offeredQuantity < 6
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => MarketplaceCheckoutScreen(
                                offer: widget.offer,
                              ),
                            ),
                          );
                        },
                  icon: const Icon(Icons.storefront_rounded),
                  label: const Text('Tramitar por tiendita'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ScanOfferQrScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Text('Escanear QR para intercambio presencial'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OwnerHeader extends StatelessWidget {
  const _OwnerHeader({required this.offer, required this.currentUser});

  final TradeOffer offer;
  final AppUser? currentUser;

  @override
  Widget build(BuildContext context) {
    final distance = currentUser?.location == null
        ? null
        : TradeOffersRepository().distanceKm(
            fromLatitude: currentUser!.location!.latitude,
            fromLongitude: currentUser!.location!.longitude,
            offer: offer,
          );

    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundImage: offer.ownerPhotoUrl == null
              ? null
              : NetworkImage(offer.ownerPhotoUrl!),
          child: offer.ownerPhotoUrl == null
              ? const Icon(Icons.person_rounded)
              : null,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                offer.ownerName,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                distance == null
                    ? '${offer.offeredQuantity} figuritas ofrecidas'
                    : '${offer.offeredQuantity} figuritas · ${distance.toStringAsFixed(1)} km aprox.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OfferedStickerTile extends StatelessWidget {
  const _OfferedStickerTile({required this.item, required this.isMissingForMe});

  final TradeOfferSticker item;
  final bool isMissingForMe;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(child: Text(item.sticker.catalogCode)),
      title: Text(item.sticker.name),
      subtitle: Text(item.sticker.team),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('x${item.quantity}'),
          if (isMissingForMe)
            Text(
              'Me falta',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: const Color(0xFFD22630),
                fontWeight: FontWeight.w900,
              ),
            ),
        ],
      ),
      tileColor: isMissingForMe ? const Color(0xFFF3F4F6) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isMissingForMe ? AppTheme.primaryRed : AppTheme.borderLine,
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF111827),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
