import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../location/data/models/exchange_point.dart';
import '../../../stickers/data/models/sticker.dart';

enum TradeOfferStatus {
  active('active'),
  reserved('reserved'),
  completed('completed'),
  cancelled('cancelled');

  const TradeOfferStatus(this.value);

  final String value;

  static TradeOfferStatus fromValue(String value) {
    return TradeOfferStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => TradeOfferStatus.active,
    );
  }
}

class TradeOfferSticker {
  const TradeOfferSticker({required this.sticker, required this.quantity});

  final Sticker sticker;
  final int quantity;

  factory TradeOfferSticker.fromJson(Map<String, dynamic> json) {
    return TradeOfferSticker(
      sticker: Sticker.fromJson(
        Map<String, dynamic>.from(json['sticker'] as Map),
      ),
      quantity: json['quantity'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'sticker': sticker.toJson(), 'quantity': quantity};
  }
}

class TradeOffer {
  const TradeOffer({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.ownerPhotoUrl,
    required this.stickersOffered,
    required this.missingStickers,
    required this.exchangePoints,
    required this.latitude,
    required this.longitude,
    required this.zoneHash,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ownerId;
  final String ownerName;
  final String? ownerPhotoUrl;
  final List<TradeOfferSticker> stickersOffered;
  final List<Sticker> missingStickers;
  final List<ExchangePoint> exchangePoints;
  final double latitude;
  final double longitude;
  final String zoneHash;
  final TradeOfferStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get offeredQuantity =>
      stickersOffered.fold(0, (total, item) => total + item.quantity);

  factory TradeOffer.fromJson(Map<String, dynamic> json) {
    return TradeOffer(
      id: json['id'] as String,
      ownerId: json['ownerId'] as String,
      ownerName: json['ownerName'] as String,
      ownerPhotoUrl: json['ownerPhotoUrl'] as String?,
      stickersOffered: (json['stickersOffered'] as List<dynamic>? ?? const [])
          .map(
            (item) => TradeOfferSticker.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      missingStickers: (json['missingStickers'] as List<dynamic>? ?? const [])
          .map(
            (item) => Sticker.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      exchangePoints: (json['exchangePoints'] as List<dynamic>? ?? const [])
          .map(
            (item) =>
                ExchangePoint.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      zoneHash: json['zoneHash'] as String,
      status: TradeOfferStatus.fromValue(json['status'] as String),
      createdAt: _readDateTime(json['createdAt']),
      updatedAt: _readDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerPhotoUrl': ownerPhotoUrl,
      'stickersOffered': stickersOffered.map((item) => item.toJson()).toList(),
      'missingStickers': missingStickers.map((item) => item.toJson()).toList(),
      'exchangePoints': exchangePoints.map((point) => point.toJson()).toList(),
      'latitude': latitude,
      'longitude': longitude,
      'zoneHash': zoneHash,
      'status': status.value,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
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
