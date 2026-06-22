import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../location/presentation/pages/exchange_points_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final user = authController.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(24),
                image: DecorationImage(
                  image: const AssetImage('assets/images/app_bg.png'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.6),
                    BlendMode.darken,
                  ),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: Colors.white,
                    backgroundImage: user?.photoUrl == null
                        ? null
                        : NetworkImage(user!.photoUrl!),
                    child: user?.photoUrl == null
                        ? const Icon(
                            Icons.person_rounded,
                            size: 38,
                            color: Colors.black87,
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.exchangeName ?? 'Coleccionista',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? 'Sin email',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: const Color(0xFFF3F4F6),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _ProfileRow(
              icon: Icons.alternate_email_rounded,
              label: 'Email',
              value: user?.email ?? 'Sin email',
            ),
            _ProfileRow(
              icon: Icons.handshake_rounded,
              label: 'Nombre de intercambio',
              value: user?.exchangeName ?? 'Pendiente',
              onTap: () => _showEditNameDialog(context, authController, user?.exchangeName ?? ''),
            ),
            _ProfileRow(
              icon: Icons.location_on_rounded,
              label: 'Ubicación confirmada',
              value: user?.locationConfirmed == true ? 'Sí' : 'No',
            ),
            _ProfileRow(
              icon: Icons.add_location_alt_rounded,
              label: 'Puntos seleccionados',
              value: '${user?.selectedExchangePoints.length ?? 0} punto(s)',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ExchangePointsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: authController.isLoading
                  ? null
                  : authController.signOut,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Cerrar sesión'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditNameDialog(BuildContext context, AuthController authController, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardDark,
          title: const Text('Editar nombre', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Nuevo nombre',
              hintStyle: TextStyle(color: Colors.grey),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                final newName = controller.text.trim();
                if (newName.length >= 3) {
                  authController.completeProfile(newName);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('El nombre debe tener al menos 3 caracteres.')),
                  );
                }
              },
              child: const Text('Guardar', style: TextStyle(color: AppTheme.primaryBrand)),
            ),
          ],
        );
      },
    );
  }
}
class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryBrand),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.lightText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            const Icon(Icons.edit_rounded, color: Color(0xFF6B7280), size: 20),
        ],
      ),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: onTap != null
          ? InkWell(onTap: onTap, child: content)
          : content,
    );
  }
}
