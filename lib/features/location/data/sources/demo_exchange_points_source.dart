import '../models/exchange_point.dart';

class DemoExchangePointsSource {
  const DemoExchangePointsSource();

  List<ExchangePoint> buildNearbyPoints({
    required double latitude,
    required double longitude,
    Set<String> selectedIds = const {},
  }) {
    if (_isInHuancayoJunin(latitude: latitude, longitude: longitude)) {
      return _huancayoSeeds.map((seed) {
        return ExchangePoint(
          id: seed.id,
          name: seed.name,
          description: seed.description,
          latitude: seed.latitude,
          longitude: seed.longitude,
          type: seed.type,
          isSelected: selectedIds.contains(seed.id),
        );
      }).toList();
    }

    final seeds = [
      _PointSeed(
        id: 'nearby-park',
        name: 'Parque del barrio',
        description: 'Espacio abierto y visible para intercambios rápidos.',
        latitudeOffset: 0.006,
        longitudeOffset: -0.004,
        type: ExchangePointType.park,
      ),
      _PointSeed(
        id: 'nearby-square',
        name: 'Plaza central',
        description: 'Punto de encuentro con buena circulación peatonal.',
        latitudeOffset: -0.005,
        longitudeOffset: 0.003,
        type: ExchangePointType.square,
      ),
      _PointSeed(
        id: 'nearby-mall',
        name: 'Centro comercial cercano',
        description: 'Zona techada con accesos claros y horarios amplios.',
        latitudeOffset: 0.009,
        longitudeOffset: 0.006,
        type: ExchangePointType.shoppingCenter,
      ),
      _PointSeed(
        id: 'nearby-university',
        name: 'Universidad local',
        description: 'Ingreso principal con movimiento durante el día.',
        latitudeOffset: -0.008,
        longitudeOffset: -0.006,
        type: ExchangePointType.university,
      ),
      _PointSeed(
        id: 'nearby-station',
        name: 'Paradero principal',
        description: 'Referencia fácil de ubicar cerca de avenidas.',
        latitudeOffset: 0.003,
        longitudeOffset: 0.010,
        type: ExchangePointType.other,
      ),
      _PointSeed(
        id: 'nearby-sports-zone',
        name: 'Losa deportiva',
        description: 'Zona conocida para reunirse después de clases o trabajo.',
        latitudeOffset: -0.010,
        longitudeOffset: 0.009,
        type: ExchangePointType.park,
      ),
    ];

    return seeds.map((seed) {
      return ExchangePoint(
        id: seed.id,
        name: seed.name,
        description: seed.description,
        latitude: latitude + seed.latitudeOffset,
        longitude: longitude + seed.longitudeOffset,
        type: seed.type,
        isSelected: selectedIds.contains(seed.id),
      );
    }).toList();
  }

  static bool _isInHuancayoJunin({
    required double latitude,
    required double longitude,
  }) {
    return latitude >= -12.18 &&
        latitude <= -11.95 &&
        longitude >= -75.35 &&
        longitude <= -74.95;
  }

  static const _huancayoSeeds = [
    _FixedPointSeed(
      id: 'huancayo-real-plaza',
      name: 'Real Plaza',
      description: 'Centro comercial conocido para coordinar intercambios.',
      latitude: -12.0688,
      longitude: -75.2076,
      type: ExchangePointType.shoppingCenter,
    ),
    _FixedPointSeed(
      id: 'huancayo-mall-plaza',
      name: 'Mall Plaza',
      description: 'Punto de encuentro techado con accesos claros.',
      latitude: -12.0648,
      longitude: -75.2038,
      type: ExchangePointType.shoppingCenter,
    ),
    _FixedPointSeed(
      id: 'huancayo-plaza-constitucion',
      name: 'Plaza Constitucion',
      description: 'Referencia centrica y facil de ubicar en Huancayo.',
      latitude: -12.0686,
      longitude: -75.2093,
      type: ExchangePointType.square,
    ),
  ];
}

class _PointSeed {
  const _PointSeed({
    required this.id,
    required this.name,
    required this.description,
    required this.latitudeOffset,
    required this.longitudeOffset,
    required this.type,
  });

  final String id;
  final String name;
  final String description;
  final double latitudeOffset;
  final double longitudeOffset;
  final ExchangePointType type;
}

class _FixedPointSeed {
  const _FixedPointSeed({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.type,
  });

  final String id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final ExchangePointType type;
}
