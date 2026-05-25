import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

Color _readableTextColor(Color color) {
  return color.computeLuminance() > 0.55 ? AppTheme.ink : Colors.white;
}

Color _accentTextColor(Color color) {
  return color.computeLuminance() > 0.55 ? AppTheme.ink : color;
}

class StickersScreen extends StatelessWidget {
  const StickersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.select<AuthController, String?>(
      (controller) => controller.user?.uid,
    );

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Inicia sesión para ver tus figuritas.')),
      );
    }

    return ChangeNotifierProvider(
      create: (_) => StickersController(userId: userId),
      child: const _StickersView(),
    );
  }
}

class _StickersView extends StatelessWidget {
  const _StickersView();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<StickersController>();
    final cart = context.watch<TradeCartController>();
    final stickers = controller.visibleStickers;

    _showErrorIfNeeded(context, controller);
    _showCartValidationIfNeeded(context, cart);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis figuritas'),
        actions: [
          _CartCounterButton(
            totalItems: cart.totalItems,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const TradeCartScreen(),
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
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (!controller.hasRegisteredStickers)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _StickerEmptyBanner(),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _CountrySearchField(onChanged: controller.setCountryQuery),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
              child: Row(
                children: [
                  Expanded(
                    child: _AlbumSections(
                      sections: controller.visibleSections,
                      selectedSectionId: controller.selectedSectionId,
                      onChanged: controller.setSection,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StickerFilterMenu(
                    selectedFilter: controller.filter,
                    onChanged: controller.setFilter,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: _SelectedFilterSummary(
                section: controller.selectedSection,
                selectedFilter: controller.filter,
              ),
            ),
            Expanded(
              child: stickers.isEmpty
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
                          onDoubleTap: () =>
                              controller.incrementQuantity(sticker.id),
                          onDecrement: () =>
                              controller.decrementQuantity(sticker.id),
                          onAddToTrade: () {
                            cart.addSticker(
                              sticker: sticker,
                              ownedQuantity: controller.quantityFor(sticker.id),
                            );
                          },
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
      color: const Color(0xFFFFF4D2),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.style_rounded, color: Color(0xFF7A5A00)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Aún no registraste figuritas. Toca + en una card para sumar.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.ink,
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

class _CountrySearchField extends StatelessWidget {
  const _CountrySearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: const InputDecoration(
        hintText: 'Buscar país',
        prefixIcon: Icon(Icons.search_rounded),
      ),
    );
  }
}

class _AlbumSections extends StatelessWidget {
  const _AlbumSections({
    required this.sections,
    required this.selectedSectionId,
    required this.onChanged,
  });

  final List<StickerAlbumSection> sections;
  final String selectedSectionId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) {
      return const Center(child: Text('No se encontró ese país.'));
    }

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: sections.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final section = sections[index];
          final isSelected = section.id == selectedSectionId;
          return _AlbumSectionChip(
            section: section,
            isSelected: isSelected,
            onTap: () => onChanged(section.id),
          );
        },
      ),
    );
  }
}

class _AlbumSectionChip extends StatelessWidget {
  const _AlbumSectionChip({
    required this.section,
    required this.isSelected,
    required this.onTap,
  });

  final StickerAlbumSection section;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = _readableTextColor(section.primaryColor);

    return ActionChip(
      onPressed: onTap,
      side: BorderSide(
        color: isSelected ? section.secondaryColor : AppTheme.line,
        width: isSelected ? 2 : 1,
      ),
      backgroundColor: isSelected ? section.primaryColor : Colors.white,
      avatar: _FlagDots(
        primaryColor: section.primaryColor,
        secondaryColor: section.secondaryColor,
      ),
      label: Text(section.label, maxLines: 1, overflow: TextOverflow.ellipsis),
      labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: isSelected ? textColor : AppTheme.ink,
        fontWeight: FontWeight.w900,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}

class _FlagDots extends StatelessWidget {
  const _FlagDots({required this.primaryColor, required this.secondaryColor});

  final Color primaryColor;
  final Color secondaryColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.line),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: secondaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.4),
              ),
            ),
          ),
        ],
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
        _FlagStrip(
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
              color: const Color(0xFF5D6F66),
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
    required this.onDoubleTap,
    required this.onDecrement,
    required this.onAddToTrade,
  });

  final Sticker sticker;
  final int quantity;
  final int cartQuantity;
  final StickerAlbumSection section;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final VoidCallback onDecrement;
  final VoidCallback onAddToTrade;

  bool get _isMissing => quantity == 0;
  bool get _canAddToTrade => quantity > 1 && cartQuantity < quantity - 1;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final countryTextColor = _accentTextColor(section.primaryColor);

    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _isMissing
              ? Color.alphaBlend(
                  section.primaryColor.withAlpha(20),
                  Colors.white,
                )
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? section.secondaryColor : AppTheme.line,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StickerNumber(
                  code: sticker.catalogCode,
                  color: section.secondaryColor,
                ),
                const Spacer(),
                IconButton.filled(
                  tooltip: 'Sumar figurita',
                  onPressed: onDoubleTap,
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
                IconButton.filledTonal(
                  tooltip: 'Restar figurita',
                  onPressed: quantity == 0 ? null : onDecrement,
                  icon: const Icon(Icons.remove_rounded, size: 18),
                  constraints: const BoxConstraints.tightFor(
                    width: 32,
                    height: 32,
                  ),
                  padding: EdgeInsets.zero,
                  style: IconButton.styleFrom(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: sticker.imageUrl == null
                  ? Align(
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.style_rounded,
                        color: _isMissing
                            ? const Color(0xFF8A968F)
                            : section.primaryColor,
                        size: 46,
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        sticker.imageUrl!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Icon(
                          Icons.broken_image_outlined,
                          color: section.primaryColor,
                          size: 46,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 10),
            Text(
              sticker.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleSmall?.copyWith(
                color: AppTheme.ink,
                fontWeight: FontWeight.w900,
                height: 1.12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              section.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                color: const Color(0xFF5D6F66),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            _QuantityBadge(
              quantity: quantity,
              color: section.primaryColor,
              textColor: countryTextColor,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _canAddToTrade ? onAddToTrade : null,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                child: const Text('Agregar al intercambio'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StickerNumber extends StatelessWidget {
  const _StickerNumber({required this.code, required this.color});

  final String code;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        code,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: _accentTextColor(color),
          fontWeight: FontWeight.w900,
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
        color: isMissing
            ? const Color(0xFFDCE2DD)
            : Color.alphaBlend(color.withAlpha(41), Colors.white),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isMissing ? 'Faltante' : 'Cantidad: $quantity',
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: isMissing ? const Color(0xFF5D6F66) : textColor,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
