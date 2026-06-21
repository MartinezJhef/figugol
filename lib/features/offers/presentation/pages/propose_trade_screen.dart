import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/models/trade_offer.dart';
import '../../data/repositories/trade_offers_repository.dart';
import '../../../stickers/data/repositories/stickers_repository.dart';
import '../../../stickers/data/models/sticker.dart';

class ProposeTradeScreen extends StatefulWidget {
  const ProposeTradeScreen({
    required this.offer,
    super.key,
  });

  final TradeOffer offer;

  @override
  State<ProposeTradeScreen> createState() => _ProposeTradeScreenState();
}

class _ProposeTradeScreenState extends State<ProposeTradeScreen> {
  final _offersRepository = TradeOffersRepository();
  final _stickersRepository = StickersRepository();

  final Set<String> _selectedOfferedIds = {};
  // Map of requested sticker ID to quantity desired
  final Map<String, int> _requestedQuantities = {};
  
  bool _isSubmitting = false;
  List<Sticker> _myDuplicates = [];
  bool _isLoadingDuplicates = true;

  @override
  void initState() {
    super.initState();
    // Initialize requested quantities to 1 (or 0 if they don't want it initially, let's start with 1 for all to make it easier, but allow them to decrease to 0)
    for (final item in widget.offer.stickersOffered) {
      _requestedQuantities[item.sticker.id] = 1;
    }
    _loadMyDuplicates();
  }

  Future<void> _loadMyDuplicates() async {
    final user = context.read<AuthController>().user;
    if (user == null) return;
    
    // For simplicity, we just listen to the first event of the stream
    final userStickersMap = await _stickersRepository.watchUserStickers(user.uid).first;
    final catalog = await _stickersRepository.watchCatalog().first;
    final duplicates = <Sticker>[];
    
    for (final sticker in catalog) {
      final userSticker = userStickersMap[sticker.id];
      if (userSticker != null && userSticker.quantity > 0) {
        duplicates.add(sticker);
      }
    }

    if (mounted) {
      setState(() {
        _myDuplicates = duplicates;
        _isLoadingDuplicates = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Proponer intercambio')),
      body: SafeArea(
        child: _isLoadingDuplicates 
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Elige tus duplicadas para ofrecer',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.lightText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                if (_myDuplicates.isEmpty)
                  const _EmptySelectionMessage(
                    text: 'No tienes figuritas duplicadas disponibles.',
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.65,
                    ),
                    itemCount: _myDuplicates.length,
                    itemBuilder: (context, index) {
                      final sticker = _myDuplicates[index];
                      final isSelected = _selectedOfferedIds.contains(sticker.id);

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedOfferedIds.remove(sticker.id);
                            } else {
                              _selectedOfferedIds.add(sticker.id);
                            }
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.cardDark,
                            image: DecorationImage(
                              image: const AssetImage('assets/images/app_bg.png'),
                              fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(
                                Colors.black.withValues(alpha: 0.6),
                                BlendMode.darken,
                              ),
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? AppTheme.primaryBrand : AppTheme.borderLine,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x12000000),
                                blurRadius: 14,
                                offset: Offset(0, 7),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Checkbox(
                                      value: isSelected,
                                      onChanged: (value) {
                                        setState(() {
                                          if (value ?? false) {
                                            _selectedOfferedIds.add(sticker.id);
                                          } else {
                                            _selectedOfferedIds.remove(sticker.id);
                                          }
                                        });
                                      },
                                      activeColor: AppTheme.primaryBrand,
                                      side: const BorderSide(color: AppTheme.lightText),
                                    ),
                                  ],
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                    child: sticker.imageUrl != null && sticker.imageUrl!.startsWith('http')
                                        ? Image.network(
                                            sticker.imageUrl!,
                                            fit: BoxFit.contain,
                                            errorBuilder: (_, __, ___) => const Center(
                                                child: Icon(Icons.broken_image, color: Colors.white24)),
                                          )
                                        : sticker.imageUrl != null
                                            ? Image.asset(sticker.imageUrl!, fit: BoxFit.contain)
                                            : const Center(
                                                child: Icon(Icons.image_not_supported, color: Colors.white24),
                                              ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 32),
                Text(
                  'Elige las figuritas que solicitas',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.lightText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.65,
                  ),
                  itemCount: widget.offer.stickersOffered.length,
                  itemBuilder: (context, index) {
                    final item = widget.offer.stickersOffered[index];
                    final currentQty = _requestedQuantities[item.sticker.id] ?? 0;
                    final maxQty = item.quantity;
                    
                    return Container(
                      decoration: BoxDecoration(
                        color: AppTheme.cardDark,
                        image: DecorationImage(
                          image: const AssetImage('assets/images/app_bg.png'),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Colors.black.withValues(alpha: 0.6),
                            BlendMode.darken,
                          ),
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.borderLine, width: 1),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x12000000),
                            blurRadius: 14,
                            offset: Offset(0, 7),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                                child: item.sticker.imageUrl != null && item.sticker.imageUrl!.startsWith('http')
                                    ? Image.network(
                                        item.sticker.imageUrl!,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) => const Center(
                                            child: Icon(Icons.broken_image, color: Colors.white24)),
                                      )
                                    : item.sticker.imageUrl != null
                                        ? Image.asset(item.sticker.imageUrl!, fit: BoxFit.contain)
                                        : const Center(
                                            child: Icon(Icons.image_not_supported, color: Colors.white24),
                                          ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: currentQty > 0
                                        ? () => setState(() {
                                              _requestedQuantities[item.sticker.id] = currentQty - 1;
                                            })
                                        : null,
                                    icon: const Icon(Icons.remove_circle_outline, size: 24),
                                    color: AppTheme.lightText,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$currentQty / $maxQty',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryBrand,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: currentQty < maxQty
                                        ? () => setState(() {
                                              _requestedQuantities[item.sticker.id] = currentQty + 1;
                                            })
                                        : null,
                                    icon: const Icon(Icons.add_circle_outline, size: 24),
                                    color: AppTheme.lightText,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
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

  bool get _canSubmit {
    if (_isSubmitting) return false;
    if (_selectedOfferedIds.isEmpty) return false;
    
    // Check if at least one requested sticker has quantity > 0
    final hasRequestedStickers = _requestedQuantities.values.any((qty) => qty > 0);
    if (!hasRequestedStickers) return false;
    
    return true;
  }

  Future<void> _submitProposal() async {
    final user = context.read<AuthController>().user;
    if (user == null) {
      return;
    }

    setState(() => _isSubmitting = true);
    
    final offered = _myDuplicates
        .where((sticker) => _selectedOfferedIds.contains(sticker.id))
        .map((sticker) => TradeOfferSticker(sticker: sticker, quantity: 1))
        .toList();
        
    final requested = widget.offer.stickersOffered
        .where((item) => (_requestedQuantities[item.sticker.id] ?? 0) > 0)
        .map((item) => TradeOfferSticker(
              sticker: item.sticker, 
              quantity: _requestedQuantities[item.sticker.id]!,
            ))
        .toList();

    try {
      await _offersRepository.createProposal(
        offerId: widget.offer.id,
        fromUserId: user.uid,
        toUserId: widget.offer.ownerId,
        offeredStickers: offered,
        requestedStickers: requested,
      );
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tu propuesta fue enviada.')),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      final message = error is TradeOfferException
          ? error.message
          : 'No se pudo enviar la propuesta. Inténtalo nuevamente.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderLine),
      ),
      child: Text(text, style: const TextStyle(color: AppTheme.lightText)),
    );
  }
}
