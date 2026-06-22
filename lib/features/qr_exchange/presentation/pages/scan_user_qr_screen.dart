import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../../auth/data/models/app_user.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../offers/data/models/trade_offer.dart';
import '../../../offers/data/repositories/trade_offers_repository.dart';
import '../../../stickers/data/models/sticker.dart';
import '../../../stickers/data/repositories/stickers_repository.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/user_qr_payload.dart';

class ScanUserQrScreen extends StatefulWidget {
  const ScanUserQrScreen({super.key});

  @override
  State<ScanUserQrScreen> createState() => _ScanUserQrScreenState();
}

class _ScanUserQrScreenState extends State<ScanUserQrScreen> {
  final _scannerController = MobileScannerController();
  final _stickersRepository = StickersRepository();
  final _offersRepository = TradeOffersRepository();

  UserQrPayload? _scannedUser;
  List<Sticker> _iGive = [];
  List<Sticker> _iReceive = [];

  final Set<String> _selectedToGive = {};
  final Set<String> _selectedToReceive = {};

  bool _isVirtual = false; // false = Presencial, true = Virtual
  String? _errorMessage;
  bool _isLoading = false;
  bool _isProcessing = false;
  bool _hasScanned = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleCapture(BarcodeCapture capture, AppUser? currentUser) async {
    if (_hasScanned || currentUser == null) return;

    final rawValue = capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue;
    if (rawValue == null || rawValue.trim().isEmpty) return;

    setState(() {
      _hasScanned = true;
      _isLoading = true;
      _errorMessage = null;
    });
    await _scannerController.stop();
    await _processQrValue(rawValue, currentUser);
  }

