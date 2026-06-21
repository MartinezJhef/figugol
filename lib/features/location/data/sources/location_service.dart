import 'package:geolocator/geolocator.dart';

class LocationService {
  const LocationService();

  Future<Position> requestCurrentPosition() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationServiceException(
        'Necesitamos permiso de ubicación para encontrar intercambios cercanos.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationServiceException(
        'Habilita el permiso de ubicación desde los ajustes del dispositivo.',
      );
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceException(
        'Activa la ubicación del dispositivo para continuar.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 12),
      ),
    );
  }

  Future<bool> openSettings() {
    return Geolocator.openLocationSettings();
  }
}

class LocationServiceException implements Exception {
  const LocationServiceException(this.message);

  final String message;
}
