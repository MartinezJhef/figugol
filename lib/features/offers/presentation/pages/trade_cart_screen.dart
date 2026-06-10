import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../controllers/trade_cart_controller.dart';
import 'publish_offer_screen.dart';

class TradeCartScreen extends StatelessWidget {
  const TradeCartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<TradeCartController>();

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
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                      itemCount: cart.items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = cart.items[index];
                        return _CartItemTile(
                          item: item,
                          onRemoveOne: () => cart.removeOne(item.sticker.id),
                          onRemoveAll: () =>
                              cart.removeSticker(item.sticker.id),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: FilledButton.icon(
                      onPressed: () {
                        cart.validateForPublish();
                        if (!cart.canPublish) {
                          return;
                        }
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const PublishOfferScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.campaign_rounded),
                      label: const Text('Continuar publicación'),
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
              color: AppTheme.primaryRed,
              size: 58,
            ),
            const SizedBox(height: 14),
            Text(
              'Selecciona mínimo 6 figuritas',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.darkText,
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

    return Card(
      color: isReady ? const Color(0xFFF3F4F6) : const Color(0xFFEFF6FF),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(
              isReady ? Icons.check_circle_rounded : Icons.info_rounded,
              color: isReady ? AppTheme.primaryRed : const Color(0xFFD97706),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isReady
                    ? 'Tienes $totalItems figuritas listas para ofrecer.'
                    : 'Debes seleccionar mínimo 6 figuritas para publicar una oferta. Faltan $missingItems.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.darkText,
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

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({
    required this.item,
    required this.onRemoveOne,
    required this.onRemoveAll,
  });

  final TradeCartItem item;
  final VoidCallback onRemoveOne;
  final VoidCallback onRemoveAll;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.accentBlue,
          foregroundColor: AppTheme.darkText,
          child: Text(item.sticker.catalogCode),
        ),
        title: Text(item.sticker.name),
        subtitle: Text('${item.sticker.team} · Ofreces ${item.quantity}'),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              tooltip: 'Restar una',
              onPressed: onRemoveOne,
              icon: const Icon(Icons.remove_circle_outline_rounded),
            ),
            IconButton(
              tooltip: 'Quitar figurita',
              onPressed: onRemoveAll,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
