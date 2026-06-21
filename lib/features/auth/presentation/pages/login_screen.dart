import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/figugol_action_button.dart';
import '../controllers/auth_controller.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa tu correo y contraseña')),
      );
      return;
    }

    context.read<AuthController>().signInWithEmailAndPassword(email, password);
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      controller.clearError();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AuthController>();
    final textTheme = Theme.of(context).textTheme;

    _showErrorIfNeeded(context, controller);

    return Scaffold(
      body: Stack(
        children: [
          // Welcome Text at the top
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Image.asset('assets/images/logo.png', height: 180),
                const SizedBox(height: 20),
                Text(
                  'Bienvenido de nuevo',
                  style: textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(width: 24, height: 3, color: Theme.of(context).colorScheme.onSurface),
                    const SizedBox(width: 8),
                    Container(width: 6, height: 3, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54)),
                    const SizedBox(width: 8),
                    Container(width: 6, height: 3, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54)),
                  ],
                ),
              ],
            ),
          ),

          // Bottom Sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: const BorderRadius.only(
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
                      'Iniciar Sesión',
                      style: textTheme.titleLarge?.copyWith(
                        color: AppTheme.lightText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Email Field
                    _CustomTextField(
                      controller: _emailController,
                      icon: Icons.mail_outline_rounded,
                      hintText: 'Correo electrónico',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),
                    
                    // Password Field
                    _CustomTextField(
                      controller: _passwordController,
                      icon: Icons.lock_outline_rounded,
                      hintText: 'Contraseña',
                      obscureText: true,
                    ),
                    const SizedBox(height: 32),
                    
                    // Sign In Button
                    FigugolActionButton(
                      label: controller.isLoading ? 'Cargando...' : 'Iniciar Sesión',
                      onPressed: controller.isLoading ? null : _onLogin,
                      style: FigugolActionButtonStyle.primary,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Navigate to Register
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '¿No tienes cuenta? ',
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade400,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Regístrate',
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppTheme.accentBrand,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),

                    // Google Login Fallback
                    FigugolActionButton(
                      label: controller.isLoading ? 'Cargando...' : 'Continuar con Google',
                      icon: Icons.login_rounded,
                      onPressed: controller.isLoading ? null : controller.signInWithGoogle,
                      style: FigugolActionButtonStyle.secondary,
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
    this.obscureText = false,
    this.keyboardType,
  });

  final TextEditingController controller;
  final IconData icon;
  final String hintText;
  final bool obscureText;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey.shade400),
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade500),
        filled: false,
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.borderLine),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.accentBrand, width: 2),
        ),
      ),
    );
  }
}
