import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/data/models/app_user.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../location/presentation/pages/location_confirm_screen.dart';
import '../../../marketplace/presentation/pages/marketplace_screen.dart';
import '../../../stickers/presentation/pages/album_screen.dart';
import '../../../stickers/presentation/pages/stickers_screen.dart';
import '../../../stickers/presentation/pages/stickers_screen.dart';
import '../../../stickers/presentation/controllers/stickers_controller.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  var _selectedIndex = 0;
  String? _lastLocationPromptUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.watch<AuthController>().user;
    _requestLocationOnEntry(user);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;
    if (user == null) {
      return const SizedBox.shrink();
    }

    final pages = [
      HomeScreen(onOpenTab: _selectTab),
      const StickersScreen(initialFilter: StickerFilter.duplicates),
      const AlbumScreen(),
      const MarketplaceScreen(),
      const ProfileScreen(),
    ];

    return ChangeNotifierProvider(
      create: (_) => StickersController(userId: user.uid),
      child: Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.style_outlined),
            selectedIcon: Icon(Icons.style_rounded),
            label: 'Repetidas',
          ),
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book_rounded),
            label: 'Mi Álbum',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront_rounded),
            label: 'Tiendita',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    ));
  }

  void _selectTab(int index) {
    setState(() => _selectedIndex = index);
  }

  void _requestLocationOnEntry(AppUser? user) {
    if (user == null ||
        user.locationConfirmed ||
        _lastLocationPromptUserId == user.uid) {
      return;
    }

    _lastLocationPromptUserId = user.uid;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const LocationConfirmScreen()),
      );
    });
  }
}
