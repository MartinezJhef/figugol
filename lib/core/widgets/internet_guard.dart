import 'dart:async';

import 'package:flutter/material.dart';

import '../services/connectivity_service.dart';

class InternetGuard extends StatefulWidget {
  const InternetGuard({
    required this.child,
    this.connectivityService = const ConnectivityService(),
    super.key,
  });

  final Widget child;
  final ConnectivityService connectivityService;

  @override
  State<InternetGuard> createState() => _InternetGuardState();
}

class _InternetGuardState extends State<InternetGuard> {
  StreamSubscription<bool>? _subscription;
  bool _hasInternetConnection = true;

  @override
  void initState() {
    super.initState();
    _subscription = widget.connectivityService.watchInternetConnection().listen(
      (hasInternetConnection) {
        if (!mounted) {
          return;
        }
        setState(() => _hasInternetConnection = hasInternetConnection);
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        AnimatedPositioned(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          left: 0,
          right: 0,
          top: _hasInternetConnection ? -112 : 0,
          child: const SafeArea(bottom: false, child: _NoInternetBanner()),
        ),
      ],
    );
  }
}

class _NoInternetBanner extends StatelessWidget {
  const _NoInternetBanner();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF10231B),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Sin conexión a internet',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Revisa tu conexión para seguir intercambiando figuritas.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFEAF4E2),
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
