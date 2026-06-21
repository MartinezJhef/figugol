import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/figugol_action_button.dart';
import '../controllers/auth_controller.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onSignUp() {
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes aceptar los términos y condiciones')),
      );
      return;
    }
    
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    context.read<AuthController>().createUserWithEmailAndPassword(
          email,
          password,
          username,
        );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AuthController>();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          // Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),

          // Welcome text at the top
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Image.asset('assets/images/logo.png', height: 180),
                const SizedBox(height: 20),
                Text(
                  'Regístrate y disfruta',
                  style: textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
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
                      'Crear cuenta nueva',
                      style: textTheme.titleLarge?.copyWith(
                        color: AppTheme.lightText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Username Field
                    _CustomTextField(
                      controller: _usernameController,
                      icon: Icons.person_outline_rounded,
                      hintText: 'Nombre de usuario',
                    ),
                    const SizedBox(height: 20),
                    
                    // Password Field
                    _CustomTextField(
                      controller: _passwordController,
                      icon: Icons.lock_outline_rounded,
                      hintText: 'Contraseña',
                      obscureText: true,
                    ),
                    const SizedBox(height: 20),
                    
                    // Email Field
                    _CustomTextField(
                      controller: _emailController,
                      icon: Icons.mail_outline_rounded,
                      hintText: 'Correo electrónico',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 24),
                    
                    // Terms and Conditions
                    Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _acceptedTerms,
                            activeColor: AppTheme.accentBrand,
                            onChanged: (value) {
                              setState(() {
                                _acceptedTerms = value ?? false;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Acepto los Términos y Condiciones',
                            style: textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // Sign Up Button
                    FigugolActionButton(
                      label: controller.isLoading ? 'Cargando...' : 'Registrarse',
                      onPressed: controller.isLoading ? null : _onSignUp,
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
