import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/models/app_user.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../offers/data/models/trade_offer.dart';
import '../../../payments/data/models/payment_simulation.dart';
import '../../../payments/data/repositories/payment_simulation_repository.dart';

class MarketplaceCheckoutScreen extends StatefulWidget {
  const MarketplaceCheckoutScreen({required this.offer, super.key});

  final TradeOffer offer;

  @override
  State<MarketplaceCheckoutScreen> createState() =>
      _MarketplaceCheckoutScreenState();
}

class _MarketplaceCheckoutScreenState extends State<MarketplaceCheckoutScreen> {
  final _repository = PaymentSimulationRepository();
  bool _isPaying = false;
  PaymentSimulation? _payment;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;
    final quantity = widget.offer.offeredQuantity;
    final total = quantity * PaymentSimulationRepository.unitPrice;

    if (_payment != null) {
      return _PaymentSuccessScreen(payment: _payment!);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Tiendita FIGUGOL')),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.fieldGreen,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.storefront_rounded,
                        color: AppTheme.gold,
                        size: 42,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Resumen de compra/intercambio',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Simulación visual. No se solicitan tarjetas, claves ni pagos reales.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFFEAF4E2),
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _OfferSummary(offer: widget.offer),
                const SizedBox(height: 14),
                _PriceSummary(quantity: quantity, total: total),
                const SizedBox(height: 14),
                const _SimulatedPaymentPanel(),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: user == null || _isPaying
                      ? null
                      : () => _simulatePayment(user),
                  icon: const Icon(Icons.lock_rounded),
                  label: Text(
                    _isPaying ? 'Procesando...' : 'Pagar comisión simulada',
                  ),
                ),
              ],
            ),
            if (_isPaying)
              Container(
                color: Colors.white.withValues(alpha: 0.64),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _simulatePayment(AppUser user) async {
    setState(() => _isPaying = true);

    try {
      final payment = await _repository.simulateSuccessfulPayment(
        userId: user.uid,
        offer: widget.offer,
      );

      if (!mounted) {
        return;
      }
      setState(() => _payment = payment);
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = error is PaymentSimulationException
          ? error.message
          : 'No se pudo simular el pago. Inténtalo nuevamente.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() => _isPaying = false);
      }
    }
  }
}

class _OfferSummary extends StatelessWidget {
  const _OfferSummary({required this.offer});

  final TradeOffer offer;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              offer.ownerName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            ...offer.stickersOffered.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.sticker.catalogCode} ${item.sticker.name}',
                      ),
                    ),
                    Text('x${item.quantity}'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceSummary extends StatelessWidget {
  const _PriceSummary({required this.quantity, required this.total});

  final int quantity;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFEAF4E2),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            _PriceRow(label: 'Cantidad', value: '$quantity figuritas'),
            const SizedBox(height: 8),
            const _PriceRow(label: 'Precio unitario', value: 'S/ 0.80'),
            const Divider(height: 22),
            _PriceRow(
              label: 'Total',
              value: 'S/ ${total.toStringAsFixed(2)}',
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  final String label;
  final String value;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyLarge?.copyWith(
      color: AppTheme.ink,
      fontWeight: isTotal ? FontWeight.w900 : FontWeight.w700,
    );

    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(value, style: style),
      ],
    );
  }
}

class _SimulatedPaymentPanel extends StatelessWidget {
  const _SimulatedPaymentPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.ink,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pago simulado',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          const _FakeInput(label: 'Tarjeta de prueba', value: '•••• 4242'),
          const SizedBox(height: 10),
          const Row(
            children: [
              Expanded(
                child: _FakeInput(label: 'Vence', value: '12/34'),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _FakeInput(label: 'CVC', value: '•••'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FakeInput extends StatelessWidget {
  const _FakeInput({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 3),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _PaymentSuccessScreen extends StatelessWidget {
  const _PaymentSuccessScreen({required this.payment});

  final PaymentSimulation payment;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resultado')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: AppTheme.grassGreen,
                size: 58,
              ),
              const SizedBox(height: 18),
              Text(
                'Pago simulado exitoso',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tu intercambio ha sido reservado.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF5D6F66),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 22),
              Text('Total simulado: S/ ${payment.total.toStringAsFixed(2)}'),
              const Spacer(),
              FilledButton.icon(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                icon: const Icon(Icons.home_rounded),
                label: const Text('Volver al inicio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
