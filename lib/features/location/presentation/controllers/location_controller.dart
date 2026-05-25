import 'package:flutter/foundation.dart';

import '../../../../core/services/connectivity_service.dart';
import '../../data/repositories/location_repository.dart';
import '../../data/sources/location_service.dart';

class LocationController extends ChangeNotifier {
  LocationController({
    required this.userId,
    LocationService? locationService,
    LocationRepository? locationRepository,
  }) : _locationService = locationService ?? const LocationService(),
       _locationRepository = locationRepository ?? LocationRepository();

  final String userId;
  final LocationService _locationService;
  final LocationRepository _locationRepository;

  double? _latitude;
  double? _longitude;
  String? _sector;
  String? _errorMessage;
  bool _isLoadingPosition = false;
  bool _isSaving = false;

  double? get latitude => _latitude;
  double? get longitude => _longitude;
  String? get sector => _sector;
  String? get errorMessage => _errorMessage;
  bool get isLoadingPosition => _isLoadingPosition;
  bool get isSaving => _isSaving;
  bool get hasPosition => _latitude != null && _longitude != null;

  Future<void> loadCurrentPosition() async {
    _isLoadingPosition = true;
    notifyListeners();

    try {
      final position = await _locationService.requestCurrentPosition();
      _latitude = position.latitude;
      _longitude = position.longitude;
      _sector = _locationRepository.calculateSector(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      _errorMessage = null;
    } catch (error) {
      _errorMessage = _messageFromError(error);
    } finally {
      _isLoadingPosition = false;
      notifyListeners();
    }
  }

  Future<bool> confirmLocation() async {
    final latitude = _latitude;
    final longitude = _longitude;

    if (latitude == null || longitude == null) {
      _errorMessage = 'Actualiza tu ubicación antes de confirmar.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    notifyListeners();

    try {
      await _locationRepository.confirmLocation(
        userId: userId,
        latitude: latitude,
        longitude: longitude,
      );
      _errorMessage = null;
      return true;
    } catch (error) {
      _errorMessage = _messageFromError(error);
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _messageFromError(Object error) {
    if (error is ConnectivityException) {
      return error.message;
    }
    if (error is LocationServiceException) {
      return error.message;
    }
    return 'No se pudo obtener tu ubicación. Inténtalo nuevamente.';
  }
}
