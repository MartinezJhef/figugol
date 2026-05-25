import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/services/connectivity_service.dart';
import '../../../auth/data/models/app_user.dart';
import '../../../location/data/models/exchange_point.dart';
import '../../../stickers/data/models/sticker.dart';
import '../../../stickers/data/models/user_sticker.dart';
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

  Future<List<ExchangePoint>> loadUserExchangePoints(String userId) async {
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
