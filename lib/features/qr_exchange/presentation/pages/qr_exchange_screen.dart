import 'package:flutter/material.dart';

import 'generate_offer_qr_screen.dart';
import 'scan_offer_qr_screen.dart';

class QrExchangeScreen extends StatelessWidget {
  const QrExchangeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Intercambio QR')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Intercambio presencial',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF10231B),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Genera un QR para una oferta activa o escanea el QR de otro coleccionista.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF5D6F66),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const GenerateOfferQrScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.qr_code_rounded),
                label: const Text('Generar QR'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ScanOfferQrScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const Text('Escanear QR'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
