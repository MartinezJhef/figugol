import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/services/connectivity_service.dart';
import '../../data/models/sticker.dart';
import '../../data/models/user_sticker.dart';
import '../../data/repositories/stickers_repository.dart';


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

  String? get flagAsset => id == 'all' ? null : 'assets/paises/$id.png';
}

class StickersController extends ChangeNotifier {
  StickersController({
    required this.userId,
    StickersRepository? stickersRepository,
  }) : _stickersRepository = stickersRepository ?? StickersRepository() {
    _catalogSubscription = _stickersRepository.watchCatalog().listen(
      (catalog) {
        _stickers = catalog;
        _isCatalogLoaded = true;
        notifyListeners();
      },
      onError: (_) {
        _errorMessage = 'No se pudo cargar el catálogo de figuritas.';
        notifyListeners();
      },
    );

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

  StreamSubscription<List<Sticker>>? _catalogSubscription;
  List<Sticker> _stickers = [];
  bool _isCatalogLoaded = false;
  
  List<Sticker> get stickers => _stickers;
  static const allSectionId = 'all';
  static const sections = <StickerAlbumSection>[
    StickerAlbumSection(
      id: allSectionId,
      label: 'Torneo mundial',
      primaryColor: Color(0xFF006847),
      secondaryColor: Color(0xFF0A369D),
    ),
    StickerAlbumSection(
      id: 'canada',
      label: 'Canada',
      team: 'Canada',
      primaryColor: Color(0xFF006847),
      secondaryColor: Color(0xFF0A369D),
    ),
    StickerAlbumSection(
      id: 'estados_unidos',
      label: 'Estados Unidos',
      team: 'Estados Unidos',
      primaryColor: Color(0xFF006847),
      secondaryColor: Color(0xFF0A369D),
    ),
    StickerAlbumSection(
      id: 'mexico',
      label: 'Mexico',
      team: 'Mexico',
      primaryColor: Color(0xFF006847),
      secondaryColor: Color(0xFF0A369D),
    ),
    StickerAlbumSection(
      id: 'argentina',
      label: 'Argentina',
      team: 'Argentina',
      primaryColor: Color(0xFF006847),
      secondaryColor: Color(0xFF0A369D),
    ),
    StickerAlbumSection(
      id: 'brasil',
      label: 'Brasil',
      team: 'Brasil',
      primaryColor: Color(0xFF006847),
      secondaryColor: Color(0xFF0A369D),
    ),
    StickerAlbumSection(
      id: 'colombia',
      label: 'Colombia',
      team: 'Colombia',
      primaryColor: Color(0xFF006847),
      secondaryColor: Color(0xFF0A369D),
    ),
    StickerAlbumSection(
      id: 'ecuador',
      label: 'Ecuador',
      team: 'Ecuador',
      primaryColor: Color(0xFF006847),
      secondaryColor: Color(0xFF0A369D),
    ),
    StickerAlbumSection(
      id: 'paraguay',
      label: 'Paraguay',
      team: 'Paraguay',
      primaryColor: Color(0xFF006847),
      secondaryColor: Color(0xFF0A369D),
    ),
    StickerAlbumSection(
      id: 'uruguay',
      label: 'Uruguay',
      team: 'Uruguay',
      primaryColor: Color(0xFF006847),
      secondaryColor: Color(0xFF0A369D),
    ),
    StickerAlbumSection(
      id: 'alemania',
      label: 'Alemania',
      team: 'Alemania',
      primaryColor: Color(0xFF006847),
      secondaryColor: Color(0xFF0A369D),
    ),
    StickerAlbumSection(
      id: 'austria',
      label: 'Austria',
      team: 'Austria',
      primaryColor: Color(0xFF006847),
      secondaryColor: Color(0xFF0A369D),
    ),
    StickerAlbumSection(
      id: 'belgica',
      label: 'Belgica',
      team: 'Belgica',
      primaryColor: Color(0xFF006847),
      secondaryColor: Color(0xFF0A369D),
    ),
    StickerAlbumSection(
      id: 'bosnia_y_herzegovina',
      label: 'Bosnia y Herzegovina',
      team: 'Bosnia y Herzegovina',
      primaryColor: Color(0xFF006847),
      secondaryColor: Color(0xFF0A369D),
    ),
    StickerAlbumSection(
      id: 'croacia',
      label: 'Croacia',
      team: 'Croacia',
      primaryColor: Color(0xFF006847),
      secondaryColor: Color(0xFF0A369D),
    ),
    StickerAlbumSection(
      id: 'escocia',
      label: 'Escocia',
      team: 'Escocia',
      primaryColor: Color(0xFF006847),
      secondaryColor: Color(0xFF0A369D),
    ),
    StickerAlbumSection(
      id: 'espana',
      label: 'Espana',
      team: 'Espana',
      primaryColor: Color(0xFF006847),
      secondaryColor: Color(0xFF0A369D),
    ),
    StickerAlbumSection(
      id: 'francia',
      label: 'Francia',
      team: 'Francia',
      primaryColor: Color(0xFF006847),
      secondaryColor: Color(0xFF0A369D),
    ),
    StickerAlbumSection(
      id: 'noruega',
      label: 'Noruega',
      team: 'Noruega',
      primaryColor: Color(0xFF006847),
      secondaryColor: Color(0xFF0A369D),
    ),
    StickerAlbumSection(
      id: 'paises_bajos',
      label: 'Paises Bajos',
      team: 'Paises Bajos',
      primaryColor: Color(0xFF006847),
      secondaryColor: Color(0xFF0A369D),
    ),
    StickerAlbumSection(
      id: 'portugal',
      label: 'Portugal',
      team: 'Portugal',
      primaryColor: Color(0xFF006847),
      secondaryColor: Color(0xFF0A369D),
    ),
    StickerAlbumSection(
      id: 'republica_checa',
      label: 'Republica Checa',
      team: 'Republica Checa',
      primaryColor: Color(0xFF006847),
      secondaryColor: Color(0xFF0A369D),
    ),
    StickerAlbumSection(
      id: 'suecia',
      label: 'Suecia',
      team: 'Suecia',
      primaryColor: Color(0xFF006847),
      secondaryColor: Color(0xFF0A369D),
    ),
    StickerAlbumSection(
      id: 'suiza',
      label: 'Suiza',
      team: 'Suiza',
      primaryColor: Color(0xFF006847),
      secondaryColor: Color(0xFF0A369D),
    ),
    StickerAlbumSection(
      id: 'turquia',
      label: 'Turquia',
      team: 'Turquia',
      primaryColor: Color(0xFF006847),
      secondaryColor: Color(0xFF0A369D),
    ),
    StickerAlbumSection(
      id: 'argelia',
      label: 'Argelia',
      team: 'Argelia',
      primaryColor: Color(0xFF006847),
      secondaryColor: Color(0xFF0A369D),
    ),
    StickerAlbumSection(
      id: 'cabo_verde',
      label: 'Cabo Verde',
      team: 'Cabo Verde',
      primaryColor: Color(0xFF006847),
      secondaryColor: Color(0xFF0A369D),
    ),
    StickerAlbumSection(
      id: 'costa_de_marfil',
      label: 'Costa de Marfil',
      team: 'Costa de Marfil',
      primaryColor: Color(0xFF006847),
      secondaryColor: Color(0xFF0A369D),
    ),
    StickerAlbumSection(
      id: 'egipto',
      label: 'Egipto',
      team: 'Egipto',
      primaryColor: Color(0xFF006847),
      secondaryColor: Color(0xFF0A369D),
    ),
    StickerAlbumSection(
      id: 'ghana',
      label: 'Ghana',
      team: 'Ghana',
      primaryColor: Color(0xFF006847),
      secondaryColor: Color(0xFF0A369D),
    ),
    StickerAlbumSection(
      id: 'marruecos',
      label: 'Marruecos',
      team: 'Marruecos',
      primaryColor: Color(0xFF006847),
      secondaryColor: Color(0xFF0A369D),
    ),
    StickerAlbumSection(
      id: 'rd_congo',
      label: 'RD Congo',
      team: 'RD Congo',
      primaryColor: Color(0xFF006847),
      secondaryColor: Color(0xFF0A369D),
    ),
    StickerAlbumSection(
      id: 'senegal',
      label: 'Senegal',
      team: 'Senegal',
      primaryColor: Color(0xFF006847),
      secondaryColor: Color(0xFF0A369D),
    ),
    StickerAlbumSection(
      id: 'sudafrica',
      label: 'Sudafrica',
      team: 'Sudafrica',
      primaryColor: Color(0xFF006847),
      secondaryColor: Color(0xFF0A369D),
    ),
    StickerAlbumSection(
      id: 'tunez',
      label: 'Tunez',
      team: 'Tunez',
      primaryColor: Color(0xFF006847),
      secondaryColor: Color(0xFF0A369D),
    ),
    StickerAlbumSection(
      id: 'arabia_saudi',
      label: 'Arabia Saudi',
      team: 'Arabia Saudi',
      primaryColor: Color(0xFF006847),
      secondaryColor: Color(0xFF0A369D),
    ),
    StickerAlbumSection(
      id: 'australia',
      label: 'Australia',
      team: 'Australia',
      primaryColor: Color(0xFF006847),
      secondaryColor: Color(0xFF0A369D),
    ),
    StickerAlbumSection(
      id: 'catar',
      label: 'Catar',
      team: 'Catar',
      primaryColor: Color(0xFF006847),
      secondaryColor: Color(0xFF0A369D),
    ),
    StickerAlbumSection(
      id: 'corea_del_sur',
      label: 'Corea del Sur',
      team: 'Corea del Sur',
      primaryColor: Color(0xFF006847),
      secondaryColor: Color(0xFF0A369D),
    ),
    StickerAlbumSection(
      id: 'irak',
      label: 'Irak',
      team: 'Irak',
      primaryColor: Color(0xFF006847),
      secondaryColor: Color(0xFF0A369D),
    ),
    StickerAlbumSection(
      id: 'japon',
      label: 'Japon',
      team: 'Japon',
      primaryColor: Color(0xFF006847),
      secondaryColor: Color(0xFF0A369D),
    ),
    StickerAlbumSection(
      id: 'jordania',
      label: 'Jordania',
      team: 'Jordania',
      primaryColor: Color(0xFF006847),
      secondaryColor: Color(0xFF0A369D),
    ),
    StickerAlbumSection(
      id: 'ri_de_iran',
      label: 'RI de Iran',
      team: 'RI de Iran',
      primaryColor: Color(0xFF006847),
      secondaryColor: Color(0xFF0A369D),
    ),
    StickerAlbumSection(
      id: 'uzbekistan',
      label: 'Uzbekistan',
      team: 'Uzbekistan',
      primaryColor: Color(0xFF006847),
      secondaryColor: Color(0xFF0A369D),
    ),
    StickerAlbumSection(
      id: 'curazao',
      label: 'Curazao',
      team: 'Curazao',
      primaryColor: Color(0xFF006847),
      secondaryColor: Color(0xFF0A369D),
    ),
    StickerAlbumSection(
      id: 'haiti',
      label: 'Haiti',
      team: 'Haiti',
      primaryColor: Color(0xFF006847),
      secondaryColor: Color(0xFF0A369D),
    ),
    StickerAlbumSection(
      id: 'panama',
      label: 'Panama',
      team: 'Panama',
      primaryColor: Color(0xFF006847),
      secondaryColor: Color(0xFF0A369D),
    ),
    StickerAlbumSection(
      id: 'nueva_zelanda',
      label: 'Nueva Zelanda',
      team: 'Nueva Zelanda',
      primaryColor: Color(0xFF006847),
      secondaryColor: Color(0xFF0A369D),
    ),
  ];

  Map<String, UserSticker> _userStickers = const {};
  final Set<String> _selectedStickerIds = {};
  StickerFilter _filter = StickerFilter.all;
  String _selectedSectionId = allSectionId;
  String _searchQuery = '';
  String? _errorMessage;
  int _savingOperations = 0;
  final Map<String, int> _pendingSaveCounts = {};

  StickerFilter get filter => _filter;
  String get searchQuery => _searchQuery;
  String get selectedSectionId => _selectedSectionId;
  StickerAlbumSection get selectedSection => sections.firstWhere(
    (section) => section.id == _selectedSectionId,
    orElse: () => sections.first,
  );
  List<StickerAlbumSection> get visibleSections {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return sections;
    }
    return sections.where((section) {
      return section.label.toLowerCase().contains(query);
    }).toList();
  }

