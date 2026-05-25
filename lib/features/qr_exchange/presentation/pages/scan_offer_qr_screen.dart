import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../../auth/data/models/app_user.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../offers/data/models/trade_offer.dart';
import '../../../offers/data/repositories/trade_offers_repository.dart';
import '../../data/models/offer_qr_payload.dart';

class ScanOfferQrScreen extends StatefulWidget {
  const ScanOfferQrScreen({super.key});

  @override
  State<ScanOfferQrScreen> createState() => _ScanOfferQrScreenState();
}

class _ScanOfferQrScreenState extends State<ScanOfferQrScreen> {
  final _scannerController = MobileScannerController();
  final _repository = TradeOffersRepository();

  TradeOffer? _offer;
  OfferCompatibility? _compatibility;
  String? _errorMessage;
  bool _isLoadingOffer = false;
  bool _isCreatingProposal = false;
  bool _hasScanned = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;

    return Scaffold(
      appBar: AppBar(title: const Text('Escanear QR')),
      body: SafeArea(
        child: _offer == null
            ? Column(
                children: [
                  Expanded(
                    child: MobileScanner(
                      controller: _scannerController,
                      onDetect: (capture) => _handleCapture(capture, user),
                    ),
                  ),
                  if (_isLoadingOffer)
                    const LinearProgressIndicator(minHeight: 3),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _errorMessage ??
                          'Apunta la cámara al QR de una oferta de FIGUGOL.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              )
            : _ProposalPreview(
                offer: _offer!,
                compatibility: _compatibility!,
                isCreatingProposal: _isCreatingProposal,
                onConfirm: () => _confirmProposal(user),
              ),
      ),
    );
  }

  Future<void> _handleCapture(BarcodeCapture capture, AppUser? user) async {
    if (_hasScanned || user == null) {
      return;
    }

    final rawValue = capture.barcodes.isEmpty
        ? null
        : capture.barcodes.first.rawValue;
    if (rawValue == null || rawValue.trim().isEmpty) {
      return;
    }

    setState(() {
      _hasScanned = true;
      _isLoadingOffer = true;
      _errorMessage = null;
    });
    await _scannerController.stop();

    try {
      final payload = OfferQrPayload.fromEncoded(rawValue);
      if (payload.ownerId == user.uid) {
        throw const FormatException('No puedes escanear tu propia oferta.');
      }

      final offer = await _repository.loadOfferById(payload.offerId);
      final compatibility = await _repository.loadOfferCompatibility(
        userId: user.uid,
        offer: offer,
      );

      if (!mounted) {
        return;
      }
      setState(() {
        _offer = offer;
        _compatibility = compatibility;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error is FormatException
            ? error.message
            : 'No se pudo leer la oferta del QR.';
        _hasScanned = false;
      });
      await _scannerController.start();
    } finally {
      if (mounted) {
        setState(() => _isLoadingOffer = false);
      }
    }
  }

  Future<void> _confirmProposal(AppUser? user) async {
    final offer = _offer;
    final compatibility = _compatibility;
    if (user == null || offer == null || compatibility == null) {
      return;
    }

    final offeredStickers = _buildOfferedStickers(compatibility);
    if (offeredStickers.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Necesitas 6 figuritas duplicadas para proponer.'),
        ),
      );
      return;
    }

    setState(() => _isCreatingProposal = true);

    final requestedStickers = compatibility.missingFromOffer.take(6).toList();

    try {
      await _repository.createProposal(
        offerId: offer.id,
        fromUserId: user.uid,
        toUserId: offer.ownerId,
        offeredStickers: offeredStickers,
        requestedStickers: requestedStickers,
      );

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Propuesta creada y enviada al ofertante.'),
        ),
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo crear la propuesta. Inténtalo nuevamente.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCreatingProposal = false);
      }
    }
  }

  List<TradeOfferSticker> _buildOfferedStickers(
    OfferCompatibility compatibility,
  ) {
    final stickers = compatibility.hasEnoughDataForFullCompatibility
        ? compatibility.possibleToOffer
        : compatibility.myDuplicates;

    return stickers
        .take(6)
        .map((sticker) => TradeOfferSticker(sticker: sticker, quantity: 1))
        .toList();
  }
}

class _ProposalPreview extends StatelessWidget {
  const _ProposalPreview({
    required this.offer,
    required this.compatibility,
    required this.isCreatingProposal,
    required this.onConfirm,
  });

  final TradeOffer offer;
  final OfferCompatibility compatibility;
  final bool isCreatingProposal;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final offeredByMe = compatibility.hasEnoughDataForFullCompatibility
        ? compatibility.possibleToOffer
        : compatibility.myDuplicates;
    final sixOfferedByMe = offeredByMe.take(6).toList();
    final requested = compatibility.missingFromOffer.take(6).toList();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          offer.ownerName,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: const Color(0xFF10231B),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${offer.offeredQuantity} figuritas ofrecidas',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: const Color(0xFF5D6F66),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 24),
        if (!compatibility.hasEnoughDataForFullCompatibility)
          const _InfoBox(
            message:
                'No hay suficientes datos para calcular compatibilidad completa.',
          ),
        Text(
          '6 figuritas que podrías ofrecer',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        if (sixOfferedByMe.length < 6)
          const _InfoBox(
            message: 'No encontramos 6 duplicadas disponibles para proponer.',
          )
        else
          ...sixOfferedByMe.map(
            (sticker) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(child: Text(sticker.catalogCode)),
              title: Text(sticker.name),
              subtitle: Text(sticker.team),
            ),
          ),
        const SizedBox(height: 22),
        Text(
          'Figuritas que te faltan de esta oferta',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        if (requested.isEmpty)
          const _InfoBox(
            message: 'No detectamos faltantes tuyas dentro de esta oferta.',
          )
        else
          ...requested.map(
            (item) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(child: Text(item.sticker.catalogCode)),
              title: Text(item.sticker.name),
              subtitle: Text(item.sticker.team),
              trailing: Text('x${item.quantity}'),
            ),
          ),
        const SizedBox(height: 22),
        Text(
          'Puntos de intercambio disponibles',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        ...offer.exchangePoints.map(
          (point) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.place_rounded),
            title: Text(point.name),
            subtitle: Text(point.description),
          ),
        ),
        const SizedBox(height: 26),
        FilledButton.icon(
          onPressed: isCreatingProposal || sixOfferedByMe.length < 6
              ? null
              : onConfirm,
          icon: const Icon(Icons.check_rounded),
          label: Text(
            isCreatingProposal ? 'Creando propuesta...' : 'Confirmar propuesta',
          ),
        ),
      ],
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4D2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8C767)),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF10231B),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
