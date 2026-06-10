import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/services/connectivity_service.dart';
import '../../data/models/sticker.dart';
import '../../data/models/user_sticker.dart';
import '../../data/repositories/stickers_repository.dart';
import '../../data/sources/demo_sticker_catalog.dart';

enum StickerFilter { all, owned, duplicates, missing }

class StickerAlbumSection {
  const StickerAlbumSection({
    required this.id,
    required this.label,
    required this.primaryColor,
    required this.secondaryColor,
    this.team,
  });

  final String id;
  final String label;
  final Color primaryColor;
  final Color secondaryColor;
  final String? team;
}

class StickersController extends ChangeNotifier {
  StickersController({
    required this.userId,
    StickersRepository? stickersRepository,
  }) : _stickersRepository = stickersRepository ?? StickersRepository() {
    _subscription = _stickersRepository
        .watchUserStickers(userId)
        .listen(
          (userStickers) {
            final mergedStickers = {...userStickers};
            for (final stickerId in _pendingSaveCounts.keys) {
              final localSticker = _userStickers[stickerId];
              if (localSticker != null) {
                mergedStickers[stickerId] = localSticker;
              }
            }
            _userStickers = mergedStickers;
            _errorMessage = null;
            notifyListeners();
          },
          onError: (_) {
            _errorMessage = 'No se pudieron cargar tus figuritas.';
            notifyListeners();
          },
        );
  }

  final String userId;
  final StickersRepository _stickersRepository;
  StreamSubscription<Map<String, UserSticker>>? _subscription;

  final List<Sticker> stickers = demoStickerCatalog;
  static const allSectionId = 'all';
  static const sections = <StickerAlbumSection>[
    StickerAlbumSection(
      id: allSectionId,
      label: 'Torneo mundial',
      primaryColor: Color(0xFF006847),
      secondaryColor: Color(0xFF0A369D),
    ),
    StickerAlbumSection(
      id: 'mexico',
      label: 'México',
      team: 'Mexico',
      primaryColor: Color(0xFF006847),
      secondaryColor: Color(0xFFCE1126),
    ),
    StickerAlbumSection(
      id: 'uruguay',
      label: 'Uruguay',
      team: 'Uruguay',
      primaryColor: Color(0xFF5BC2E7),
      secondaryColor: Color(0xFFFFD100),
    ),
    StickerAlbumSection(
      id: 'uzbekistan',
      label: 'Uzbekistán',
      team: 'Uzbekistan',
      primaryColor: Color(0xFF0099B5),
      secondaryColor: Color(0xFF1EB53A),
    ),
    StickerAlbumSection(
      id: 'canada',
      label: 'Canada',
      team: 'Equipo Costero',
      primaryColor: Color(0xFFD52B1E),
      secondaryColor: Color(0xFFFFFFFF),
    ),
    StickerAlbumSection(
      id: 'estados_unidos',
      label: 'Estados Unidos',
      team: 'Equipo Selva',
      primaryColor: Color(0xFF3C3B6E),
      secondaryColor: Color(0xFFB22234),
    ),
    StickerAlbumSection(
      id: 'argentina',
      label: 'Argentina',
      team: 'Equipo Austral',
      primaryColor: Color(0xFF75AADB),
      secondaryColor: Color(0xFFFFFFFF),
    ),
    StickerAlbumSection(
      id: 'brasil',
      label: 'Brasil',
      team: 'Equipo Norte',
      primaryColor: Color(0xFF009B3A),
      secondaryColor: Color(0xFFFFDF00),
    ),
    StickerAlbumSection(
      id: 'espana',
      label: 'Espana',
      team: 'Equipo Plata',
      primaryColor: Color(0xFFAA151B),
      secondaryColor: Color(0xFFF1BF00),
    ),
    StickerAlbumSection(
      id: 'francia',
      label: 'Francia',
      team: 'Equipo Dorado',
      primaryColor: Color(0xFF0055A4),
      secondaryColor: Color(0xFFEF4135),
    ),
    StickerAlbumSection(
      id: 'inglaterra',
      label: 'Inglaterra',
      team: 'Equipo Oceano',
      primaryColor: Color(0xFFFFFFFF),
      secondaryColor: Color(0xFFC8102E),
    ),
    StickerAlbumSection(
      id: 'alemania',
      label: 'Alemania',
      team: 'Equipo Capital',
      primaryColor: Color(0xFF000000),
      secondaryColor: Color(0xFFFFCC00),
    ),
    StickerAlbumSection(
      id: 'japon',
      label: 'Japon',
      team: 'Equipo Granate',
      primaryColor: Color(0xFFFFFFFF),
      secondaryColor: Color(0xFFBC002D),
    ),
  ];

