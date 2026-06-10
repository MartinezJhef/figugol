import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/connectivity_service.dart';
import '../models/exchange_point.dart';
import '../models/user_location.dart';

class LocationRepository {
  LocationRepository({
    FirebaseFirestore? firestore,
    ConnectivityService? connectivityService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _connectivityService =
           connectivityService ?? const ConnectivityService();

  static const nearbyRadiusKm = 100.0;

  final FirebaseFirestore _firestore;
  final ConnectivityService _connectivityService;

  Future<void> confirmLocation({
    required String userId,
    required double latitude,
    required double longitude,
  }) async {
    if (userId == 'invitado_local') {
      return;
    }

    await _connectivityService.ensureInternetConnection(
      action: ImportantNetworkAction.confirmLocation,
    );

    final location = UserLocation(
      latitude: latitude,
      longitude: longitude,
      confirmedAt: DateTime.now(),
      sector: calculateSector(latitude: latitude, longitude: longitude),
      nearbyRadiusKm: nearbyRadiusKm,
    );

    await _firestore.collection('users').doc(userId).update({
      'location': location.toJson(),
      'locationConfirmed': true,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> saveExchangePoints({
    required String userId,
    required List<ExchangePoint> exchangePoints,
  }) async {
    if (userId == 'invitado_local') {
      return;
    }

    await _connectivityService.ensureInternetConnection(
      action: ImportantNetworkAction.confirmLocation,
    );

    final batch = _firestore.batch();
    final userRef = _firestore.collection('users').doc(userId);
    final exchangePointsRef = userRef.collection('exchangePoints');
    final selectedIds = exchangePoints.map((point) => point.id).toList();

    for (final point in exchangePoints) {
      batch.set(exchangePointsRef.doc(point.id), point.toJson());
    }

    batch.update(userRef, {
      'selectedExchangePoints': selectedIds,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });

    await batch.commit();
  }

  String calculateSector({
    required double latitude,
    required double longitude,
  }) {
    final latBand = (latitude * 20).floor();
    final lngBand = (longitude * 20).floor();
    return 'zone_${latBand}_$lngBand';
  }
}
