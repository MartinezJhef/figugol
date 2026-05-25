import 'package:cloud_firestore/cloud_firestore.dart';

import 'trade_offer.dart';

enum TradeProposalStatus {
  pending('pending'),
  accepted('accepted'),
  rejected('rejected'),
  completed('completed');

  const TradeProposalStatus(this.value);

  final String value;

  static TradeProposalStatus fromValue(String value) {
    return TradeProposalStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => TradeProposalStatus.pending,
    );
  }
}

class TradeProposal {
  const TradeProposal({
    required this.id,
    required this.offerId,
    required this.fromUserId,
    required this.toUserId,
    required this.offeredStickers,
    required this.requestedStickers,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String offerId;
  final String fromUserId;
  final String toUserId;
  final List<TradeOfferSticker> offeredStickers;
  final List<TradeOfferSticker> requestedStickers;
  final TradeProposalStatus status;
  final DateTime createdAt;

  factory TradeProposal.fromJson(Map<String, dynamic> json) {
    return TradeProposal(
      id: json['id'] as String,
      offerId: json['offerId'] as String,
      fromUserId: json['fromUserId'] as String,
      toUserId: json['toUserId'] as String,
      offeredStickers: (json['offeredStickers'] as List<dynamic>? ?? const [])
          .map(
            (item) => TradeOfferSticker.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      requestedStickers:
          (json['requestedStickers'] as List<dynamic>? ?? const [])
              .map(
                (item) => TradeOfferSticker.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList(),
      status: TradeProposalStatus.fromValue(json['status'] as String),
      createdAt: _readDateTime(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'offerId': offerId,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'offeredStickers': offeredStickers.map((item) => item.toJson()).toList(),
      'requestedStickers': requestedStickers
          .map((item) => item.toJson())
          .toList(),
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