  Map<String, UserSticker> _userStickers = const {};
  final Set<String> _selectedStickerIds = {};
  StickerFilter _filter = StickerFilter.all;
  String _selectedSectionId = allSectionId;
  String _countryQuery = '';
  String? _errorMessage;
  int _savingOperations = 0;
  final Map<String, int> _pendingSaveCounts = {};

  StickerFilter get filter => _filter;
  String get selectedSectionId => _selectedSectionId;
  StickerAlbumSection get selectedSection => sections.firstWhere(
    (section) => section.id == _selectedSectionId,
    orElse: () => sections.first,
  );
  List<StickerAlbumSection> get visibleSections {
    final query = _countryQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return sections;
    }
    return sections.where((section) {
      return section.label.toLowerCase().contains(query);
    }).toList();
  }

  String? get errorMessage => _errorMessage;
  bool get isSaving => _savingOperations > 0;
  bool get hasLoadedCollection => _userStickers.isNotEmpty;
  bool get hasRegisteredStickers =>
      _userStickers.values.any((sticker) => sticker.quantity > 0);

  List<Sticker> get visibleStickers {
    return stickers.where((sticker) {
      final quantity = quantityFor(sticker.id);
      final sectionMatches =
          selectedSection.team == null || selectedSection.team == sticker.team;
      return switch (_filter) {
        StickerFilter.all => sectionMatches,
        StickerFilter.owned => sectionMatches && quantity > 0,
        StickerFilter.duplicates => sectionMatches && quantity > 1,
        StickerFilter.missing => sectionMatches && quantity == 0,
      };
    }).toList();
  }

  int quantityFor(String stickerId) {
    return _userStickers[stickerId]?.quantity ?? 0;
  }

  bool isSelected(String stickerId) => _selectedStickerIds.contains(stickerId);

  void setFilter(StickerFilter filter) {
    _filter = filter;
    notifyListeners();
  }

  void setSection(String sectionId) {
    _selectedSectionId = sectionId;
    notifyListeners();
  }

  void setCountryQuery(String query) {
    _countryQuery = query;
    notifyListeners();
  }

  StickerAlbumSection sectionForTeam(String team) {
    return sections.firstWhere(
      (section) => section.team == team,
      orElse: () => sections.first,
    );
  }

  void toggleSelected(String stickerId) {
    if (!_selectedStickerIds.add(stickerId)) {
      _selectedStickerIds.remove(stickerId);
    }
    notifyListeners();
  }

  Future<void> incrementQuantity(String stickerId) async {
    await _saveQuantity(stickerId, quantityFor(stickerId) + 1);
  }

  Future<void> decrementQuantity(String stickerId) async {
    final currentQuantity = quantityFor(stickerId);
    if (currentQuantity == 0) {
      return;
    }
    await _saveQuantity(stickerId, currentQuantity - 1);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _saveQuantity(String stickerId, int quantity) async {
    final nextQuantity = quantity < 0 ? 0 : quantity;
    final previousSticker = _userStickers[stickerId];
    final now = DateTime.now();
    final nextSticker = UserSticker(
      userId: userId,
      stickerId: stickerId,
      quantity: nextQuantity,
      updatedAt: now,
    );

    _userStickers = {..._userStickers, stickerId: nextSticker};
    _savingOperations += 1;
    _pendingSaveCounts[stickerId] = (_pendingSaveCounts[stickerId] ?? 0) + 1;
    notifyListeners();

    try {
      await _stickersRepository.saveUserSticker(nextSticker);
      _errorMessage = null;
    } catch (error) {
      final restoredStickers = {..._userStickers};
      if (previousSticker == null) {
        restoredStickers.remove(stickerId);
      } else {
        restoredStickers[stickerId] = previousSticker;
      }
      _userStickers = restoredStickers;
      _errorMessage = _messageFromError(error);
    } finally {
      _savingOperations -= 1;
      final pendingCount = (_pendingSaveCounts[stickerId] ?? 1) - 1;
      if (pendingCount <= 0) {
        _pendingSaveCounts.remove(stickerId);
      } else {
        _pendingSaveCounts[stickerId] = pendingCount;
      }
      notifyListeners();
    }
  }

  String _messageFromError(Object error) {
    if (error is ConnectivityException) {
      return error.message;
    }
    return 'No se pudo guardar la figurita. Inténtalo nuevamente.';
  }

    /// Returns the list of player (sticker) names for the currently selected country section.
  List<String> playerNamesForSelectedSection() {
    final team = selectedSection.team;
    if (team == null) {
      // If the 'all' section is selected, return all names.
      return stickers.map((s) => s.name).toList();
    }
    return stickers
        .where((sticker) => sticker.team == team)
        .map((sticker) => sticker.name)
        .toList();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
