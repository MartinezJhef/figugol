import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/models/sticker.dart';
import '../controllers/stickers_controller.dart';
import '../widgets/shared_album_widgets.dart';

class AlbumScreen extends StatelessWidget {
  const AlbumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AlbumView();
  }
}

class _AlbumView extends StatefulWidget {
  const _AlbumView();

  @override
  State<_AlbumView> createState() => _AlbumViewState();
}

class _AlbumViewState extends State<_AlbumView> {
  @override
  Widget build(BuildContext context) {
    final controller = context.watch<StickersController>();
    
    if (!controller.isCatalogLoaded) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mi Álbum')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final countriesList = controller.visibleSections
        .where((s) => s.id != StickersController.allSectionId)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Álbum'),
      ),
      body: Column(
        children: [
          // Banner Instructivo
          Container(
            width: double.infinity,
            color: AppTheme.primaryBrand.withValues(alpha: 0.1),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.primaryBrand, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Haz doble tap para pegar o despegar tus figuritas',
                    style: TextStyle(color: AppTheme.primaryBrand, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: CountrySearchField(onChanged: controller.setSearchQuery),
          ),
          if (controller.selectedSectionId != StickersController.allSectionId || controller.filter != StickerFilter.all)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      controller.setSection(StickersController.allSectionId);
                      controller.setFilter(StickerFilter.all);
                    },
                    tooltip: 'Volver',
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      controller.selectedSectionId == StickersController.allSectionId
                          ? _getFilterLabel(controller.filter)
                          : controller.selectedSection.label,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: (controller.selectedSectionId == StickersController.allSectionId && controller.searchQuery.isEmpty && controller.filter == StickerFilter.all)
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
                          isFullImage: true,
                        );
                      },
                    )
              : controller.visibleStickers.isEmpty
                ? const Center(child: Text('No se encontraron figuritas.'))
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: controller.visibleStickers.length,
                    itemBuilder: (context, index) {
                      final sticker = controller.visibleStickers[index];
                      final section = controller.sectionForTeam(sticker.team);
                      return _AlbumSlot(
                        sticker: sticker,
                        controller: controller,
                        section: section,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _AlbumSlot extends StatelessWidget {
  const _AlbumSlot({
    required this.sticker,
    required this.controller,
    required this.section,
  });

  final Sticker sticker;
  final StickersController controller;
  final StickerAlbumSection section;

  @override
  Widget build(BuildContext context) {
    final isPasted = controller.isPasted(sticker.id);
    final canPaste = !isPasted;

    return GestureDetector(
      onDoubleTap: () => controller.togglePasteSticker(sticker.id),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: canPaste ? section.primaryColor : Colors.white12,
            width: canPaste ? 2 : 1,
          ),
          boxShadow: canPaste
              ? [
                  BoxShadow(
                    color: section.primaryColor.withValues(alpha: 0.5),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image/Number
            if (isPasted && sticker.imageUrl != null && sticker.imageUrl!.startsWith('http'))
              Image.network(
                sticker.imageUrl!,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image, color: Colors.white24, size: 48),
                ),
              )
            else if (isPasted && sticker.imageUrl != null)
              Image.asset(
                sticker.imageUrl!,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image, color: Colors.white24, size: 48),
                ),
              )
            else ...[
              // Placeholder when not pasted
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        sticker.catalogCode,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white24,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sticker.name,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white24,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _getFilterLabel(StickerFilter filter) {
  switch (filter) {
    case StickerFilter.owned:
      return 'Mis Figuritas Pegadas';
    case StickerFilter.duplicates:
      return 'Mis Repetidas';
    case StickerFilter.missing:
      return 'Figuritas Faltantes';
    case StickerFilter.all:
      return 'Todas las Figuritas';
  }
}
