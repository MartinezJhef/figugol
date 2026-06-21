import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/figugol_action_button.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _exchangeNameController = TextEditingController();

  @override
  void dispose() {
    _exchangeNameController.dispose();
    super.dispose();
  }

  void _submit(AuthController authController) {
    final trimmedValue = _exchangeNameController.text.trim();
    if (trimmedValue.isEmpty || trimmedValue.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un nombre de usuario válido (min. 3 caracteres).')),
      );
      return;
    }

    authController.completeProfile(trimmedValue);
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

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final textTheme = Theme.of(context).textTheme;

    _showErrorIfNeeded(context, authController);

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/auth_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          
          // Back/Logout Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: authController.isLoading ? null : authController.signOut,
              tooltip: 'Cerrar sesión',
            ),
          ),

          // Welcome text or context
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  'Falta poco...',
                  style: textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),

          // Bottom Sheet Form
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              padding: const EdgeInsets.only(
                left: 32,
                right: 32,
                top: 40,
                bottom: 40,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Completa tu perfil',
                      style: textTheme.titleLarge?.copyWith(
                        color: AppTheme.lightText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Elige tu nombre para intercambios.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Username Field
                    _CustomTextField(
                      controller: _exchangeNameController,
                      icon: Icons.person_outline_rounded,
                      hintText: 'Nombre de usuario',
                    ),
                    const SizedBox(height: 32),
                    
                    // Submit Button
                    FigugolActionButton(
                      label: authController.isLoading ? 'Guardando...' : 'Guardar perfil',
                      onPressed: authController.isLoading ? null : () => _submit(authController),
                      style: FigugolActionButtonStyle.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomTextField extends StatelessWidget {
  const _CustomTextField({
    required this.controller,
    required this.icon,
    required this.hintText,
  });

  final TextEditingController controller;
  final IconData icon;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey.shade600),
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        filled: false,
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.accentBrand, width: 2),
        ),
      ),
      onSubmitted: (_) {},
    );
  }
}
