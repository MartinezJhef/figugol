import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/models/trade_offer.dart';
import '../../data/repositories/trade_offers_repository.dart';

class ProposeTradeScreen extends StatefulWidget {
  const ProposeTradeScreen({
    required this.offer,
    required this.compatibility,
    super.key,
  });

  final TradeOffer offer;
  final OfferCompatibility compatibility;

  @override
  State<ProposeTradeScreen> createState() => _ProposeTradeScreenState();
}

class _ProposeTradeScreenState extends State<ProposeTradeScreen> {
  final _repository = TradeOffersRepository();
  final Set<String> _selectedOfferedIds = {};
  final Set<String> _selectedRequestedIds = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedRequestedIds.addAll(
      widget.compatibility.missingFromOffer.map((item) => item.sticker.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableDuplicates = widget.compatibility.myDuplicates;

    return Scaffold(
      appBar: AppBar(title: const Text('Proponer intercambio')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const _ProposalInfo(),
            const SizedBox(height: 20),
            Text(
              'Elige tus duplicadas para ofrecer',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.darkText,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            if (availableDuplicates.isEmpty)
              const _EmptySelectionMessage(
                text: 'No tienes figuritas duplicadas disponibles.',
              )
            else
              ...availableDuplicates.map(
                (sticker) => CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _selectedOfferedIds.contains(sticker.id),
                  title: Text('${sticker.catalogCode}  ${sticker.name}'),
                  subtitle: Text(sticker.team),
                  onChanged: (value) {
                    setState(() {
                      if (value ?? false) {
                        _selectedOfferedIds.add(sticker.id);
                      } else {
                        _selectedOfferedIds.remove(sticker.id);
                      }
                    });
                  },
                ),
              ),
            const SizedBox(height: 20),
            Text(
              'Elige las figuritas que solicitas',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.darkText,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            ...widget.offer.stickersOffered.map(
              (item) => CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _selectedRequestedIds.contains(item.sticker.id),
                title: Text(
                  '${item.sticker.catalogCode}  ${item.sticker.name}',
                ),
                subtitle: Text(
                  '${item.sticker.team} - Disponible x${item.quantity}',
                ),
                onChanged: (value) {
                  setState(() {
                    if (value ?? false) {
                      _selectedRequestedIds.add(item.sticker.id);
                    } else {
                      _selectedRequestedIds.remove(item.sticker.id);
                    }
                  });
                },
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _canSubmit ? _submitProposal : null,
              icon: const Icon(Icons.send_rounded),
              label: Text(
                _isSubmitting ? 'Enviando propuesta...' : 'Enviar propuesta',
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _canSubmit =>
      !_isSubmitting &&
      _selectedOfferedIds.isNotEmpty &&
      _selectedRequestedIds.isNotEmpty;

  Future<void> _submitProposal() async {
    final user = context.read<AuthController>().user;
    if (user == null) {
      return;
    }

    setState(() => _isSubmitting = true);
    final offered = widget.compatibility.myDuplicates
        .where((sticker) => _selectedOfferedIds.contains(sticker.id))
        .map((sticker) => TradeOfferSticker(sticker: sticker, quantity: 1))
        .toList();
    final requested = widget.offer.stickersOffered
        .where((item) => _selectedRequestedIds.contains(item.sticker.id))
        .map((item) => TradeOfferSticker(sticker: item.sticker, quantity: 1))
        .toList();

    try {
      await _repository.createProposal(
        offerId: widget.offer.id,
        fromUserId: user.uid,
        toUserId: widget.offer.ownerId,
        offeredStickers: offered,
        requestedStickers: requested,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tu propuesta fue enviada.')),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = error is TradeOfferException
          ? error.message
          : 'No se pudo enviar la propuesta. Intentalo nuevamente.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

class _ProposalInfo extends StatelessWidget {
  const _ProposalInfo();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Selecciona lo que entregas y lo que deseas recibir. '
        'La otra persona podra revisar tu propuesta antes del intercambio.',
      ),
    );
  }
}

class _EmptySelectionMessage extends StatelessWidget {
  const _EmptySelectionMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(text),
    );
  }
}
