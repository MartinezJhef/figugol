import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/models/app_user.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
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

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthController>().user;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de oferta')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _OwnerHeader(offer: widget.offer, currentUser: currentUser),
                  const SizedBox(height: 24),
                  Text(
                    'Figuritas que ofrece',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.lightText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: widget.offer.stickersOffered.length,
                    itemBuilder: (context, index) {
                      final item = widget.offer.stickersOffered[index];
                      return _OfferedStickerTile(item: item);
                    },
                  ),
                  const SizedBox(height: 80), // Padding for FAB
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ProposeTradeScreen(
                offer: widget.offer,
              ),
            ),
          );
        },
        icon: const Icon(Icons.handshake_rounded),
        label: const Text('Proponer intercambio'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      backgroundColor: AppTheme.bgDark,
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
          backgroundColor: const Color(0xFFF3F4F6),
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
                ).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.lightText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                distance == null
                    ? '${offer.offeredQuantity} figuritas ofrecidas'
                    : '${offer.offeredQuantity} figuritas · ${distance.toStringAsFixed(1)} km aprox.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF9CA3AF),
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
  const _OfferedStickerTile({required this.item});

  final TradeOfferSticker item;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        image: DecorationImage(
          image: const AssetImage('assets/images/app_bg.png'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.6),
            BlendMode.darken,
          ),
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLine, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 14,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: item.sticker.imageUrl != null && item.sticker.imageUrl!.startsWith('http')
                    ? Image.network(
                        item.sticker.imageUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.broken_image, color: Colors.white24)),
                      )
                    : item.sticker.imageUrl != null
                        ? Image.asset(item.sticker.imageUrl!, fit: BoxFit.contain)
                        : const Center(
                            child: Icon(Icons.image_not_supported, color: Colors.white24),
                          ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBrand.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Cantidad: ${item.quantity}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        color: AppTheme.primaryBrand,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
