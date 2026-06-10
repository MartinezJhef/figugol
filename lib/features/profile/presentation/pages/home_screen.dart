import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/connectivity_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../location/presentation/pages/location_confirm_screen.dart';
import '../../../offers/presentation/pages/nearby_offers_screen.dart';
import '../../../offers/presentation/pages/publish_offer_screen.dart';
import '../../../stickers/data/models/sticker_stats.dart';
import '../../../stickers/data/repositories/stickers_repository.dart';
import '../../../stickers/presentation/pages/stickers_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.onOpenTab});

  final ValueChanged<int>? onOpenTab;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;
    final exchangeName = user?.exchangeName ?? 'Coleccionista';
    final userId = user?.uid;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.secondaryGreen,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.sports_soccer_rounded,
                  color: AppTheme.accentBlue,
                  size: 42,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hola, $exchangeName',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Revisa tu álbum y encuentra intercambios cerca de tu zona.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFFF3F4F6),
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const _ConnectionStatusCard(),
          const SizedBox(height: 12),
          _LocationStatusCard(
            locationConfirmed: user?.locationConfirmed ?? false,
            selectedPointsCount: user?.selectedExchangePoints.length ?? 0,
          ),
          const SizedBox(height: 16),
          if (userId == null)
            const _StatsGrid(
              stats: StickerStats(owned: 0, duplicates: 0, missing: 0),
            )
          else
            StreamBuilder<StickerStats>(
              stream: StickersRepository().watchStickerStats(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _StatsLoadingCard();
                }
                if (snapshot.hasError) {
                  return const _HomeInfoCard(
                    icon: Icons.error_outline_rounded,
                    message: 'No pudimos cargar tu resumen de figuritas.',
                  );
                }
                return _StatsGrid(
                  stats:
                      snapshot.data ??
                      const StickerStats(owned: 0, duplicates: 0, missing: 0),
                );
              },
            ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _openStickers(context),
            icon: const Icon(Icons.style_rounded),
            label: const Text('Registrar figuritas'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: user?.canPublishOffers == true
                ? () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const PublishOfferScreen(),
                    ),
                  )
                : null,
            icon: const Icon(Icons.add_business_rounded),
            label: const Text('Publicar intercambio'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: user?.location == null
                ? null
                : () => _openNearbyOffers(context),
            icon: const Icon(Icons.travel_explore_rounded),
            label: const Text('Ver ofertas cercanas'),
          ),
        ],
      ),
    );
  }

  void _openStickers(BuildContext context) {
    final callback = onOpenTab;
    if (callback != null) {
      callback(1);
      return;
    }
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const StickersScreen()));
  }

  void _openNearbyOffers(BuildContext context) {
    final callback = onOpenTab;
    if (callback != null) {
      callback(2);
      return;
    }
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => NearbyOffersScreen()));
  }
}

class _ConnectionStatusCard extends StatelessWidget {
  const _ConnectionStatusCard();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: const ConnectivityService().watchInternetConnectionContinuously(),
      initialData: true,
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? true;
        return _StatusCard(
          icon: isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
          text: isOnline ? 'Conexión disponible.' : 'Sin conexión a internet.',
          isReady: isOnline,
        );
      },
    );
  }
}

class _LocationStatusCard extends StatelessWidget {
  const _LocationStatusCard({
    required this.locationConfirmed,
    required this.selectedPointsCount,
  });

  final bool locationConfirmed;
  final int selectedPointsCount;

  @override
  Widget build(BuildContext context) {
    final isReady = locationConfirmed && selectedPointsCount == 3;
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const LocationConfirmScreen(),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: _StatusCard(
        icon: isReady ? Icons.check_circle_rounded : Icons.info_rounded,
        text: isReady
            ? 'Ubicación y 3 puntos confirmados.'
            : locationConfirmed
            ? 'Seleccionaste $selectedPointsCount de 3 puntos.'
            : 'Confirma tu ubicación para continuar.',
        isReady: isReady,
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.text,
    required this.isReady,
  });

  final IconData icon;
  final String text;
  final bool isReady;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isReady ? const Color(0xFFF3F4F6) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isReady ? const Color(0xFFE5E7EB) : const Color(0xFFFDE68A),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isReady ? AppTheme.primaryRed : const Color(0xFFD97706),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.darkText,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsLoadingCard extends StatelessWidget {
  const _StatsLoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
            SizedBox(width: 12),
            Expanded(child: Text('Cargando resumen de figuritas...')),
          ],
        ),
      ),
    );
  }
}

class _HomeInfoCard extends StatelessWidget {
  const _HomeInfoCard({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryRed),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.darkText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final StickerStats stats;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.05,
      children: [
        _StatTile(label: 'Tengo', value: stats.owned),
        _StatTile(label: 'Repetidas', value: stats.duplicates),
        _StatTile(label: 'Faltantes', value: stats.missing),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLine),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$value',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.darkText,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
