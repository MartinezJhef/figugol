import 'dart:convert';

class OfferQrPayload {
  const OfferQrPayload({
    required this.offerId,
    required this.ownerId,
    required this.createdAt,
  });

  final String offerId;
  final String ownerId;
  final DateTime createdAt;

  factory OfferQrPayload.fromJson(Map<String, dynamic> json) {
    return OfferQrPayload(
      offerId: json['offerId'] as String,
      ownerId: json['ownerId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  factory OfferQrPayload.fromEncoded(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('El QR no pertenece a FIGUGOL.');
    }
    return OfferQrPayload.fromJson(decoded);
  }

  Map<String, dynamic> toJson() {
    return {
      'offerId': offerId,
      'ownerId': ownerId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String encode() => jsonEncode(toJson());
}
