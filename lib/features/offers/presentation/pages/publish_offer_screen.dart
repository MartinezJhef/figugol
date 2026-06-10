import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/data/models/app_user.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../location/data/models/exchange_point.dart';
import '../../data/repositories/trade_offers_repository.dart';
import '../controllers/trade_cart_controller.dart';

class PublishOfferScreen extends StatefulWidget {
  const PublishOfferScreen({super.key});

  @override
  State<PublishOfferScreen> createState() => _PublishOfferScreenState();
}

class _PublishOfferScreenState extends State<PublishOfferScreen> {
  final _repository = TradeOffersRepository();
  late Future<List<ExchangePoint>> _exchangePointsFuture;
  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthController>().user;
    _exchangePointsFuture = user == null
        ? Future.value(const <ExchangePoint>[])
        : _repository.loadUserExchangePoints(user.uid);
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final cart = context.watch<TradeCartController>();
    final user = authController.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Publicar oferta')),
      body: SafeArea(
        child: FutureBuilder<List<ExchangePoint>>(
          future: _exchangePointsFuture,
          builder: (context, snapshot) {
            final exchangePoints = snapshot.data ?? const <ExchangePoint>[];

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (user == null) {
              return const _PublishMessage(
                message: 'Inicia sesión para publicar una oferta.',
              );
            }

            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _ValidationSummary(
                  user: user,
                  cart: cart,
                  exchangePoints: exchangePoints,
                ),
                const SizedBox(height: 20),
                Text(
                  'Figuritas seleccionadas',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                ...cart.items.map((item) => _StickerOfferTile(item: item)),
                const SizedBox(height: 24),
                Text(
                  'Puntos de intercambio',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                ...exchangePoints.map((point) => _ExchangePointChip(point)),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: _canPublish(user, cart, exchangePoints)
                      ? () => _publishOffer(user, cart, exchangePoints)
                      : null,
                  icon: const Icon(Icons.campaign_rounded),
                  label: Text(
                    _isPublishing ? 'Publicando...' : 'Publicar oferta',
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  bool _canPublish(
    AppUser user,
    TradeCartController cart,
    List<ExchangePoint> exchangePoints,
  ) {
    return !_isPublishing &&
        user.hasCompletedProfile &&
        user.locationConfirmed &&
        user.location != null &&
        exchangePoints.length == 3 &&
        cart.canPublish;
  }

  Future<void> _publishOffer(
    AppUser user,
    TradeCartController cart,
    List<ExchangePoint> exchangePoints,
  ) async {
    setState(() => _isPublishing = true);

    try {
      await _repository.publishOffer(
        user: user,
        cartItems: cart.items,
        exchangePoints: exchangePoints,
      );
      cart.clear();

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tu oferta ya está visible para usuarios cercanos.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = error is TradeOfferException
          ? error.message
          : 'No se pudo publicar la oferta. Inténtalo nuevamente.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) {
        setState(() => _isPublishing = false);
      }
    }
  }
}

class _ValidationSummary extends StatelessWidget {
  const _ValidationSummary({
    required this.user,
    required this.cart,
    required this.exchangePoints,
  });

  final AppUser user;
  final TradeCartController cart;
  final List<ExchangePoint> exchangePoints;

  @override
  Widget build(BuildContext context) {
    final messages = <String>[
      if (!user.hasCompletedProfile) 'Completa tu nombre de intercambio.',
      if (!user.locationConfirmed || user.location == null)
        'Confirma tu ubicación.',
      if (exchangePoints.length != 3) 'Selecciona 3 puntos de intercambio.',
      if (!cart.canPublish)
        'Debes seleccionar mínimo 6 figuritas para publicar una oferta.',
    ];

    if (messages.isEmpty) {
      return const _StatusBox(
        message: 'Todo listo para publicar tu oferta.',
        isReady: true,
      );
    }

    return _StatusBox(message: messages.join('\n'), isReady: false);
  }
}

class _StatusBox extends StatelessWidget {
  const _StatusBox({required this.message, required this.isReady});

  final String message;
  final bool isReady;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isReady ? const Color(0xFFF3F4F6) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF111827),
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
      ),
    );
  }
}

class _StickerOfferTile extends StatelessWidget {
  const _StickerOfferTile({required this.item});

  final TradeCartItem item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(child: Text(item.sticker.catalogCode)),
      title: Text(item.sticker.name),
      subtitle: Text(item.sticker.team),
      trailing: Text('x${item.quantity}'),
    );
  }
}

class _ExchangePointChip extends StatelessWidget {
  const _ExchangePointChip(this.point);

  final ExchangePoint point;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.place_rounded, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(point.name)),
        ],
      ),
    );
  }
}

class _PublishMessage extends StatelessWidget {
  const _PublishMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}
