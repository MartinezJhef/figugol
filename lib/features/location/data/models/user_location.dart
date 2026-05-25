import 'package:cloud_firestore/cloud_firestore.dart';

class UserLocation {
  const UserLocation({
    required this.latitude,
    required this.longitude,
    required this.confirmedAt,
    required this.sector,
    required this.nearbyRadiusKm,
  });

  final double latitude;
  final double longitude;
  final DateTime confirmedAt;
  final String sector;
  final double nearbyRadiusKm;

  factory UserLocation.fromJson(Map<String, dynamic> json) {
    return UserLocation(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      confirmedAt: _readDateTime(json['confirmedAt']),
      sector: json['sector'] as String,
      nearbyRadiusKm: (json['nearbyRadiusKm'] as num? ?? 100).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'confirmedAt': Timestamp.fromDate(confirmedAt),
      'sector': sector,
      'nearbyRadiusKm': nearbyRadiusKm,
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
