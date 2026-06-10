import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/location_controller.dart';
import 'exchange_points_screen.dart';

class LocationConfirmScreen extends StatelessWidget {
  const LocationConfirmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.select<AuthController, String?>(
      (controller) => controller.user?.uid,
    );

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Inicia sesión para confirmar tu ubicación.')),
      );
    }

    return ChangeNotifierProvider(
      create: (_) => LocationController(userId: userId)..loadCurrentPosition(),
      child: const _LocationConfirmView(),
    );
  }
}

class _LocationConfirmView extends StatelessWidget {
  const _LocationConfirmView();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LocationController>();
    final authController = context.read<AuthController>();

    _showErrorIfNeeded(context, controller);

    return Scaffold(
      appBar: AppBar(title: const Text('Ubicación')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 48,
              ),
              const SizedBox(height: 18),
              Text(
                'Confirma tu zona de intercambio',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF111827),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Usaremos una zona aproximada y un radio de 5 km para mostrar intercambios cercanos.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF6B7280),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 28),
              _LocationPreview(controller: controller),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: controller.isLoadingPosition || controller.isSaving
                    ? null
                    : controller.loadCurrentPosition,
                icon: const Icon(Icons.my_location_rounded),
                label: Text(
                  controller.isLoadingPosition
                      ? 'Actualizando...'
                      : 'Actualizar ubicación',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed:
                    !controller.hasPosition ||
                        controller.isSaving ||
                        controller.isLoadingPosition
                    ? null
                    : () async {
                        final confirmed = await controller.confirmLocation();
                        if (!context.mounted || !confirmed) {
                          return;
                        }
                        await authController.refreshCurrentUser();
                        if (!context.mounted) {
                          return;
                        }
                        await Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(
                            builder: (_) => const ExchangePointsScreen(),
                          ),
                        );
                      },
                icon: const Icon(Icons.check_rounded),
                label: Text(
                  controller.isSaving ? 'Guardando...' : 'Confirmar ubicación',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorIfNeeded(BuildContext context, LocationController controller) {
    final message = controller.errorMessage;
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
      controller.clearError();
    });
  }
}

class _LocationPreview extends StatelessWidget {
  const _LocationPreview({required this.controller});

  final LocationController controller;

  @override
  Widget build(BuildContext context) {
    final latitude = controller.latitude;
    final longitude = controller.longitude;
    final sector = controller.sector;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: controller.isLoadingPosition
          ? const Row(
              children: [
                SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
                SizedBox(width: 12),
                Text('Buscando ubicación actual...'),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  latitude == null || longitude == null
                      ? 'Ubicación pendiente'
                      : 'Zona aproximada',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  latitude == null || longitude == null
                      ? 'Actualiza tu ubicación para calcular tu zona de intercambio.'
                      : 'Latitud: ${latitude.toStringAsFixed(5)}\nLongitud: ${longitude.toStringAsFixed(5)}\nZona: $sector\nRadio cercano: 5 km',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
              ],
            ),
    );
  }
}