  Future<void> _pickImage(AppUser currentUser) async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery);
    if (xfile == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final capture = await _scannerController.analyzeImage(xfile.path);
      if (capture == null || capture.barcodes.isEmpty || capture.barcodes.first.rawValue == null) {
        throw const FormatException('No se encontró un código QR válido en la imagen.');
      }
      
      final rawValue = capture.barcodes.first.rawValue!;
      await _processQrValue(rawValue, currentUser);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e is FormatException ? e.message : 'Error al analizar la imagen: ${e.toString()}';
        _isLoading = false;
        _hasScanned = false;
      });
    }
  }

  Future<void> _processQrValue(String rawValue, AppUser currentUser) async {
    try {
      final payload = UserQrPayload.fromEncoded(rawValue);
      if (payload.userId == currentUser.uid) {
        throw const FormatException('No puedes escanear tu propio código.');
      }

      // Fetch catalogs
      final catalog = await _stickersRepository.watchCatalog().first;
      final myStickers = await _stickersRepository.watchUserStickers(currentUser.uid).first;
      final otherStickers = await _stickersRepository.watchUserStickers(payload.userId).first;

      final iGive = <Sticker>[];
      final iReceive = <Sticker>[];

      for (final sticker in catalog) {
        final myQty = myStickers[sticker.id]?.quantity ?? 0;
        final myPasted = myStickers[sticker.id]?.isPasted ?? false;
        final otherQty = otherStickers[sticker.id]?.quantity ?? 0;
        final otherPasted = otherStickers[sticker.id]?.isPasted ?? false;

        // Yo doy: Yo tengo repetida (>0) y al otro le falta (!isPasted)
        if (myQty > 0 && !otherPasted) {
          iGive.add(sticker);
        }

        // Yo recibo: El otro tiene repetida (>0) y a mí me falta (!isPasted)
        if (otherQty > 0 && !myPasted) {
          iReceive.add(sticker);
        }
      }

      if (!mounted) return;
      setState(() {
        _scannedUser = payload;
        _iGive = iGive;
        _iReceive = iReceive;
        // Select all by default
        _selectedToGive.addAll(iGive.map((s) => s.id));
        _selectedToReceive.addAll(iReceive.map((s) => s.id));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e is FormatException ? e.message : 'Error al leer el código QR.';
        _hasScanned = false;
      });
      await _scannerController.start();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _executeExchange(AppUser currentUser) async {
    if (_selectedToGive.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tienes que ofrecer al menos una figurita')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      if (_isVirtual) {
        final offeredStickers = _iGive
            .where((s) => _selectedToGive.contains(s.id))
            .map((s) => TradeOfferSticker(sticker: s, quantity: 1))
            .toList();
            
        final requestedStickers = _iReceive
            .where((s) => _selectedToReceive.contains(s.id))
            .map((s) => TradeOfferSticker(sticker: s, quantity: 1))
            .toList();

        await _offersRepository.createDirectProposal(
          fromUserId: currentUser.uid,
          toUserId: _scannedUser!.userId,
          offeredStickers: offeredStickers,
          requestedStickers: requestedStickers,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Propuesta de intercambio virtual enviada.')),
        );
        Navigator.of(context).pop();
        // Opcional: Navegar a la pantalla de notificaciones o chat.
      } else {
        await _stickersRepository.executeDirectExchange(
          fromUserId: currentUser.uid,
          toUserId: _scannedUser!.userId,
          fromUserGivesIds: _selectedToGive.toList(),
          toUserGivesIds: _selectedToReceive.toList(),
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Intercambio presencial realizado con éxito!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: const Text('Escanear QR'),
        actions: [
          if (_scannedUser == null && user != null)
            IconButton(
              icon: const Icon(Icons.image_rounded),
              tooltip: 'Escanear desde Galería',
              onPressed: () => _pickImage(user),
            ),
        ],
      ),
      body: SafeArea(
        child: _scannedUser == null
            ? _buildScanner(user)
            : _buildMatchView(user!),
      ),
    );
  }

  Widget _buildScanner(AppUser? user) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              MobileScanner(
                controller: _scannerController,
                onDetect: (capture) => _handleCapture(capture, user),
              ),
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            image: DecorationImage(
              image: const AssetImage('assets/images/app_bg.png'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.6),
                BlendMode.darken,
              ),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Text(
            _errorMessage ?? 'Apunta la cámara al QR del otro coleccionista.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _errorMessage != null ? Colors.red[300] : Colors.white70,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMatchView(AppUser currentUser) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Intercambio con ${_scannedUser!.userName}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: 'Lo que vas a dar',
                subtitle: 'Tus repetidas que a él le faltan',
                stickers: _iGive,
                selectedSet: _selectedToGive,
                emptyMessage: 'No tienes figuritas que le falten.',
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: 'Lo que vas a recibir',
                subtitle: 'Sus repetidas que a ti te faltan',
                stickers: _iReceive,
                selectedSet: _selectedToReceive,
                emptyMessage: 'No tiene figuritas que te falten.',
              ),
              const SizedBox(height: 32),
              Text(
                'Modalidad de Intercambio',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isVirtual = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: !_isVirtual ? AppTheme.primaryBrand.withValues(alpha: 0.1) : Colors.transparent,
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                            border: const Border(right: BorderSide(color: Colors.white12)),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.handshake_rounded, 
                                color: !_isVirtual ? AppTheme.primaryBrand : Colors.white54),
                              const SizedBox(height: 4),
                              Text('Presencial', 
                                style: TextStyle(
                                  color: !_isVirtual ? AppTheme.primaryBrand : Colors.white54,
                                  fontWeight: FontWeight.bold,
                                )),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isVirtual = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: _isVirtual ? AppTheme.primaryBrand.withValues(alpha: 0.1) : Colors.transparent,
                            borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.chat_bubble_rounded, 
                                color: _isVirtual ? AppTheme.primaryBrand : Colors.white54),
                              const SizedBox(height: 4),
                              Text('Virtual', 
                                style: TextStyle(
                                  color: _isVirtual ? AppTheme.primaryBrand : Colors.white54,
                                  fontWeight: FontWeight.bold,
                                )),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_isVirtual)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Se creará una propuesta en notificaciones para chatear.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppTheme.bgDark,
            border: Border(top: BorderSide(color: Colors.white12)),
          ),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isProcessing ? null : () => _executeExchange(currentUser),
                  icon: _isProcessing 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : const Icon(Icons.check_circle_rounded, color: Colors.black),
                  label: Text(_isProcessing ? 'Procesando...' : 'Realizar Intercambio', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryBrand,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red[700],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('No se dio el intercambio', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required List<Sticker> stickers,
    required Set<String> selectedSet,
    required String emptyMessage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: Colors.white)),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70)),
        const SizedBox(height: 12),
        if (stickers.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Text(emptyMessage, style: const TextStyle(color: Colors.white54)),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: stickers.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white12),
              itemBuilder: (context, index) {
                final sticker = stickers[index];
                final isSelected = selectedSet.contains(sticker.id);
                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        selectedSet.add(sticker.id);
                      } else {
                        selectedSet.remove(sticker.id);
                      }
                    });
                  },
                  activeColor: AppTheme.primaryBrand,
                  checkColor: Colors.black,
                  title: Text(sticker.name, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                  subtitle: Text('${sticker.team} • ${sticker.catalogCode}', style: const TextStyle(color: Colors.white70)),
                  secondary: Container(
                    width: 40,
                    height: 56,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: AppTheme.bgDark,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: (sticker.imageUrl != null)
                        ? (sticker.imageUrl!.startsWith('http')
                            ? Image.network(
                                sticker.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 20, color: Colors.white24),
                              )
                            : Image.asset(
                                sticker.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 20, color: Colors.white24),
                              ))
                        : Center(
                            child: Text(
                              sticker.catalogCode,
                              style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
