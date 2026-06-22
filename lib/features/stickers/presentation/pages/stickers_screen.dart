import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:figugol/features/stickers/presentation/widgets/shared_album_widgets.dart';


import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../offers/presentation/controllers/trade_cart_controller.dart';
import '../../../offers/presentation/pages/trade_cart_screen.dart';
import '../../data/models/sticker.dart';
import '../controllers/stickers_controller.dart';

String _filterLabel(StickerFilter filter) {
  return switch (filter) {
    StickerFilter.all => 'Todas',
    StickerFilter.owned => 'Tengo',
    StickerFilter.duplicates => 'Repetidas',
    StickerFilter.missing => 'Me faltan',
  };
}


Color _accentTextColor(Color color) {
  return color.computeLuminance() > 0.55 ? AppTheme.lightText : color;
}

class StickersScreen extends StatelessWidget {
  final StickerFilter initialFilter;

  const StickersScreen({super.key, this.initialFilter = StickerFilter.all});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<StickersController>();
    if (controller.filter != initialFilter) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.setFilter(initialFilter);
      });
    }
    return const _StickersView();
  }
}

class _StickersView extends StatelessWidget {
  const _StickersView();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<StickersController>();
    final cart = context.watch<TradeCartController>();
    final stickers = controller.visibleStickers;
    final countriesList = controller.visibleSections.where((s) => s.id != StickersController.allSectionId).toList();

    _showErrorIfNeeded(context, controller);
    _showCartValidationIfNeeded(context, cart);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis figuritas'),
        actions: [
          if (controller.filter != StickerFilter.duplicates)
            _CartCounterButton(
              totalItems: cart.totalItems,
              onPressed: () {
                final stickersController = context.read<StickersController>();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ChangeNotifierProvider.value(
                      value: stickersController,
                      child: const TradeCartScreen(),
                    ),
                  ),
                );
              },
            ),
          if (controller.isSaving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
              ),
            ),
            if (!controller.isCatalogLoaded)
            const Expanded(
              child: Center(
                child: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: (controller.selectedSectionId != StickersController.allSectionId)
          ? FloatingActionButton.extended(
              heroTag: 'add_fab',
              onPressed: () {
                final selected = controller.selectedStickerIds;
                final listToAdd = selected.isEmpty
                    ? controller.visibleStickers
                    : controller.visibleStickers
                        .where((s) => selected.contains(s.id))
                        .toList();

                if (listToAdd.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No hay repetidas para agregar')),
                  );
                  return;
                }

                int added = 0;
                for (final sticker in listToAdd) {
                  final owned = controller.quantityFor(sticker.id);
                  if (cart.canAddSticker(stickerId: sticker.id, ownedQuantity: owned)) {
                    cart.addSticker(sticker: sticker, ownedQuantity: owned);
                    added++;
                  }
                }

                if (added > 0) {
                  controller.clearSelection();
                }

                final stickersController = context.read<StickersController>();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ChangeNotifierProvider.value(
                      value: stickersController,
                      child: const TradeCartScreen(),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.swap_horiz_rounded),
              label: Text(
                controller.selectedStickerIds.isEmpty
                    ? 'Agregar al Intercambio'
                    : 'Agregar seleccionadas al Intercambio',
              ),
            )
          : null,
      body: !controller.isCatalogLoaded
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
            if (!controller.hasRegisteredStickers)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _StickerEmptyBanner(),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: CountrySearchField(onChanged: controller.setSearchQuery),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
              child: Row(
                children: [
                  Expanded(
                    child: AlbumSections(
                      sections: controller.visibleSections,
                      selectedSectionId: controller.selectedSectionId,
                      onChanged: controller.setSection,
                    ),
                  ),
                ],
              ),
            ),
            if (controller.selectedSectionId != StickersController.allSectionId || controller.filter != StickerFilter.all)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                child: _SelectedFilterSummary(
                  section: controller.selectedSection,
                  selectedFilter: controller.filter,
                ),
              ),
            Expanded(
              child: (controller.selectedSectionId == StickersController.allSectionId && controller.searchQuery.isEmpty)
                ? countriesList.isEmpty
                    ? const Center(child: Text('No se encontraron países.'))
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 200,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.1,
                        ),
                        itemCount: countriesList.length,
                        itemBuilder: (context, index) {
                          final section = countriesList[index];
                          return CountryCard(
                            section: section,
                            onTap: () => controller.setSection(section.id),
                          );
                        },
                      )
                : stickers.isEmpty
                  ? const _StickerFilterEmptyState()
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 190,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.48,
                          ),
                      itemCount: stickers.length,
                      itemBuilder: (context, index) {
                        final sticker = stickers[index];
                        return _StickerCard(
                          sticker: sticker,
                          quantity: controller.quantityFor(sticker.id),
                          cartQuantity: cart.quantityFor(sticker.id),
                          section: controller.sectionForTeam(sticker.team),
                          isSelected: controller.isSelected(sticker.id),
                          onTap: () => controller.toggleSelected(sticker.id),
                          onIncrement: () =>
                              controller.incrementQuantity(sticker.id),
                          onDecrement: () =>
                              controller.decrementQuantity(sticker.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorIfNeeded(BuildContext context, StickersController controller) {
    final message = controller.errorMessage;
    if (message == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      controller.clearError();
    });
  }

  void _showCartValidationIfNeeded(
    BuildContext context,
    TradeCartController cart,
  ) {
    final message = cart.validationMessage;
    if (message == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      cart.clearValidationMessage();
    });
  }
}

