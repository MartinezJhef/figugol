import 'package:cloud_firestore/cloud_firestore.dart';

class UserSticker {
  const UserSticker({
    required this.userId,
    required this.stickerId,
    required this.quantity,
    required this.updatedAt,
    this.isPasted = false,
  });

  final String userId;
  final String stickerId;
  final int quantity;
  final DateTime updatedAt;
  final bool isPasted;

  factory UserSticker.fromJson(Map<String, dynamic> json) {
    return UserSticker(
      userId: json['userId'] as String,
      stickerId: json['stickerId'] as String,
      quantity: json['quantity'] as int? ?? 0,
      updatedAt: _readDateTime(json['updatedAt']),
      isPasted: json['isPasted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'stickerId': stickerId,
      'quantity': quantity,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isPasted': isPasted,
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
