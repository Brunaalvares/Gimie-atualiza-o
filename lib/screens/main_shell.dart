import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_screen.dart';
import 'add_product_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'trends_screen.dart';
import '../services/share_flow_coordinator.dart';
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
  static const String _lastTabPrefsKey = 'main_shell_last_tab_index';

  int _currentIndex = 0;
  bool _checkedPendingShare = false;

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
    _restoreLastTab();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_checkedPendingShare) return;
    _checkedPendingShare = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _onAppBecameActive();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    super.dispose();
  }

  late final WidgetsBindingObserver _lifecycleObserver =
      _MainShellLifecycleObserver(
    onResume: _onAppBecameActive,
    onPause: _persistCurrentTab,
  );

  Future<void> _restoreLastTab() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt(_lastTabPrefsKey);
      if (!mounted || saved == null) return;
      if (saved == 0 || saved == 1 || saved == 3 || saved == 4) {
        setState(() => _currentIndex = saved);
      }
    } catch (_) {
      // Ignore restore failures; default tab is fine.
    }
  }

  Future<void> _persistCurrentTab() async {
    final index = _currentIndex;
    if (index != 0 && index != 1 && index != 3 && index != 4) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastTabPrefsKey, index);
    } catch (_) {
      // Ignore persistence failures.
    }
  }

  Future<void> _onAppBecameActive() async {
    final userId =
        Provider.of<AuthProvider>(context, listen: false).resolvedUserId;
    if (userId != null && userId.isNotEmpty) {
      unawaited(MetricsService.instance.touchDailyStreak(userId: userId));
      unawaited(BadgesService.instance.evaluateAndSync(userId));
    }
    await _persistCurrentTab();
    await ShareFlowCoordinator.instance.onAppResumed();
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
      unawaited(_persistCurrentTab());
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
      unawaited(_persistCurrentTab());
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
  final Future<void> Function() onPause;

  _MainShellLifecycleObserver({
    required this.onResume,
    required this.onPause,
  });

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResume();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      onPause();
    }
  }
}
