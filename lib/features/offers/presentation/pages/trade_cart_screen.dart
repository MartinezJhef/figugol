import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../stickers/presentation/controllers/stickers_controller.dart';
import '../controllers/trade_cart_controller.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/repositories/trade_offers_repository.dart';
import 'publish_offer_screen.dart';

class TradeCartScreen extends StatefulWidget {
  const TradeCartScreen({super.key});

  @override
  State<TradeCartScreen> createState() => _TradeCartScreenState();
}

class _TradeCartScreenState extends State<TradeCartScreen> {
  bool _isPublishing = false;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<TradeCartController>();
    final stickersController = context.watch<StickersController>();
    final user = context.watch<AuthController>().user;

    _showValidationIfNeeded(context, cart);

    return Scaffold(
      appBar: AppBar(title: const Text('Carrito de intercambio')),
      body: SafeArea(
        child: cart.items.isEmpty
            ? const _CartEmptyState()
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    child: _CartSummary(totalItems: cart.totalItems),
                  ),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.72,
                      ),
                      itemCount: cart.items.length,
                      itemBuilder: (context, index) {
                        final item = cart.items[index];
                        final ownedQuantity = stickersController.quantityFor(item.sticker.id);
                        final stock = ownedQuantity;
                        return _CartItemGridTile(
                          item: item,
                          stock: stock,
                          onAddOne: () => cart.addSticker(sticker: item.sticker, ownedQuantity: ownedQuantity),
                          onRemoveOne: () => cart.removeOne(item.sticker.id),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: FilledButton.icon(
                      onPressed: _isPublishing
                          ? null
                          : () async {
                              cart.validateForPublish();
                              if (!cart.canPublish) {
                                return;
                              }
                              
                              if (user == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Debes iniciar sesión.')),
                                );
                                return;
                              }
                              
                              if (!user.hasCompletedProfile || !user.locationConfirmed || user.location == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Completa tu perfil y ubicación antes de publicar.')),
                                );
                                return;
                              }

                              setState(() {
                                _isPublishing = true;
                              });

                              try {
                                final repository = TradeOffersRepository();
                                final points = await repository.loadUserExchangePoints(user.uid);
                                
                                if (points.isEmpty) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Necesitas configurar al menos 1 punto de intercambio en tu perfil.')),
                                  );
                                  setState(() {
                                    _isPublishing = false;
                                  });
                                  return;
                                }

                                await repository.publishOffer(
                                  user: user,
                                  cartItems: cart.items,
                                  exchangePoints: points,
                                );

                                if (!context.mounted) return;
                                final currentStickersController = context.read<StickersController>();
                                for (final item in cart.items) {
                                  await currentStickersController.decreaseQuantityBy(item.sticker.id, item.quantity);
                                }

                                cart.clear();

                                if (!context.mounted) return;
                                Navigator.of(context).pop();
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Intercambio publicado exitosamente.'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } catch (e) {
                                if (!context.mounted) return;
                                final message = e is TradeOfferException ? e.message : 'Ocurrió un error al publicar.';
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(message)),
                                );
                                setState(() {
                                  _isPublishing = false;
                                });
                              }
                            },
                      icon: _isPublishing 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.campaign_rounded),
                      label: Text(_isPublishing ? 'Publicando...' : 'Publicar El intercambio'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _showValidationIfNeeded(BuildContext context, TradeCartController cart) {
    final message = cart.validationMessage;
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
      cart.clearValidationMessage();
    });
  }
}

class _CartEmptyState extends StatelessWidget {
  const _CartEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.shopping_basket_outlined,
              color: AppTheme.primaryBrand,
              size: 58,
            ),
            const SizedBox(height: 14),
            Text(
              'Selecciona mínimo 6 figuritas',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.lightText,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega repetidas desde “Mis figuritas” para preparar tu intercambio.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF6B7280),
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

class _CartSummary extends StatelessWidget {
  const _CartSummary({required this.totalItems});

  final int totalItems;

  @override
  Widget build(BuildContext context) {
    final missingItems = TradeCartController.minimumItemsToPublish - totalItems;
    final isReady = totalItems >= TradeCartController.minimumItemsToPublish;

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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isReady ? AppTheme.primaryBrand : const Color(0xFFD97706),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 14,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(
              isReady ? Icons.check_circle_rounded : Icons.info_rounded,
              color: isReady ? AppTheme.primaryBrand : const Color(0xFFD97706),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isReady
                    ? 'Tienes $totalItems figuritas listas para ofrecer.'
                    : 'Debes seleccionar mínimo 6 figuritas para publicar una oferta. Faltan $missingItems.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightText,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartItemGridTile extends StatelessWidget {
  const _CartItemGridTile({
    required this.item,
    required this.stock,
    required this.onAddOne,
    required this.onRemoveOne,
  });

  final TradeCartItem item;
  final int stock;
  final VoidCallback onAddOne;
  final VoidCallback onRemoveOne;

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
        child: Stack(
          children: [
            Column(
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Stock: $stock',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: AppTheme.lightText,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: onRemoveOne,
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4B5563),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.remove,
                                size: 16,
                                color: AppTheme.lightText,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppTheme.lightText,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: onAddOne,
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBrand,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.add,
                                size: 16,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
