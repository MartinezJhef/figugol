import 'package:flutter/foundation.dart';

import '../../../../core/services/connectivity_service.dart';
import '../../data/models/exchange_point.dart';
import '../../data/models/user_location.dart';
import '../../data/repositories/location_repository.dart';
import '../../data/sources/demo_exchange_points_source.dart';

class ExchangePointsController extends ChangeNotifier {
  ExchangePointsController({
    required this.userId,
    required this.location,
    required List<String> selectedExchangePointIds,
    LocationRepository? locationRepository,
    DemoExchangePointsSource? exchangePointsSource,
  }) : _locationRepository = locationRepository ?? LocationRepository(),
       _exchangePointsSource =
           exchangePointsSource ?? const DemoExchangePointsSource() {
    _points = _exchangePointsSource.buildNearbyPoints(
      latitude: location.latitude,
      longitude: location.longitude,
      selectedIds: selectedExchangePointIds.toSet(),
    );
  }

  static const maxSelectedPoints = 3;

  final String userId;
  final UserLocation location;
  final LocationRepository _locationRepository;
  final DemoExchangePointsSource _exchangePointsSource;

  List<ExchangePoint> _points = const [];
  String? _errorMessage;
  bool _isSaving = false;

  List<ExchangePoint> get points => _points;
  String? get errorMessage => _errorMessage;
  bool get isSaving => _isSaving;
  int get selectedCount => _points.where((point) => point.isSelected).length;
  bool get canSave => selectedCount == maxSelectedPoints && !_isSaving;

  void togglePoint(String pointId) {
    final point = _points.firstWhere((item) => item.id == pointId);

    if (!point.isSelected && selectedCount >= maxSelectedPoints) {
      _errorMessage = 'Solo puedes seleccionar 3 puntos de intercambio.';
      notifyListeners();
      return;
    }

    _points = [
      for (final item in _points)
        if (item.id == pointId)
          item.copyWith(isSelected: !item.isSelected)
        else
          item,
    ];
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> saveSelectedPoints() async {
    final selectedPoints = _points
        .where((point) => point.isSelected)
        .toList(growable: false);

    if (selectedPoints.length != maxSelectedPoints) {
      _errorMessage = 'Selecciona 3 puntos para continuar.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    notifyListeners();

    try {
      await _locationRepository.saveExchangePoints(
        userId: userId,
        exchangePoints: selectedPoints,
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
    return 'No se pudieron guardar tus puntos. Inténtalo nuevamente.';
  }
}