class _StickerEmptyBanner extends StatelessWidget {
  const _StickerEmptyBanner();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.cardDark,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.style_rounded, color: Color(0xFFD97706)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Aún no registraste figuritas. Toca + en una card para sumar.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightText,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StickerFilterEmptyState extends StatelessWidget {
  const _StickerFilterEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No hay figuritas para este filtro.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _CartCounterButton extends StatelessWidget {
  const _CartCounterButton({required this.totalItems, required this.onPressed});

  final int totalItems;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Ver carrito de intercambio',
      onPressed: onPressed,
      icon: Badge(
        isLabelVisible: totalItems > 0,
        label: Text('$totalItems'),
        child: const Icon(Icons.shopping_basket_rounded),
      ),
    );
  }
}

class _StickerFilterMenu extends StatelessWidget {
  const _StickerFilterMenu({
    required this.selectedFilter,
    required this.onChanged,
  });

  final StickerFilter selectedFilter;
  final ValueChanged<StickerFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<StickerFilter>(
      tooltip: 'Filtrar figuritas',
      initialValue: selectedFilter,
      onSelected: onChanged,
      position: PopupMenuPosition.under,
      icon: const Icon(Icons.more_vert_rounded),
      itemBuilder: (context) => [
        _filterItem(StickerFilter.all, 'Todas'),
        _filterItem(StickerFilter.owned, 'Tengo'),
        _filterItem(StickerFilter.duplicates, 'Repetidas'),
        _filterItem(StickerFilter.missing, 'Me faltan'),
      ],
    );
  }

  PopupMenuItem<StickerFilter> _filterItem(StickerFilter filter, String label) {
    return PopupMenuItem<StickerFilter>(
      value: filter,
      child: Row(
        children: [
          Icon(
            selectedFilter == filter
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 18,
          ),
          const SizedBox(width: 10),
          Text(label),
        ],
      ),
    );
  }
}

class _SelectedFilterSummary extends StatelessWidget {
  const _SelectedFilterSummary({
    required this.section,
    required this.selectedFilter,
  });

  final StickerAlbumSection section;
  final StickerFilter selectedFilter;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        section.flagAsset != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.asset(
                  section.flagAsset!,
                  width: 36,
                  height: 20,
                  fit: BoxFit.cover,
                ),
              )
            : _FlagStrip(
                primaryColor: section.primaryColor,
                secondaryColor: section.secondaryColor,
              ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${section.label} - ${_filterLabel(selectedFilter)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _FlagStrip extends StatelessWidget {
  const _FlagStrip({required this.primaryColor, required this.secondaryColor});

  final Color primaryColor;
  final Color secondaryColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        width: 36,
        height: 8,
        child: Row(
          children: [
            Expanded(child: ColoredBox(color: primaryColor)),
            Expanded(child: ColoredBox(color: secondaryColor)),
          ],
        ),
      ),
    );
  }
}

class _StickerCard extends StatelessWidget {
  const _StickerCard({
    required this.sticker,
    required this.quantity,
    required this.cartQuantity,
    required this.section,
    required this.isSelected,
    required this.onTap,
    required this.onIncrement,
    required this.onDecrement,
  });

  final Sticker sticker;
  final int quantity;
  final int cartQuantity;
  final StickerAlbumSection section;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  bool get _isMissing => quantity == 0;

  @override
  Widget build(BuildContext context) {
    final countryTextColor = _accentTextColor(section.primaryColor);

    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onIncrement,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: _isMissing
              ? Color.alphaBlend(
                  section.primaryColor.withAlpha(20),
                  AppTheme.cardDark,
                )
              : AppTheme.cardDark,
          image: DecorationImage(
            image: const AssetImage('assets/images/app_bg.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: _isMissing ? 0.75 : 0.6),
              BlendMode.darken,
            ),
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? section.secondaryColor : AppTheme.borderLine,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: GestureDetector(
                onDoubleTap: () {}, // Swallow double tap to prevent triggering the card's increment
                child: Row(
                  children: [
                    const Spacer(),
                  IconButton.filled(
                    tooltip: 'Sumar figurita',
                    onPressed: onIncrement,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    constraints: const BoxConstraints.tightFor(
                      width: 32,
                      height: 32,
                    ),
                    padding: EdgeInsets.zero,
                    style: IconButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton.filled(
                    tooltip: 'Restar figurita',
                    onPressed: quantity == 0 ? null : onDecrement,
                    icon: const Icon(Icons.remove_rounded, size: 18),
                    constraints: const BoxConstraints.tightFor(
                      width: 32,
                      height: 32,
                    ),
                    padding: EdgeInsets.zero,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: sticker.imageUrl != null && sticker.imageUrl!.startsWith('http')
                  ? Image.network(
                      sticker.imageUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                    )
                  : sticker.imageUrl != null
                      ? Image.asset(sticker.imageUrl!, fit: BoxFit.contain)
                      : const Center(child: Icon(Icons.image_not_supported, color: Colors.grey)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _QuantityBadge(
                    quantity: quantity,
                    color: section.primaryColor,
                    textColor: countryTextColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _QuantityBadge extends StatelessWidget {
  const _QuantityBadge({
    required this.quantity,
    required this.color,
    required this.textColor,
  });

  final int quantity;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final isMissing = quantity == 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF4B5563), // Lighter tone for missing or present
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        isMissing ? 'Faltante' : 'Cantidad: $quantity',
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Colors.white70,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

