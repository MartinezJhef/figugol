import 'package:flutter/material.dart';
import 'package:figugol/core/theme/app_theme.dart';
import 'package:figugol/features/stickers/presentation/controllers/stickers_controller.dart';

Color readableTextColor(Color color) {
  return color.computeLuminance() > 0.55 ? AppTheme.lightText : Colors.white;
}

class CountrySearchField extends StatelessWidget {
  const CountrySearchField({super.key, required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLine),
      ),
      child: TextField(
        onChanged: onChanged,
        decoration: const InputDecoration(
          hintText: 'Buscar país, equipo o jugador...',
          hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}

class AlbumSections extends StatelessWidget {
  const AlbumSections({
    super.key,
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
          return AlbumSectionChip(
            section: section,
            isSelected: isSelected,
            onTap: () => onChanged(section.id),
          );
        },
      ),
    );
  }
}

class AlbumSectionChip extends StatelessWidget {
  const AlbumSectionChip({
    super.key,
    required this.section,
    required this.isSelected,
    required this.onTap,
  });

  final StickerAlbumSection section;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      side: BorderSide(
        color: isSelected ? AppTheme.primaryBrand : AppTheme.borderLine,
        width: isSelected ? 2 : 1,
      ),
      backgroundColor: isSelected ? AppTheme.primaryBrand : AppTheme.cardDark,
      avatar: section.flagAsset != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.asset(
                section.flagAsset!,
                width: 24,
                height: 18,
                fit: BoxFit.cover,
              ),
            )
          : FlagDots(
              primaryColor: section.primaryColor,
              secondaryColor: section.secondaryColor,
            ),
      label: Text(section.label, maxLines: 1, overflow: TextOverflow.ellipsis),
      labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: isSelected ? Colors.black87 : AppTheme.lightText,
        fontWeight: FontWeight.w900,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}

class FlagDots extends StatelessWidget {
  const FlagDots({super.key, required this.primaryColor, required this.secondaryColor});

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
                border: Border.all(color: AppTheme.borderLine),
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
                border: Border.all(color: AppTheme.cardDark, width: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CountryCard extends StatelessWidget {
  const CountryCard({
    super.key,
    required this.section,
    required this.onTap,
    this.isFullImage = false,
  });

  final StickerAlbumSection section;
  final VoidCallback onTap;
  final bool isFullImage;

  @override
  Widget build(BuildContext context) {
    final textColor = readableTextColor(section.primaryColor);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: section.primaryColor,
          image: isFullImage
              ? null
              : DecorationImage(
                  image: const AssetImage('assets/images/app_bg.png'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.6),
                    BlendMode.darken,
                  ),
                ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderLine),
          boxShadow: [
            BoxShadow(
              color: section.primaryColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: isFullImage
                  ? (section.flagAsset == null
                      ? Center(
                          child: FlagDotsLarge(
                            primaryColor: section.primaryColor,
                            secondaryColor: section.secondaryColor,
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage(section.flagAsset!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ))
                  : Center(
                      child: section.flagAsset != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                section.flagAsset!,
                                width: 72,
                                height: 54,
                                fit: BoxFit.cover,
                              ),
                            )
                          : FlagDotsLarge(
                              primaryColor: section.primaryColor,
                              secondaryColor: section.secondaryColor,
                            ),
                    ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Text(
                section.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FlagDotsLarge extends StatelessWidget {
  const FlagDotsLarge({super.key, required this.primaryColor, required this.secondaryColor});

  final Color primaryColor;
  final Color secondaryColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.cardDark, width: 2),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: secondaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.cardDark, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
