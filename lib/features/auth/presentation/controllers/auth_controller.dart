import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/services/connectivity_service.dart';
import '../../data/models/app_user.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/sources/auth_service.dart';

enum AuthFlowStatus { checking, signedOut, profileIncomplete, signedIn }

class AuthController extends ChangeNotifier with WidgetsBindingObserver {
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
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_user == null) return;
    
    if (state == AppLifecycleState.resumed) {
      _repository.updateOnlinePresence(_user!.uid, true);
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _repository.updateOnlinePresence(_user!.uid, false);
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
      if (_user != null) {
        _repository.updateOnlinePresence(_user!.uid, true);
      }
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
      if (_user != null) {
        _repository.updateOnlinePresence(_user!.uid, true);
      }
      _resolveStatus();
      _errorMessage = null;
    } catch (error) {
      _errorMessage = _messageFromError(error);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    _setLoading(true);
    try {
      _user = await _repository.signInWithEmailAndPassword(email, password);
      _resolveStatus();
      _errorMessage = null;
    } catch (error) {
      _errorMessage = _messageFromError(error);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createUserWithEmailAndPassword(String email, String password, String username) async {
    _setLoading(true);
    try {
      _user = await _repository.createUserWithEmailAndPassword(email, password, username);
      _resolveStatus();
      _errorMessage = null;
    } catch (error) {
      _errorMessage = _messageFromError(error);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signInAnonymously() async {
    _setLoading(true);
    try {
      _user = await _repository.signInAnonymously();
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
      if (_user != null) {
        await _repository.updateOnlinePresence(_user!.uid, false);
      }
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
    if (error is PlatformException) {
      final code = error.code.toLowerCase();
      final msg = error.message?.toLowerCase() ?? '';
      if (code.contains('developer') || 
          code.contains('10') || 
          msg.contains('developer') || 
          msg.contains('credential') || 
          msg.contains('getcredential')) {
        return 'Firma SHA-1 de Google no registrada. Por favor ingresa usando el botón de Invitado (Demo).';
      }
      return 'Error de plataforma: ${error.message}';
    }
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
