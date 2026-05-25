import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/connectivity_service.dart';
import '../../../offers/data/models/trade_offer.dart';
import '../models/payment_simulation.dart';

class PaymentSimulationRepository {
  PaymentSimulationRepository({
    FirebaseFirestore? firestore,
    ConnectivityService? connectivityService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _connectivityService =
           connectivityService ?? const ConnectivityService();

  static const unitPrice = 0.80;
  static const currency = 'PEN';
  static const minimumQuantity = 6;

  final FirebaseFirestore _firestore;
  final ConnectivityService _connectivityService;

  Future<PaymentSimulation> simulateSuccessfulPayment({
    required String userId,
    required TradeOffer offer,
  }) async {
    await _connectivityService.ensureInternetConnection(
      action: ImportantNetworkAction.simulatedPayment,
    );

    final quantity = offer.offeredQuantity;
    if (quantity < minimumQuantity) {
      throw const PaymentSimulationException(
        'El intercambio debe tener mínimo 6 figuritas.',
      );
    }

    final paymentRef = _firestore.collection('simulated_payments').doc();
    final payment = PaymentSimulation(
      id: paymentRef.id,
      userId: userId,
      offerId: offer.id,
      quantity: quantity,
      unitPrice: unitPrice,
      total: quantity * unitPrice,
      currency: currency,
      status: PaymentSimulationStatus.simulatedSuccess,
      createdAt: DateTime.now(),
    );

    final offerRef = _firestore.collection('tradeOffers').doc(offer.id);
    await _firestore.runTransaction((transaction) async {
      final offerSnapshot = await transaction.get(offerRef);
      final data = offerSnapshot.data();
      if (data == null ||
          TradeOffer.fromJson(data).status != TradeOfferStatus.active) {
        throw const PaymentSimulationException(
          'La oferta ya fue reservada o ya no esta disponible.',
        );
      }

      transaction.set(paymentRef, payment.toJson());
      transaction.update(offerRef, {
        'status': TradeOfferStatus.reserved.value,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    });

    return payment;
  }
}

class PaymentSimulationException implements Exception {
  const PaymentSimulationException(this.message);

  final String message;
}
