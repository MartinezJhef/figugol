import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../location/data/models/user_location.dart';

class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.exchangeName,
    required this.createdAt,
    required this.updatedAt,
    required this.locationConfirmed,
    required this.selectedExchangePoints,
    this.location,
    this.isOnline = false,
    this.lastSeen,
  });

  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final String? exchangeName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool locationConfirmed;
  final List<String> selectedExchangePoints;
  final UserLocation? location;
  final bool isOnline;
  final DateTime? lastSeen;

  bool get hasCompletedProfile =>
      exchangeName != null && exchangeName!.trim().isNotEmpty;

  bool get hasRequiredExchangePoints => selectedExchangePoints.length == 3;

  bool get canPublishOffers =>
      locationConfirmed && location != null && hasRequiredExchangePoints;

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    String? exchangeName,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? locationConfirmed,
    List<String>? selectedExchangePoints,
    UserLocation? location,
    bool? isOnline,
    DateTime? lastSeen,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      exchangeName: exchangeName ?? this.exchangeName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      locationConfirmed: locationConfirmed ?? this.locationConfirmed,
      selectedExchangePoints:
          selectedExchangePoints ?? this.selectedExchangePoints,
      location: location ?? this.location,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['uid'] as String,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      exchangeName: json['exchangeName'] as String?,
      createdAt: _readDateTime(json['createdAt']),
      updatedAt: _readDateTime(json['updatedAt']),
      locationConfirmed: json['locationConfirmed'] as bool? ?? false,
      selectedExchangePoints:
          (json['selectedExchangePoints'] as List<dynamic>? ?? const [])
              .map((point) => point.toString())
              .toList(),
      location: _readLocation(json['location']),
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeen: json['lastSeen'] != null ? _readDateTime(json['lastSeen']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'exchangeName': exchangeName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'locationConfirmed': locationConfirmed,
      'selectedExchangePoints': selectedExchangePoints,
      'location': location?.toJson(),
      'isOnline': isOnline,
      if (lastSeen != null) 'lastSeen': Timestamp.fromDate(lastSeen!),
    };
  }

  static UserLocation? _readLocation(Object? value) {
    if (value is Map<String, dynamic>) {
      return UserLocation.fromJson(value);
    }
    if (value is Map) {
      return UserLocation.fromJson(Map<String, dynamic>.from(value));
    }
    return null;
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
