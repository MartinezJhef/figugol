import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/services/connectivity_service.dart';
import '../models/app_user.dart';
import '../sources/auth_service.dart';

class AuthRepository {
  AuthRepository({
    AuthService? authService,
    FirebaseFirestore? firestore,
    ConnectivityService? connectivityService,
  }) : _authService = authService ?? AuthService(),
       _firestore = firestore ?? FirebaseFirestore.instance,
       _connectivityService =
           connectivityService ?? const ConnectivityService();

  final AuthService _authService;
  final FirebaseFirestore _firestore;
  final ConnectivityService _connectivityService;

  Stream<User?> get authStateChanges => _authService.authStateChanges;

  Future<AppUser> signInWithGoogle() async {
    await _connectivityService.ensureInternetConnection(
      action: ImportantNetworkAction.login,
    );
    final credential = await _authService.signInWithGoogle();
    final user = credential.user;

    if (user == null) {
      throw const AuthRepositoryException(
        'No se pudo iniciar sesión. Inténtalo nuevamente.',
      );
    }

    return _loadOrCreateUser(user);
  }

  Future<AppUser?> loadCurrentUserProfile() async {
    final user = _authService.currentUser;
    if (user == null) {
      return null;
    }

    await _connectivityService.ensureInternetConnection(
      action: ImportantNetworkAction.login,
    );
    return _loadOrCreateUser(user);
  }

  Future<AppUser> updateExchangeName({
    required String uid,
    required String exchangeName,
  }) async {
    await _connectivityService.ensureInternetConnection(
      action: ImportantNetworkAction.saveProfile,
    );

    final userRef = _users.doc(uid);
    final updatedAt = DateTime.now();

    await userRef.update({
      'exchangeName': exchangeName.trim(),
      'updatedAt': Timestamp.fromDate(updatedAt),
    });

    final snapshot = await userRef.get();
    final data = snapshot.data();

    if (data == null) {
      throw const AuthRepositoryException(
        'No se pudo actualizar tu perfil. Inténtalo nuevamente.',
      );
    }

    return AppUser.fromJson(data);
  }

  Future<void> signOut() => _authService.signOut();

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Future<AppUser> _loadOrCreateUser(User firebaseUser) async {
    final userRef = _users.doc(firebaseUser.uid);
    final snapshot = await userRef.get();

    if (snapshot.exists) {
      final data = snapshot.data();
      if (data == null) {
        throw const AuthRepositoryException(
          'No se pudo leer tu perfil. Inténtalo nuevamente.',
        );
      }
      return AppUser.fromJson(data);
    }

    final now = DateTime.now();
    final appUser = AppUser(
      uid: firebaseUser.uid,
      email: firebaseUser.email,
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      exchangeName: null,
      createdAt: now,
      updatedAt: now,
      locationConfirmed: false,
      selectedExchangePoints: const [],
    );

    await userRef.set(appUser.toJson());
    return appUser;
  }
}

class AuthRepositoryException implements Exception {
  const AuthRepositoryException(this.message);

  final String message;
}