  String? get errorMessage => _errorMessage;
  bool get isSaving => _savingOperations > 0;
  bool get isCatalogLoaded => _isCatalogLoaded;
  bool get hasLoadedCollection => _isCatalogLoaded;
  bool get hasRegisteredStickers =>
      _userStickers.values.any((sticker) => sticker.quantity > 0);

  List<Sticker> get visibleStickers {
    final query = _searchQuery.trim().toLowerCase();
    return stickers.where((sticker) {
      final quantity = quantityFor(sticker.id);
      final sectionMatches =
          selectedSection.team == null || selectedSection.team == sticker.team;
          
      final matchesName = query.isEmpty || sticker.name.toLowerCase().contains(query);
      final matchesTeam = query.isEmpty || sticker.team.toLowerCase().contains(query);
      
      if (query.isNotEmpty && !matchesName && !matchesTeam) {
        return false;
      }
      
      return switch (_filter) {
        StickerFilter.all => sectionMatches,
        StickerFilter.owned => sectionMatches && isPasted(sticker.id),
        StickerFilter.duplicates => sectionMatches && quantity > 0,
        StickerFilter.missing => sectionMatches && !isPasted(sticker.id),
      };
    }).toList();
  }

  int quantityFor(String stickerId) {
    return _userStickers[stickerId]?.quantity ?? 0;
  }

