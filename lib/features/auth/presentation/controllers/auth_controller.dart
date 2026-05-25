import 'package:flutter/foundation.dart';

import '../../../../core/services/connectivity_service.dart';
import '../../data/models/app_user.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/sources/auth_service.dart';

enum AuthFlowStatus { checking, signedOut, profileIncomplete, signedIn }

class AuthController extends ChangeNotifier {
  AuthController({
    AuthRepository? authRepository,
    bool loadCurrentUserOnStart = true,
  }) : _authRepository =
           authRepository ??
           (loadCurrentUserOnStart ? AuthRepository() : null) {
    if (loadCurrentUserOnStart) {
      refreshCurrentUser();
    } else {
      _status = AuthFlowStatus.signedOut;
    }
  }

  final AuthRepository? _authRepository;

  AuthFlowStatus _status = AuthFlowStatus.checking;
  AppUser? _user;
  String? _errorMessage;
  bool _isLoading = false;

  AuthFlowStatus get status => _status;
  AppUser? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  Future<void> refreshCurrentUser() async {
    _setLoading(true);
    try {
      _user = await _repository.loadCurrentUserProfile();
      _resolveStatus();
      _errorMessage = null;
    } catch (error) {
      _user = null;
      _status = AuthFlowStatus.signedOut;
      _errorMessage = _messageFromError(error);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signInWithGoogle() async {
    _setLoading(true);
    try {
      _user = await _repository.signInWithGoogle();
      _resolveStatus();
      _errorMessage = null;
    } catch (error) {
      _errorMessage = _messageFromError(error);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> completeProfile(String exchangeName) async {
    final currentUser = _user;
    if (currentUser == null) {
      _status = AuthFlowStatus.signedOut;
      notifyListeners();
      return;
    }

    _setLoading(true);
    try {
      _user = await _repository.updateExchangeName(
        uid: currentUser.uid,
        exchangeName: exchangeName,
      );
      _resolveStatus();
      _errorMessage = null;
    } catch (error) {
      _errorMessage = _messageFromError(error);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _repository.signOut();
      _user = null;
      _status = AuthFlowStatus.signedOut;
      _errorMessage = null;
    } catch (error) {
      _errorMessage = _messageFromError(error);
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _resolveStatus() {
    final currentUser = _user;
    if (currentUser == null) {
      _status = AuthFlowStatus.signedOut;
      return;
    }

    _status = currentUser.hasCompletedProfile
        ? AuthFlowStatus.signedIn
        : AuthFlowStatus.profileIncomplete;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _messageFromError(Object error) {
    if (error is ConnectivityException) {
      return error.message;
    }
    if (error is AuthRepositoryException) {
      return error.message;
    }
    if (error is AuthServiceException) {
      return error.message;
    }
    return 'Ocurrió un problema. Inténtalo nuevamente.';
  }

  AuthRepository get _repository {
    final repository = _authRepository;
    if (repository == null) {
      throw StateError('AuthRepository is not available in this test setup.');
    }
    return repository;
  }
}
