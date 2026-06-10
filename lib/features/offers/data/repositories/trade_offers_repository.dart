import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/services/connectivity_service.dart';
import '../../../auth/data/models/app_user.dart';
import '../../../location/data/models/exchange_point.dart';
import '../../../stickers/data/models/sticker.dart';
import '../../../stickers/data/models/user_sticker.dart';
import '../../../stickers/data/repositories/stickers_repository.dart';
import '../../../stickers/data/sources/demo_sticker_catalog.dart';
import '../../presentation/controllers/trade_cart_controller.dart';
import '../models/trade_offer.dart';
import '../models/trade_proposal.dart';

class TradeOffersRepository {
  TradeOffersRepository({
    FirebaseFirestore? firestore,
    ConnectivityService? connectivityService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _connectivityService =
           connectivityService ?? const ConnectivityService();

  final FirebaseFirestore _firestore;
  final ConnectivityService _connectivityService;

  static const maximumVisibleDistanceKm = 100.0;

  static final List<TradeOffer> _localMockOffers = [
    TradeOffer(
      id: 'offer_mock_1',
      ownerId: 'owner_mock_1',
      ownerName: 'Juan Pérez',
      ownerPhotoUrl: null,
      stickersOffered: [
        TradeOfferSticker(
          sticker: demoStickerCatalog[0],
          quantity: 2,
        ),
        TradeOfferSticker(
          sticker: demoStickerCatalog[1],
          quantity: 1,
        ),
      ],
      missingStickers: [
        demoStickerCatalog[2],
      ],
      exchangePoints: [
        ExchangePoint(
          id: 'pt_1',
          name: 'Centro de Intercambio Norte',
          latitude: 0,
          longitude: 0,
          description: 'Frente a la boletería',
          type: ExchangePointType.other,
          isSelected: true,
        ),
        ExchangePoint(
          id: 'pt_2',
          name: 'Punto Central Estadio',
          latitude: 0,
          longitude: 0,
          description: 'Puerta de entrada principal',
          type: ExchangePointType.other,
          isSelected: true,
        ),
        ExchangePoint(
          id: 'pt_3',
          name: 'Intercambio Plaza Sur',
          latitude: 0,
          longitude: 0,
          description: 'Patio de comidas central',
          type: ExchangePointType.other,
          isSelected: true,
        ),
      ],
      latitude: -12.046374,
      longitude: -77.042793,
      zoneHash: 'zone_0_0',
      status: TradeOfferStatus.active,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    TradeOffer(
      id: 'offer_mock_2',
      ownerId: 'owner_mock_2',
      ownerName: 'María Rodríguez',
      ownerPhotoUrl: null,
      stickersOffered: [
        TradeOfferSticker(
          sticker: demoStickerCatalog[2],
          quantity: 1,
        ),
      ],
      missingStickers: [
        demoStickerCatalog[0],
      ],
      exchangePoints: [
        ExchangePoint(
          id: 'pt_1',
          name: 'Centro de Intercambio Norte',
          latitude: 0,
          longitude: 0,
          description: 'Frente a la boletería',
          type: ExchangePointType.other,
          isSelected: true,
        ),
        ExchangePoint(
          id: 'pt_2',
          name: 'Punto Central Estadio',
          latitude: 0,
          longitude: 0,
          description: 'Puerta de entrada principal',
          type: ExchangePointType.other,
          isSelected: true,
        ),
        ExchangePoint(
          id: 'pt_3',
          name: 'Intercambio Plaza Sur',
          latitude: 0,
          longitude: 0,
          description: 'Patio de comidas central',
          type: ExchangePointType.other,
          isSelected: true,
        ),
      ],
      latitude: -12.046374,
      longitude: -77.042793,
      zoneHash: 'zone_0_0',
      status: TradeOfferStatus.active,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  Future<List<ExchangePoint>> loadUserExchangePoints(String userId) async {
    if (userId == 'invitado_local') {
      return [
        ExchangePoint(
          id: 'pt_1',
          name: 'Centro de Intercambio Norte',
          latitude: 0,
          longitude: 0,
          description: 'Frente a la boletería',
          type: ExchangePointType.other,
          isSelected: true,
        ),
        ExchangePoint(
          id: 'pt_2',
          name: 'Punto Central Estadio',
          latitude: 0,
          longitude: 0,
          description: 'Puerta de entrada principal',
          type: ExchangePointType.other,
          isSelected: true,
        ),
        ExchangePoint(
          id: 'pt_3',
          name: 'Intercambio Plaza Sur',
          latitude: 0,
          longitude: 0,
          description: 'Patio de comidas central',
          type: ExchangePointType.other,
          isSelected: true,
        ),
      ];
    }

    await _connectivityService.ensureInternetConnection(
      action: ImportantNetworkAction.publishOffers,
    );

    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('exchangePoints')
        .get();

    return snapshot.docs
        .map((document) => ExchangePoint.fromJson(document.data()))
        .toList();
  }

  Future<void> publishOffer({
    required AppUser user,
    required List<TradeCartItem> cartItems,
    required List<ExchangePoint> exchangePoints,
  }) async {
    if (user.uid == 'invitado_local') {
      final now = DateTime.now();
      final offer = TradeOffer(
        id: 'offer_local_${now.millisecondsSinceEpoch}',
        ownerId: user.uid,
        ownerName: user.exchangeName!,
        ownerPhotoUrl: user.photoUrl,
        stickersOffered: cartItems
            .map(
              (item) => TradeOfferSticker(
                sticker: item.sticker,
                quantity: item.quantity,
              ),
            )
            .toList(),
        missingStickers: const <Sticker>[],
        exchangePoints: exchangePoints,
        latitude: user.location?.latitude ?? 0.0,
        longitude: user.location?.longitude ?? 0.0,
        zoneHash: 'zone_0_0',
        status: TradeOfferStatus.active,
        createdAt: now,
        updatedAt: now,
      );
      _localMockOffers.add(offer);
      return;
    }

    await _connectivityService.ensureInternetConnection(
      action: ImportantNetworkAction.publishOffers,
    );

    _validatePublishRules(
      user: user,
      cartItems: cartItems,
      exchangePoints: exchangePoints,
    );
    await _ensureOfferedStickersAreDuplicates(
      userId: user.uid,
      cartItems: cartItems,
    );

    final location = user.location!;
    final offerRef = _firestore.collection('tradeOffers').doc();
    final now = DateTime.now();
    final offer = TradeOffer(
      id: offerRef.id,
      ownerId: user.uid,
      ownerName: user.exchangeName!.trim(),
      ownerPhotoUrl: user.photoUrl,
      stickersOffered: cartItems
          .map(
            (item) => TradeOfferSticker(
              sticker: item.sticker,
              quantity: item.quantity,
            ),
          )
          .toList(),
      missingStickers: const <Sticker>[],
      exchangePoints: exchangePoints,
      latitude: location.latitude,
      longitude: location.longitude,
      zoneHash: buildZoneHash(location.sector),
      status: TradeOfferStatus.active,
      createdAt: now,
      updatedAt: now,
    );

    await offerRef.set(offer.toJson());
  }

  Stream<List<TradeOffer>> watchNearbyActiveOffers({required AppUser user}) {
    if (user.uid == 'invitado_local') {
      return Stream.value(_localMockOffers.where((offer) => offer.ownerId != 'invitado_local').toList());
    }

    final location = user.location;
    if (location == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('tradeOffers')
        .where('status', isEqualTo: TradeOfferStatus.active.value)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((document) => TradeOffer.fromJson(document.data()))
              .where((offer) => offer.ownerId != user.uid)
              .where(
                (offer) =>
                    distanceKm(
                      fromLatitude: location.latitude,
                      fromLongitude: location.longitude,
                      offer: offer,
                    ) <=
                    maximumVisibleDistanceKm,
              )
              .toList()
            ..sort(
              (left, right) =>
                  distanceKm(
                    fromLatitude: location.latitude,
                    fromLongitude: location.longitude,
                    offer: left,
                  ).compareTo(
                    distanceKm(
                      fromLatitude: location.latitude,
                      fromLongitude: location.longitude,
                      offer: right,
                    ),
                  ),
            );
        });
  }

  Stream<List<TradeOffer>> watchMyActiveOffers(String userId) {
    if (userId == 'invitado_local') {
      return Stream.value(_localMockOffers.where((offer) => offer.ownerId == 'invitado_local').toList());
    }

    return _firestore
        .collection('tradeOffers')
        .where('ownerId', isEqualTo: userId)
        .where('status', isEqualTo: TradeOfferStatus.active.value)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((document) => TradeOffer.fromJson(document.data()))
              .toList();
        });
  }

  Future<TradeOffer> loadOfferById(String offerId) async {
    if (offerId.startsWith('offer_mock_') || offerId.startsWith('offer_local_')) {
      return _localMockOffers.firstWhere((offer) => offer.id == offerId);
    }

    await _connectivityService.ensureInternetConnection(
      action: ImportantNetworkAction.sendExchange,
    );

    final snapshot = await _firestore
        .collection('tradeOffers')
        .doc(offerId)
        .get();
    final data = snapshot.data();

    if (data == null) {
      throw const TradeOfferException('No se encontró la oferta escaneada.');
    }

    return TradeOffer.fromJson(data);
  }

  Future<void> createProposal({
    required String offerId,
    required String fromUserId,
    required String toUserId,
    required List<TradeOfferSticker> offeredStickers,
    required List<TradeOfferSticker> requestedStickers,
  }) async {
    if (fromUserId == 'invitado_local') {
      return;
    }

    await _connectivityService.ensureInternetConnection(
      action: ImportantNetworkAction.sendExchange,
    );

    if (fromUserId == toUserId) {
      throw const TradeOfferException(
        'No puedes proponer un intercambio para tu propia oferta.',
      );
    }
    if (offeredStickers.isEmpty || requestedStickers.isEmpty) {
      throw const TradeOfferException(
        'Selecciona figuritas para ofrecer y para solicitar.',
      );
    }

    final proposalRef = _firestore.collection('tradeProposals').doc();
    final proposal = TradeProposal(
      id: proposalRef.id,
      offerId: offerId,
      fromUserId: fromUserId,
      toUserId: toUserId,
      offeredStickers: offeredStickers,
      requestedStickers: requestedStickers,
      status: TradeProposalStatus.pending,
      createdAt: DateTime.now(),
    );

    final offerRef = _firestore.collection('tradeOffers').doc(offerId);
    final collectionRef = _firestore
        .collection('sticker_collections')
        .doc(fromUserId)
        .collection('stickers');

    await _firestore.runTransaction((transaction) async {
      final offerSnapshot = await transaction.get(offerRef);
      final data = offerSnapshot.data();
      if (data == null) {
        throw const TradeOfferException('La oferta ya no esta disponible.');
      }

      final currentOffer = TradeOffer.fromJson(data);
      if (currentOffer.ownerId != toUserId ||
          currentOffer.status != TradeOfferStatus.active) {
        throw const TradeOfferException('La oferta ya no esta disponible.');
      }

      final offeredByOwner = <String, int>{
        for (final item in currentOffer.stickersOffered)
          item.sticker.id: item.quantity,
      };
      for (final requested in requestedStickers) {
        if (requested.quantity < 1 ||
            (offeredByOwner[requested.sticker.id] ?? 0) < requested.quantity) {
          throw const TradeOfferException(
            'Una figurita solicitada ya no esta disponible.',
          );
        }
      }

      for (final offered in offeredStickers) {
        final stickerSnapshot = await transaction.get(
          collectionRef.doc(offered.sticker.id),
        );
        final ownedQuantity = stickerSnapshot.data()?['quantity'] as int? ?? 0;
        if (offered.quantity < 1 || offered.quantity > ownedQuantity - 1) {
          throw TradeOfferException(
            'Ya no tienes duplicadas suficientes de ${offered.sticker.catalogCode}.',
          );
        }
      }

      transaction.set(proposalRef, proposal.toJson());
    });
  }

  double distanceKm({
    required double fromLatitude,
    required double fromLongitude,
    required TradeOffer offer,
  }) {
    final meters = Geolocator.distanceBetween(
      fromLatitude,
      fromLongitude,
      offer.latitude,
      offer.longitude,
    );
    return meters / 1000;
  }

  Future<OfferCompatibility> loadOfferCompatibility({
    required String userId,
    required TradeOffer offer,
  }) async {
    final myStickers = await _loadUserStickerMap(userId);
    final offeredStickerIds = offer.stickersOffered
        .map((item) => item.sticker.id)
        .toSet();
    final ownerMissingIds = offer.missingStickers
        .map((sticker) => sticker.id)
        .toSet();

    final missingFromOffer = offer.stickersOffered.where((item) {
      return (myStickers[item.sticker.id]?.quantity ?? 0) == 0;
    }).toList();

    final myDuplicates = demoStickerCatalog.where((sticker) {
      return (myStickers[sticker.id]?.quantity ?? 0) > 1;
    }).toList();

    final possibleToOffer = ownerMissingIds.isEmpty
        ? const <Sticker>[]
        : myDuplicates.where((sticker) {
            return ownerMissingIds.contains(sticker.id) &&
                !offeredStickerIds.contains(sticker.id);
          }).toList();

    return OfferCompatibility(
      missingFromOffer: missingFromOffer,
      possibleToOffer: possibleToOffer,
      myDuplicates: myDuplicates,
      hasEnoughDataForFullCompatibility: ownerMissingIds.isNotEmpty,
    );
  }

  String buildZoneHash(String sector) {
    // This intentionally mirrors the current sector value. Replace this method
    // with a real geohash implementation when nearby search needs finer bounds.
    return sector;
  }

  void _validatePublishRules({
    required AppUser user,
    required List<TradeCartItem> cartItems,
    required List<ExchangePoint> exchangePoints,
  }) {
    if (!user.hasCompletedProfile) {
      throw const TradeOfferException(
        'Completa tu nombre de intercambio antes de publicar.',
      );
    }
    if (!user.locationConfirmed || user.location == null) {
      throw const TradeOfferException(
        'Confirma tu ubicación antes de publicar una oferta.',
      );
    }
    if (exchangePoints.length != 3) {
      throw const TradeOfferException(
        'Selecciona 3 puntos de intercambio antes de publicar.',
      );
    }
    final totalItems = cartItems.fold(
      0,
      (total, item) => total + item.quantity,
    );
    if (totalItems < TradeCartController.minimumItemsToPublish) {
      throw const TradeOfferException(
        'Debes seleccionar mínimo 6 figuritas para publicar una oferta.',
      );
    }
    if (cartItems.any((item) => item.quantity < 1)) {
      throw const TradeOfferException(
        'Solo puedes publicar figuritas duplicadas.',
      );
    }
  }

  Future<void> _ensureOfferedStickersAreDuplicates({
    required String userId,
    required List<TradeCartItem> cartItems,
  }) async {
    if (userId == 'invitado_local') {
      return;
    }

    final collectionRef = _firestore
        .collection('sticker_collections')
        .doc(userId)
        .collection('stickers');

    for (final item in cartItems) {
      final snapshot = await collectionRef.doc(item.sticker.id).get();
      final quantity = snapshot.data()?['quantity'] as int? ?? 0;

      if (quantity <= 1 || item.quantity > quantity - 1) {
        throw TradeOfferException(
          'La figurita ${item.sticker.catalogCode} ya no tiene duplicados suficientes.',
        );
      }
    }
  }

  Future<Map<String, UserSticker>> _loadUserStickerMap(String userId) async {
    if (userId == 'invitado_local') {
      // Retornar directamente la lista local mockeada
      return StickersRepository.localMockStickers;
    }

    final snapshot = await _firestore
        .collection('sticker_collections')
        .doc(userId)
        .collection('stickers')
        .get();

    return {
      for (final document in snapshot.docs)
        document.id: UserSticker.fromJson(document.data()),
    };
  }
}

class TradeOfferException implements Exception {
  const TradeOfferException(this.message);

  final String message;
}

class OfferCompatibility {
  const OfferCompatibility({
    required this.missingFromOffer,
    required this.possibleToOffer,
    required this.myDuplicates,
    required this.hasEnoughDataForFullCompatibility,
  });

  final List<TradeOfferSticker> missingFromOffer;
  final List<Sticker> possibleToOffer;
  final List<Sticker> myDuplicates;
  final bool hasEnoughDataForFullCompatibility;
}
