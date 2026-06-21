import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/models/app_user.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/models/trade_offer.dart';
import '../../data/repositories/trade_offers_repository.dart';
import 'offer_detail_screen.dart';

class MyPublishedOffersScreen extends StatefulWidget {
  const MyPublishedOffersScreen({super.key});

  @override
  State<MyPublishedOffersScreen> createState() => _MyPublishedOffersScreenState();
}

class _MyPublishedOffersScreenState extends State<MyPublishedOffersScreen> {
  final TradeOffersRepository _repository = TradeOffersRepository();

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthController, AppUser?>(
      (controller) => controller.user,
    );

    if (user == null) {
      return const Scaffold(
        body: _EmptyState(
          icon: Icons.person_off_rounded,
          title: 'Inicia sesión',
          message: 'Necesitas iniciar sesión para ver tus publicaciones.',
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mis publicaciones'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Activas'),
              Tab(text: 'Completadas'),
            ],
            indicatorColor: AppTheme.primaryBrand,
            labelColor: AppTheme.lightText,
            unselectedLabelColor: Colors.grey,
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              _OffersList(
                stream: _repository.watchMyActiveOffers(user.uid),
                emptyTitle: 'No tienes ofertas activas',
                emptyMessage: 'Tus publicaciones recientes aparecerán aquí.',
              ),
              _OffersList(
                stream: _repository.watchMyCompletedOffers(user.uid),
                emptyTitle: 'No hay intercambios completados',
                emptyMessage: 'El historial de tus intercambios aparecerá aquí.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OffersList extends StatelessWidget {
  const _OffersList({
    required this.stream,
    required this.emptyTitle,
    required this.emptyMessage,
  });

  final Stream<List<TradeOffer>> stream;
  final String emptyTitle;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TradeOffer>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const _EmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Ocurrió un error',
            message: 'No pudimos cargar esta lista. Inténtalo más tarde.',
          );
        }

        final offers = snapshot.data ?? const <TradeOffer>[];
        if (offers.isEmpty) {
          return _EmptyState(
            icon: Icons.list_alt_rounded,
            title: emptyTitle,
            message: emptyMessage,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: offers.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final offer = offers[index];
            return _MyOfferCard(
              offer: offer,
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
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
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
            Icon(icon, color: AppTheme.primaryBrand, size: 58),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.lightText,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
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

class _MyOfferCard extends StatelessWidget {
  const _MyOfferCard({
    required this.offer,
    required this.onViewOffer,
  });

  final TradeOffer offer;
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
                  backgroundColor: AppTheme.primaryBrand.withValues(alpha: 0.2),
                  child: const Icon(Icons.style_rounded, color: AppTheme.primaryBrand),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${offer.offeredQuantity} figuritas ofrecidas',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.lightText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: offer.status == TradeOfferStatus.active 
                        ? AppTheme.primaryBrand.withValues(alpha: 0.2)
                        : Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    offer.status == TradeOfferStatus.active ? 'Activa' : 'Completada',
                    style: TextStyle(
                      color: offer.status == TradeOfferStatus.active 
                          ? AppTheme.primaryBrand 
                          : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
        Icon(icon, size: 18, color: AppTheme.primaryBrand),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
