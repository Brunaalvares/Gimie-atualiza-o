import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_screen.dart';
import 'add_product_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'trends_screen.dart';
import '../services/share_service.dart';
import '../services/metrics_service.dart';
import '../services/badges_service.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  bool _checkedPendingShare = false;
  bool _isOpeningShareFlow = false;
  StreamSubscription<void>? _shareSubscription;

  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(),
    const SizedBox(), // Placeholder for FAB
    const TrendsScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
    _shareSubscription =
        ShareService.instance.onSharedContentAvailable.listen((_) {
      _openAddScreenIfSharedContentExists();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_checkedPendingShare) return;
    _checkedPendingShare = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshSharePayloadFromNative();
    });
  }

  @override
  void dispose() {
    _shareSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    super.dispose();
  }

  late final WidgetsBindingObserver _lifecycleObserver =
      _MainShellLifecycleObserver(onResume: _refreshSharePayloadFromNative);

  Future<void> _refreshSharePayloadFromNative() async {
    final userId =
        Provider.of<AuthProvider>(context, listen: false).resolvedUserId;
    if (userId != null && userId.isNotEmpty) {
      unawaited(MetricsService.instance.touchDailyStreak(userId: userId));
      unawaited(BadgesService.instance.evaluateAndSync(userId));
    }
    await ShareService.instance.refreshPendingSharedContent();
    if (!mounted) return;
    await _openAddScreenIfSharedContentExists();
  }

  Future<void> _openAddScreenIfSharedContentExists() async {
    if (_isOpeningShareFlow) return;
    final sharedContent = await ShareService.instance.getSharedContent();
    if (!mounted || sharedContent == null) return;

    _isOpeningShareFlow = true;
    try {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AddProductScreen()),
      );
    } finally {
      _isOpeningShareFlow = false;
    }
  }

  void _onTabTapped(int index) {
    if (index == 2) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AddProductScreen()),
      );
    } else if (index == 3) {
      if (_currentIndex != 3) {
        final userId =
            Provider.of<AuthProvider>(context, listen: false).resolvedUserId;
        if (userId != null && userId.isNotEmpty) {
          unawaited(MetricsService.instance.trackTrendVisit(userId: userId));
        }
      }
      setState(() {
        _currentIndex = 3;
      });
    } else {
      if (index == 4) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final userId = authProvider.resolvedUserId;
        if (userId != null && userId.isNotEmpty) {
          Provider.of<ProductProvider>(context, listen: false)
              .loadUserProducts(userId);
        }
      }
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex == 2 ? 0 : _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home_outlined, Icons.home, 0),
                _buildNavItem(Icons.search, Icons.search, 1),
                const SizedBox(width: 60), // Space for FAB
                _buildNavItem(
                    Icons.auto_awesome_outlined, Icons.auto_awesome, 3),
                _buildNavItem(Icons.person_outline, Icons.person, 4),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onTabTapped(2),
        backgroundColor: const Color(0xFF6B2C5C),
        child: const Icon(Icons.add, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildNavItem(IconData outlinedIcon, IconData filledIcon, int index) {
    final isSelected = _currentIndex == index;
    return IconButton(
      icon: Icon(
        isSelected ? filledIcon : outlinedIcon,
        color: isSelected ? const Color(0xFF8B7FB8) : Colors.grey,
      ),
      onPressed: () => _onTabTapped(index),
    );
  }
}

class _MainShellLifecycleObserver with WidgetsBindingObserver {
  final Future<void> Function() onResume;

  _MainShellLifecycleObserver({required this.onResume});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResume();
    }
  }
}
