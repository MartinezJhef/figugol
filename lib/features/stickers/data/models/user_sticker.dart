import 'package:cloud_firestore/cloud_firestore.dart';

class UserSticker {
  const UserSticker({
    required this.userId,
    required this.stickerId,
    required this.quantity,
    required this.updatedAt,
  });

  final String userId;
  final String stickerId;
  final int quantity;
  final DateTime updatedAt;

  factory UserSticker.fromJson(Map<String, dynamic> json) {
    return UserSticker(
      userId: json['userId'] as String,
      stickerId: json['stickerId'] as String,
      quantity: json['quantity'] as int? ?? 0,
      updatedAt: _readDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'stickerId': stickerId,
      'quantity': quantity,
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
