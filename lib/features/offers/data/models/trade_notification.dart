import 'package:cloud_firestore/cloud_firestore.dart';

enum TradeNotificationStatus { unread, read, accepted, rejected }

class TradeNotification {
  const TradeNotification({
    required this.id,
    required this.toUserId,
    required this.fromUserId,
    required this.fromUserName,
    required this.proposalId,
    required this.offerId,
    required this.createdAt,
    this.status = TradeNotificationStatus.unread,
  });

  final String id;
  final String toUserId;
  final String fromUserId;
  final String fromUserName;
  final String proposalId;
  final String offerId;
  final DateTime createdAt;
  final TradeNotificationStatus status;

  TradeNotification copyWith({
    String? id,
    String? toUserId,
    String? fromUserId,
    String? fromUserName,
    String? proposalId,
    String? offerId,
    DateTime? createdAt,
    TradeNotificationStatus? status,
  }) {
    return TradeNotification(
      id: id ?? this.id,
      toUserId: toUserId ?? this.toUserId,
      fromUserId: fromUserId ?? this.fromUserId,
      fromUserName: fromUserName ?? this.fromUserName,
      proposalId: proposalId ?? this.proposalId,
      offerId: offerId ?? this.offerId,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  factory TradeNotification.fromJson(Map<String, dynamic> json) {
    return TradeNotification(
      id: json['id'] as String,
      toUserId: json['toUserId'] as String,
      fromUserId: json['fromUserId'] as String,
      fromUserName: json['fromUserName'] as String,
      proposalId: json['proposalId'] as String,
      offerId: json['offerId'] as String,
      createdAt: _readDateTime(json['createdAt']),
      status: TradeNotificationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TradeNotificationStatus.unread,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'toUserId': toUserId,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'proposalId': proposalId,
      'offerId': offerId,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status.name,
    };
  }

  static DateTime _readDateTime(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