  bool isPasted(String stickerId) {
    return _userStickers[stickerId]?.isPasted ?? false;
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

  void setSearchQuery(String query) {
    _searchQuery = query;
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
    await _saveStickerState(stickerId, quantityFor(stickerId) + 1, isPasted(stickerId));
  }

  Future<void> decrementQuantity(String stickerId) async {
    final currentQuantity = quantityFor(stickerId);
    if (currentQuantity == 0) {
      return;
    }
    await _saveStickerState(stickerId, currentQuantity - 1, isPasted(stickerId));
  }

  Future<void> decreaseQuantityBy(String stickerId, int amount) async {
    final currentQuantity = quantityFor(stickerId);
    if (currentQuantity < amount) {
      return;
    }
    await _saveStickerState(stickerId, currentQuantity - amount, isPasted(stickerId));
  }

  Future<void> togglePasteSticker(String stickerId) async {
    await _saveStickerState(stickerId, quantityFor(stickerId), !isPasted(stickerId));
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _saveStickerState(String stickerId, int quantity, bool isPasted) async {
    final nextQuantity = quantity < 0 ? 0 : quantity;
    final previousSticker = _userStickers[stickerId];
    final now = DateTime.now();
    final nextSticker = UserSticker(
      userId: userId,
      stickerId: stickerId,
      quantity: nextQuantity,
      updatedAt: now,
      isPasted: isPasted,
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
    _catalogSubscription?.cancel();
    _subscription?.cancel();
    super.dispose();
  }
}
