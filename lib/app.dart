import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/internet_guard.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/auth/presentation/pages/auth_gate.dart';
import 'features/offers/presentation/controllers/trade_cart_controller.dart';

class FigugolApp extends StatelessWidget {
  const FigugolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => TradeCartController()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        initialRoute: AppRoutes.authGate,
        routes: {AppRoutes.authGate: (_) => const AuthGate()},
        builder: (context, child) {
          return InternetGuard(child: child ?? const SizedBox.shrink());
        },
      ),
    );
  }
}
