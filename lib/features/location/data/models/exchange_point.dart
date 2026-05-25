enum ExchangePointType {
  park('parque'),
  shoppingCenter('centro_comercial'),
  square('plaza'),
  university('universidad'),
  other('otro');

  const ExchangePointType(this.value);

  final String value;

  static ExchangePointType fromValue(String value) {
    return ExchangePointType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ExchangePointType.other,
    );
  }
}

class ExchangePoint {
  const ExchangePoint({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.isSelected,
  });

  final String id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final ExchangePointType type;
  final bool isSelected;

  ExchangePoint copyWith({bool? isSelected}) {
    return ExchangePoint(
      id: id,
      name: name,
      description: description,
      latitude: latitude,
      longitude: longitude,
      type: type,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  factory ExchangePoint.fromJson(Map<String, dynamic> json) {
    return ExchangePoint(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      type: ExchangePointType.fromValue(json['type'] as String),
      isSelected: json['isSelected'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'type': type.value,
      'isSelected': isSelected,
    };
  }
}
