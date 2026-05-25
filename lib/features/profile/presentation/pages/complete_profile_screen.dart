import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/figugol_action_button.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _exchangeNameController = TextEditingController();

  @override
  void dispose() {
    _exchangeNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final textTheme = Theme.of(context).textTheme;

    _showErrorIfNeeded(context, authController);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Completa tu perfil'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: authController.isLoading ? null : authController.signOut,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 28),
                Icon(
                  Icons.handshake_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 48,
                ),
                const SizedBox(height: 18),
                Text(
                  'Elige tu nombre para intercambios',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF10231B),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Este nombre será visible cuando propongas intercambios de figuritas.',
                  style: textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF5D6F66),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _exchangeNameController,
                  textInputAction: TextInputAction.done,
                  enabled: !authController.isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Nombre para intercambios',
                    hintText: 'Ej. Coleccionista Lima',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final trimmedValue = value?.trim() ?? '';
                    if (trimmedValue.isEmpty) {
                      return 'Ingresa un nombre para intercambios.';
                    }
                    if (trimmedValue.length < 3) {
                      return 'Usa al menos 3 caracteres.';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _submit(authController),
                ),
                const SizedBox(height: 22),
                FigugolActionButton(
                  label: authController.isLoading
                      ? 'Guardando...'
                      : 'Guardar perfil',
                  icon: Icons.check_rounded,
                  onPressed: authController.isLoading
                      ? null
                      : () => _submit(authController),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit(AuthController authController) {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    authController.completeProfile(_exchangeNameController.text);
  }

  void _showErrorIfNeeded(BuildContext context, AuthController controller) {
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
