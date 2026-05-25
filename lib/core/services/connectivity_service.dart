import 'dart:async';
import 'dart:io';

enum ImportantNetworkAction {
  login,
  saveStickers,
  publishOffers,
  confirmLocation,
  sendExchange,
  simulatedPayment,
  saveProfile,
}

class ConnectivityService {
  const ConnectivityService({
    this.lookupHost = 'google.com',
    this.timeout = const Duration(seconds: 3),
  });

  final String lookupHost;
  final Duration timeout;

  Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup(lookupHost).timeout(timeout);
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on Object {
      return false;
    }
  }

  Stream<bool> watchInternetConnection({
    Duration interval = const Duration(seconds: 5),
  }) async* {
    var lastStatus = await hasInternetConnection();
    yield lastStatus;

    await for (final _ in Stream<void>.periodic(interval)) {
      final nextStatus = await hasInternetConnection();
      if (nextStatus != lastStatus) {
        lastStatus = nextStatus;
        yield nextStatus;
      }
    }
  }

  Stream<bool> watchInternetConnectionContinuously({
    Duration interval = const Duration(seconds: 5),
  }) {
    return watchInternetConnection(interval: interval);
  }

  Future<void> ensureInternetConnection({
    required ImportantNetworkAction action,
  }) async {
    final isConnected = await hasInternetConnection();
    if (!isConnected) {
      throw ConnectivityException(
        action: action,
        message: 'Necesitas conexión a internet para continuar.',
      );
    }
  }
}

class ConnectivityException implements Exception {
  const ConnectivityException({required this.action, required this.message});

  final ImportantNetworkAction action;
  final String message;
}
