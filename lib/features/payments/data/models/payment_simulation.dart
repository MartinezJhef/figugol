import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentSimulationStatus {
  simulatedSuccess('simulated_success'),
  simulatedFailed('simulated_failed'),
  cancelled('cancelled');

  const PaymentSimulationStatus(this.value);

  final String value;

  static PaymentSimulationStatus fromValue(String value) {
    return PaymentSimulationStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => PaymentSimulationStatus.cancelled,
    );
  }
}

class PaymentSimulation {
  const PaymentSimulation({
    required this.id,
    required this.userId,
    required this.offerId,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    required this.currency,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String offerId;
  final int quantity;
  final double unitPrice;
  final double total;
  final String currency;
  final PaymentSimulationStatus status;
  final DateTime createdAt;

  factory PaymentSimulation.fromJson(Map<String, dynamic> json) {
    return PaymentSimulation(
      id: json['id'] as String,
      userId: json['userId'] as String,
      offerId: json['offerId'] as String,
      quantity: json['quantity'] as int,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      currency: json['currency'] as String,
      status: PaymentSimulationStatus.fromValue(json['status'] as String),
      createdAt: _readDateTime(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'offerId': offerId,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'total': total,
      'currency': currency,
      'status': status.value,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static DateTime _readDateTime(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
