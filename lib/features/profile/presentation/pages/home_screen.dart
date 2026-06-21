import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/connectivity_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

import '../../../offers/presentation/pages/nearby_offers_screen.dart';
import '../../../offers/presentation/pages/my_published_offers_screen.dart';
import '../../../offers/presentation/pages/notifications_screen.dart';
import '../../../offers/data/models/trade_notification.dart';
import '../../../offers/data/repositories/trade_offers_repository.dart';
import '../../../stickers/data/models/sticker_stats.dart';
import '../../../stickers/data/repositories/stickers_repository.dart';
import '../../../stickers/presentation/pages/stickers_screen.dart';
import '../../../stickers/presentation/controllers/stickers_controller.dart';
import '../../../../features/qr_exchange/presentation/pages/user_qr_options_modal.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.onOpenTab});

  final ValueChanged<int>? onOpenTab;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;
    final exchangeName = user?.exchangeName ?? 'Coleccionista';
    final userId = user?.uid;

    final hour = DateTime.now().hour;
    final String greetingSubtitle;
    if (hour < 12) {
      greetingSubtitle = 'Buenos días';
    } else if (hour < 19) {
      greetingSubtitle = 'Buenas tardes';
    } else {
      greetingSubtitle = 'Buenas noches';
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.grid_view_rounded, color: AppTheme.lightText, size: 28),
              Text(
                'Inicio',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.lightText,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (userId != null)
                StreamBuilder<List<TradeNotification>>(
                  stream: TradeOffersRepository().watchNotifications(userId),
                  builder: (context, snapshot) {
                    final notifications = snapshot.data ?? [];
                    final hasUnread = notifications.any((n) => n.status == TradeNotificationStatus.unread);

                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const NotificationsScreen(),
                          ),
                        );
                      },
                      child: Stack(
                        children: [
                          const Icon(Icons.notifications_none_rounded, color: AppTheme.lightText, size: 30),
                          if (hasUnread)
                            Positioned(
                              right: 2,
                              top: 2,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: AppTheme.secondaryBrand,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                )
              else
                const Icon(Icons.notifications_none_rounded, color: AppTheme.lightText, size: 30),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '¡Hola $exchangeName!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.accentBrand,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (userId != null)
                IconButton(
                  onPressed: () => UserQrOptionsModal.show(context),
                  icon: const Icon(Icons.qr_code_rounded, color: AppTheme.accentBrand, size: 32),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            greetingSubtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: const Color(0xFF9CA3AF),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.borderLine, width: 1.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¡Bienvenido!',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.accentBrand,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Organiza tus intercambios y completa tu álbum.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF4B5563),
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  height: 72,
                  width: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/logo.png'),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const _ConnectionStatusCard(),






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
                  onOpenTab: onOpenTab,
                  stats:
                      snapshot.data ??
                      const StickerStats(owned: 0, duplicates: 0, missing: 0),
                );
              },
            ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Acciones',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.lightText,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'ver todo',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.95,
            children: [
              _ActionCard(
                title: 'Registrar\nFiguritas',
                icon: Icons.style_rounded,
                isPrimary: true,
                onTap: () => _openStickers(context),
              ),
              _ActionCard(
                title: 'Publicadas para\nIntercambio',
                icon: Icons.storefront_rounded,
                onTap: user != null
                    ? () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const MyPublishedOffersScreen(),
                        ),
                      )
                    : null,
              ),
              _ActionCard(
                title: 'Ver Ofertas\nCercanas',
                icon: Icons.travel_explore_rounded,
                onTap: user?.location == null
                    ? null
                    : () => _openNearbyOffers(context),
              ),
              _ActionCard(
                title: 'Ver mi\nalbum',
                icon: Icons.book_rounded,
                onTap: () => _openAlbum(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openStickers(BuildContext context) {
    final callback = onOpenTab;
    if (callback != null) {
      callback(1); // Repetidas
      return;
    }
  }

  void _openAlbum(BuildContext context) {
    final callback = onOpenTab;
    if (callback != null) {
      context.read<StickersController>().setFilter(StickerFilter.all);
      callback(2); // Mi Álbum
      return;
    }
  }

  void _openNearbyOffers(BuildContext context) {
    final callback = onOpenTab;
    if (callback != null) {
      callback(3); // Tiendita (Marketplace)
      return;
    }
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
        if (isOnline) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _StatusCard(
            icon: Icons.wifi_off_rounded,
            text: 'Sin conexión a internet.',
            isReady: false,
          ),
        );
      },
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
            color: isReady ? AppTheme.primaryBrand : const Color(0xFFD97706),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightText,
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
            Icon(icon, color: AppTheme.primaryBrand),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightText,
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
  const _StatsGrid({required this.stats, this.onOpenTab});

  final StickerStats stats;
  final ValueChanged<int>? onOpenTab;

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
        _StatTile(
          label: 'Tengo',
          value: stats.owned,
          onTap: () {
            context.read<StickersController>().setFilter(StickerFilter.owned);
            onOpenTab?.call(2); // Mi Álbum
          },
        ),
        _StatTile(
          label: 'Repetidas',
          value: stats.duplicates,
          onTap: () {
            context.read<StickersController>().setFilter(StickerFilter.duplicates);
            onOpenTab?.call(1); // Repetidas
          },
        ),
        _StatTile(
          label: 'Faltantes',
          value: stats.missing,
          onTap: () {
            context.read<StickersController>().setFilter(StickerFilter.missing);
            onOpenTab?.call(2); // Mi Álbum
          },
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, this.onTap});

  final String label;
  final int value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderLine),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$value',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.lightText,
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
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.icon,
    this.onTap,
    this.isPrimary = false,
  });

  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final bgColor = isPrimary ? AppTheme.accentBrand : AppTheme.cardDark;
    final textColor = isPrimary ? Colors.white : AppTheme.lightText;
    final iconColor = isPrimary ? Colors.white : AppTheme.accentBrand;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          border: isPrimary ? null : Border.all(color: AppTheme.borderLine),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: AppTheme.accentBrand.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: iconColor, size: 32),
                Icon(Icons.more_vert, color: textColor.withValues(alpha: 0.5), size: 20),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w900,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Container(
              height: 4,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isPrimary ? Colors.white.withValues(alpha: 0.3) : AppTheme.borderLine,
                borderRadius: BorderRadius.circular(2),
              ),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: 0.6,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: isPrimary ? Colors.white : AppTheme.primaryBrand,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
