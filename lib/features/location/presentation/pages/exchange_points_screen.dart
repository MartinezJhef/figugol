import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/data/models/app_user.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/models/exchange_point.dart';
import '../controllers/exchange_points_controller.dart';

class ExchangePointsScreen extends StatelessWidget {
  const ExchangePointsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthController, AppUser?>(
      (controller) => controller.user,
    );

    if (user == null || user.location == null) {
      return const Scaffold(
        body: Center(
          child: Text('Confirma tu ubicación antes de elegir puntos.'),
        ),
      );
    }

    return ChangeNotifierProvider(
      create: (_) => ExchangePointsController(
        userId: user.uid,
        location: user.location!,
        selectedExchangePointIds: user.selectedExchangePoints,
      ),
      child: const _ExchangePointsView(),
    );
  }
}

class _ExchangePointsView extends StatelessWidget {
  const _ExchangePointsView();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ExchangePointsController>();
    final authController = context.read<AuthController>();

    _showErrorIfNeeded(context, controller);

    return Scaffold(
      appBar: AppBar(title: const Text('Puntos de intercambio')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Elige tus puntos seguros',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: const Color(0xFF10231B),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Seleccionaste ${controller.selectedCount} de 3 puntos',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF126B3A),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                itemCount: controller.points.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final point = controller.points[index];
                  return _ExchangePointTile(
                    point: point,
                    onTap: () => controller.togglePoint(point.id),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: FilledButton.icon(
                onPressed: controller.canSave
                    ? () async {
                        final saved = await controller.saveSelectedPoints();
                        if (!context.mounted || !saved) {
                          return;
                        }
                        await authController.refreshCurrentUser();
                        if (!context.mounted) {
                          return;
                        }
                        Navigator.of(context).pop();
                      }
                    : null,
                icon: const Icon(Icons.check_rounded),
                label: Text(
                  controller.isSaving ? 'Guardando...' : 'Guardar puntos',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorIfNeeded(
    BuildContext context,
    ExchangePointsController controller,
  ) {
    final message = controller.errorMessage;
    if (message == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
      controller.clearError();
    });
  }
}

class _ExchangePointTile extends StatelessWidget {
  const _ExchangePointTile({required this.point, required this.onTap});

  final ExchangePoint point;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: point.isSelected ? const Color(0xFFEAF4E2) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: point.isSelected
                ? const Color(0xFF126B3A)
                : const Color(0xFFD5DDD6),
            width: point.isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _iconForType(point.type),
              color: point.isSelected
                  ? const Color(0xFF126B3A)
                  : const Color(0xFF5D6F66),
              size: 30,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    point.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF10231B),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    point.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF5D6F66),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF5D6F66),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Checkbox(value: point.isSelected, onChanged: (_) => onTap()),
          ],
        ),
      ),
    );
  }

  IconData _iconForType(ExchangePointType type) {
    return switch (type) {
      ExchangePointType.park => Icons.park_rounded,
      ExchangePointType.shoppingCenter => Icons.store_mall_directory_rounded,
      ExchangePointType.square => Icons.location_city_rounded,
      ExchangePointType.university => Icons.school_rounded,
      ExchangePointType.other => Icons.place_rounded,
    };
  }
}
