import 'package:figugol/features/auth/presentation/pages/login_screen.dart';
import 'package:figugol/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('shows the FIGUGOL login screen', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthController(loadCurrentUserOnStart: false),
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.text('FIGUGOL'), findsOneWidget);
    expect(find.text('Intercambia tus figuritas cerca de ti'), findsOneWidget);
    expect(find.text('Ingresar con Google'), findsOneWidget);
  });
}
